import SwiftUI

struct LogView: View {
    @AppStorage("logHistory") private var logHistoryData: Data = Data()
    @State private var logs: [LogEntry] = []

    @State private var date = Date()
    @State private var base = "USD"
    @State private var target = "JPY"
    @State private var amount = ""
    @State private var note = ""
    @State private var isLoading = false

    private let currencyList = ["USD", "EUR", "JPY", "GBP", "AUD", "CAD", "CHF", "CNY", "KRW"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("📝 Log Your Exchange")
                    .font(.title2)
                    .bold()

                DatePicker("Date of Exchange", selection: $date, displayedComponents: [.date, .hourAndMinute])

                HStack {
                    VStack(alignment: .leading) {
                        Text("From:")
                        Picker("Base", selection: $base) {
                            ForEach(currencyList, id: \.self) { currency in
                                Text(currency)
                            }
                        }.pickerStyle(.menu)
                    }

                    VStack(alignment: .leading) {
                        Text("To:")
                        Picker("Target", selection: $target) {
                            ForEach(currencyList, id: \.self) { currency in
                                Text(currency)
                            }
                        }.pickerStyle(.menu)
                    }
                }

                HStack {
                    Text("Amount:")
                    TextField("e.g. 100", text: $amount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }

                TextField("Optional Note", text: $note)
                    .textFieldStyle(.roundedBorder)

                Button(action: fetchAndLog) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Save Log")
                    }
                }
                .buttonStyle(.borderedProminent)

                Divider()

                Text("📚 History")
                    .font(.headline)

                ForEach(logs.sorted(by: { $0.timestamp > $1.timestamp })) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(log.amount, specifier: "%.2f") \(log.base) → \(log.convertedAmount, specifier: "%.2f") \(log.target) @ \(log.rate, specifier: "%.4f")")
                            .font(.subheadline)
                        if !log.note.isEmpty {
                            Text("\"\(log.note)\"")
                                .font(.caption)
                                .italic()
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                    Divider()
                }
            }
            .padding()
        }
        .onAppear(perform: loadLogs)
    }

    func fetchAndLog() {
        guard let amountDouble = Double(amount), !amountDouble.isNaN else { return }
        isLoading = true

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)

        let urlString = "https://api.frankfurter.app/\(dateStr)?from=\(base)&to=\(target)"
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }

            do {
                let result = try JSONDecoder().decode(SingleDayRateResponse.self, from: data)

                if let rate = result.rates[target] {
                    let converted = amountDouble * rate

                    let entry = LogEntry(
                        timestamp: Date(),
                        base: base,
                        target: target,
                        amount: amountDouble,
                        convertedAmount: converted,
                        rate: rate,
                        note: note
                    )

                    DispatchQueue.main.async {
                        logs.append(entry)
                        saveLogs()
                        clearForm()
                        isLoading = false
                    }
                } else {
                    print("⚠️ No rate found for \(target)")
                    DispatchQueue.main.async {
                        isLoading = false
                    }
                }
            } catch {
                print("Decode error:", error)
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }.resume()
    }

    func saveLogs() {
        if let encoded = try? JSONEncoder().encode(logs) {
            logHistoryData = encoded
        }
    }

    func loadLogs() {
        if let decoded = try? JSONDecoder().decode([LogEntry].self, from: logHistoryData) {
            logs = decoded
        }
    }

    func clearForm() {
        amount = ""
        note = ""
        date = Date()
    }
}
#Preview {
    LogView()
}
