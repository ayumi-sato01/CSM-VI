import SwiftUI

struct HomeView: View {
    @AppStorage("baseCurrency") private var baseCurrency = "USD"
    @AppStorage("targetCurrency") private var targetCurrency = "JPY"
    @State private var exchangeRate: Double? = nil
    @State private var isLoading = false
    @State private var amount: String = "1" // Default amount

    let currencyList = ["USD", "EUR", "JPY", "GBP", "AUD", "CAD", "CHF", "CNY", "KRW"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Exchange Rate")
                .font(.title)
                .bold()

            // Base Currency Picker with Label
            VStack(alignment: .leading) {
                Text("From:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Picker("From", selection: $baseCurrency) {
                    ForEach(currencyList, id: \.self) { currency in
                        Text(currency)
                    }
                }
                .pickerStyle(.menu)
            }

            // Target Currency Picker with Label
            VStack(alignment: .leading) {
                Text("To:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Picker("To", selection: $targetCurrency) {
                    ForEach(currencyList, id: \.self) { currency in
                        Text(currency)
                    }
                }
                .pickerStyle(.menu)
            }

            // Amount to Convert
            HStack {
                Text("Amount:")
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }

            // Show exchange rate result
            if isLoading {
                ProgressView()
            } else if let rate = exchangeRate,
                      let amountDouble = Double(amount) {
                let result = amountDouble * rate
                Text("1 \(baseCurrency) = \(String(format: "%.2f", rate)) \(targetCurrency)")
                Text("\(amount) \(baseCurrency) = \(String(format: "%.2f", result)) \(targetCurrency)")
                    .font(.headline)
            }

            // Refresh Button
            Button("Refresh") {
                fetchExchangeRate()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .onChange(of: baseCurrency) { _, _ in fetchExchangeRate() }
        .onChange(of: targetCurrency) { _, _ in fetchExchangeRate() }
    }

    // Fetch Exchange Rate
    func fetchExchangeRate() {
        isLoading = true
        let urlString = "https://api.frankfurter.app/latest?from=\(baseCurrency)&to=\(targetCurrency)"

        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
            }

            if let data = data {
                print(String(data: data, encoding: .utf8) ?? "No data string")
                do {
                    let result = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
                    if let rate = result.rates[targetCurrency] {
                        DispatchQueue.main.async {
                            exchangeRate = rate
                        }
                    } else {
                        print("No exchange rate found in response.")
                    }
                } catch {
                    print("Error decoding JSON:", error)
                }
            }
        }.resume()
    }
}

// Response Struct
struct ExchangeRateResponse: Codable {
    let rates: [String: Double]
}
