import SwiftUI
import UserNotifications

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

    let currencyList = ["USD", "EUR", "JPY", "GBP", "AUD", "CAD", "CHF", "CNY", "KRW"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("🔔 Notification Settings")
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
                                ForEach(currencyList, id: \.self) { Text($0) }
                            }.pickerStyle(.menu)
                        }

                        VStack(alignment: .leading) {
                            Text("To")
                            Picker("Target", selection: $alertTargetCurrency) {
                                ForEach(currencyList, id: \.self) { Text($0) }
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
                }

                Divider()

                // - Daily Notification
                VStack(alignment: .leading, spacing: 16) {
                    Text("Daily Exchange Rate Notification")
                        .font(.headline)

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

                    Button("Schedule Daily Alert") {
                        scheduleDailyNotification()
                    }
                    .buttonStyle(.borderedProminent)

                    // Summary
                    if let scheduledDate = Calendar.current.date(bySettingHour: alertHour, minute: alertMinute, second: 0, of: Date()) {
                        Text("🗓️ Daily alert set at \(formattedTime(scheduledDate)) for \(dailyBase) → \(dailyTarget)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            requestNotificationPermission()
        }
    }

    //  - Notification Permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("⚠️ Notification error: \(error.localizedDescription)")
            } else {
                print("🔔 Permission granted: \(granted)")
            }
        }
    }

    //  - Threshold Notification
    func checkAndSendThresholdNotification() {
        guard let threshold = Double(alertRate) else { return }

        let urlString = "https://api.frankfurter.app/latest?from=\(alertBaseCurrency)&to=\(alertTargetCurrency)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let result = try? JSONDecoder().decode(ExchangeRateResponse.self, from: data),
                  let rate = result.rates[alertTargetCurrency],
                  rate < threshold else { return }

            let content = UNMutableNotificationContent()
            content.title = "🎯 Threshold Alert Triggered!"
            content.body = "1 \(alertBaseCurrency) = \(String(format: "%.2f", rate)) \(alertTargetCurrency)"

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request)
        }.resume()
    }

    // - Daily Notification
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

    // - Formatter
    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
