import SwiftUI
import UserNotifications

struct RateDropAlert: Identifiable, Codable, Equatable {
    var id = UUID()
    var base: String
    var target: String
    var threshold: Double
}

struct AlertSettingsView: View {
    // Threshold alert settings
    @AppStorage("alertBaseCurrency") private var alertBaseCurrency = "USD"
    @AppStorage("alertTargetCurrency") private var alertTargetCurrency = "JPY"
    @AppStorage("alertRate") private var alertRate: String = "140"

    // Daily notification settings
    @AppStorage("dailyAlertBaseCurrency") private var dailyBase = "USD"
    @AppStorage("dailyAlertTargetCurrency") private var dailyTarget = "JPY"
    @AppStorage("dailyAlertHour") private var alertHour = 8
    @AppStorage("dailyAlertMinute") private var alertMinute = 0

    @AppStorage("isDailyAlertEnabled") private var isDailyAlertEnabled = false
    @State private var currentRateText: String = ""
    @AppStorage("savedRateAlerts") private var savedRateAlertsData: Data = Data()
    @State private var savedRateAlerts: [RateDropAlert] = []

    let currencyList = ["USD", "EUR", "JPY", "GBP", "AUD", "CAD", "CHF", "CNY", "KRW", "ZAR"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("\u{1F514} Notification Settings")
                    .font(.title2)
                    .bold()

                // MARK: - Threshold Alert
                VStack(alignment: .leading, spacing: 16) {
                    Text("Rate Drop Alert")
                        .font(.headline)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("From")
                            Picker("Base", selection: $alertBaseCurrency) {
                                ForEach(currencyList, id: \.self) { Text($0)}
                            }.pickerStyle(.menu)
                        }

                        VStack(alignment: .leading) {
                            Text("To")
                            Picker("Target", selection: $alertTargetCurrency) {
                                ForEach(currencyList, id: \.self) { Text($0)}
                            }.pickerStyle(.menu)
                        }
                    }

                    HStack {
                        Text("Alert below:")
                        TextField("Threshold", text: $alertRate)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        Text(alertTargetCurrency)
                    }

                    Button("Save & Check Now") {
                        checkAndSendThresholdNotification()
                    }
                    .buttonStyle(.borderedProminent)

                    if !currentRateText.isEmpty {
                        Text(currentRateText)
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }

                    // Current Alerts
                    if !savedRateAlerts.isEmpty {
                        Divider()
                        Text("\u{1F4C8} Your current Rate Drop Alert")
                            .font(.subheadline)
                            .bold()

                        ForEach(savedRateAlerts) { alert in
                            HStack {
                                Text("• \(alert.base) → \(alert.target) under \(String(format: "%.2f", alert.threshold))")
                                    .font(.footnote)
                                Spacer()
                                Button(role: .destructive) {
                                    deleteRateAlert(alert)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                }

                Divider()

                // MARK: - Daily Notification
                // MARK: - Daily Notification
                VStack(alignment: .leading, spacing: 16) {
                    Text("Daily Exchange Rate Notification")
                        .font(.headline)

                    Toggle("Enable Daily Alert", isOn: $isDailyAlertEnabled)
                        .onChange(of: isDailyAlertEnabled) { oldValue, newValue in
                            if newValue {
                                scheduleDailyNotification()
                            } else {
                                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyRateNotification"])
                            }
                        }

                    if isDailyAlertEnabled {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("From")
                                Picker("Daily Base", selection: $dailyBase) {
                                    ForEach(currencyList, id: \.self) { Text($0) }
                                }.pickerStyle(.menu)
                            }

                            VStack(alignment: .leading) {
                                Text("To")
                                Picker("Daily Target", selection: $dailyTarget) {
                                    ForEach(currencyList, id: \.self) { Text($0) }
                                }.pickerStyle(.menu)
                            }
                        }

                        DatePicker("Alert Time", selection: Binding(
                            get: {
                                Calendar.current.date(bySettingHour: alertHour, minute: alertMinute, second: 0, of: Date()) ?? Date()
                            },
                            set: { date in
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                                alertHour = comps.hour ?? 8
                                alertMinute = comps.minute ?? 0
                            }),
                            displayedComponents: .hourAndMinute
                        )

                        // These individual onChange calls replace the broken tuple version
                        .onChange(of: dailyBase) {
                            if isDailyAlertEnabled { scheduleDailyNotification() }
                        }
                        .onChange(of: dailyTarget) {
                            if isDailyAlertEnabled { scheduleDailyNotification() }
                        }
                        .onChange(of: alertHour) {
                            if isDailyAlertEnabled { scheduleDailyNotification() }
                        }
                        .onChange(of: alertMinute) {
                            if isDailyAlertEnabled { scheduleDailyNotification() }
                        }
                        if let scheduledDate = Calendar.current.date(bySettingHour: alertHour, minute: alertMinute, second: 0, of: Date()) {
                            Text("\u{1F4C5} Daily alert set at \(formattedTime(scheduledDate)) for \(dailyBase) → \(dailyTarget)")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            requestNotificationPermission()
            loadRateAlerts()
        }
    }

    // MARK: - Save, Load, Delete Alerts
    func saveRateAlerts() {
        if let data = try? JSONEncoder().encode(savedRateAlerts) {
            savedRateAlertsData = data
        }
    }

    func loadRateAlerts() {
        if let decoded = try? JSONDecoder().decode([RateDropAlert].self, from: savedRateAlertsData) {
            savedRateAlerts = decoded
        }
    }

    func deleteRateAlert(_ alert: RateDropAlert) {
        savedRateAlerts.removeAll { $0 == alert }
        saveRateAlerts()
    }

    // MARK: - Permissions
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("⚠️ Notification error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Threshold Check
    func checkAndSendThresholdNotification() {
        guard let threshold = Double(alertRate) else { return }

        let alertToSave = RateDropAlert(base: alertBaseCurrency, target: alertTargetCurrency, threshold: threshold)
        if !savedRateAlerts.contains(alertToSave) {
            savedRateAlerts.append(alertToSave)
            saveRateAlerts()
        }

        let urlString = "https://api.frankfurter.app/latest?from=\(alertBaseCurrency)&to=\(alertTargetCurrency)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let result = try? JSONDecoder().decode(ExchangeRateResponse.self, from: data),
                  let rate = result.rates[alertTargetCurrency] else {
                DispatchQueue.main.async {
                    currentRateText = "Failed to fetch current rate."
                }
                return
            }

            DispatchQueue.main.async {
                currentRateText = "Current rate: 1 \(alertBaseCurrency) = \(String(format: "%.2f", rate)) \(alertTargetCurrency)"
            }

            if rate < threshold {
                let content = UNMutableNotificationContent()
                content.title = "🎯 Threshold Alert Triggered!"
                content.body = "1 \(alertBaseCurrency) = \(String(format: "%.2f", rate)) \(alertTargetCurrency)"

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request)
            }
        }.resume()
    }

    // MARK: - Daily Notification
    func scheduleDailyNotification() {
        let urlString = "https://api.frankfurter.app/latest?from=\(dailyBase)&to=\(dailyTarget)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let result = try? JSONDecoder().decode(ExchangeRateResponse.self, from: data),
                  let rate = result.rates[dailyTarget] else { return }

            let content = UNMutableNotificationContent()
            content.title = "📊 Daily Exchange Rate"
            content.body = "1 \(dailyBase) = \(String(format: "%.2f", rate)) \(dailyTarget)"

            var dateComponents = DateComponents()
            dateComponents.hour = alertHour
            dateComponents.minute = alertMinute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "dailyRateNotification", content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request)
        }.resume()
    }

    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
