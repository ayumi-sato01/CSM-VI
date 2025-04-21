import SwiftUI
import UserNotifications

struct AlertSettingsView: View {
    @AppStorage("alertBaseCurrency") private var alertBaseCurrency = "USD"
    @AppStorage("alertTargetCurrency") private var alertTargetCurrency = "JPY"
    @AppStorage("alertRate") private var alertRate: String = "140"

    let currencyList = ["USD", "EUR", "JPY", "GBP", "AUD", "CAD", "CHF", "CNY", "KRW"]

    var body: some View {
        VStack(spacing: 20) {
            Text("🔔 Notification Alert Settings")
                .font(.title2)
                .bold()

            // Base currency
            VStack(alignment: .leading) {
                Text("From:")
                Picker("From", selection: $alertBaseCurrency) {
                    ForEach(currencyList, id: \.self) { currency in
                        Text(currency)
                    }
                }.pickerStyle(.menu)
            }

            // Target currency
            VStack(alignment: .leading) {
                Text("To:")
                Picker("To", selection: $alertTargetCurrency) {
                    ForEach(currencyList, id: \.self) { currency in
                        Text(currency)
                    }
                }.pickerStyle(.menu)
            }

            // Threshold input
            HStack {
                Text("Alert below:")
                TextField("Threshold", text: $alertRate)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                Text(alertTargetCurrency)
            }

            Button("Save & Check Now") {
                checkAndSendNotification()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }

    func checkAndSendNotification() {
        guard let threshold = Double(alertRate) else { return }

        let urlString = "https://api.frankfurter.app/latest?from=\(alertBaseCurrency)&to=\(alertTargetCurrency)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }

            if let result = try? JSONDecoder().decode(ExchangeRateResponse.self, from: data),
               let rate = result.rates[alertTargetCurrency],
               rate < threshold {

                let content = UNMutableNotificationContent()
                content.title = "🎉 Great Time to Exchange!"
                content.body = "1 \(alertBaseCurrency) = \(rate) \(alertTargetCurrency)"

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request)
            }
        }.resume()
    }
}
