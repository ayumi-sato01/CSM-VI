import SwiftUI
import Charts

struct DashboardView: View {
    @State private var currentTime = Date()
    
    @AppStorage("dashboardBaseCurrency") private var base = "USD"
    @AppStorage("dashboardTargetCurrency") private var target = "JPY"
    
    @State private var liveRate: Double? = nil
    @State private var rates: [HistoricalRate] = []
    @State private var isLoading = false

    let currencyList = ["USD", "EUR", "JPY", "GBP", "AUD", "CAD", "CHF", "CNY", "KRW", "ZAR"]
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Zenny")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            Text("Currency Tracker")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text(currentTime.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                            Text(currentTime.formatted(date: .omitted, time: .standard))
                                .font(.caption2)
                                .monospacedDigit()
                        }
                    }
                    .onReceive(timer) { _ in currentTime = Date() }

                    // Pickers
                    HStack {
                        VStack(alignment: .leading) {
                            Text("From")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Picker("From", selection: $base) {
                                ForEach(currencyList, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                        }

                        VStack(alignment: .leading) {
                            Text("To")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Picker("To", selection: $target) {
                                ForEach(currencyList, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    .onChange(of: base) { _, _ in fetchLiveRate(); fetchRates() }
                    .onChange(of: target) { _, _ in fetchLiveRate(); fetchRates() }

                    // Live Rate
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 60)
                        if let rate = liveRate {
                            Text("1 \(base) = \(String(format: "%.2f", rate)) \(target)")
                                .font(.title3)
                        } else {
                            Text("Fetching rate...")
                                .foregroundColor(.gray)
                        }
                    }

                    // Graph
                    if isLoading {
                        ProgressView()
                    } else if !rates.isEmpty {
                        Chart {
                            ForEach(rates.prefix(5)) { rate in
                                LineMark(
                                    x: .value("Date", rate.date),
                                    y: .value("Rate", rate.rate)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(.blue)
                                .symbol(Circle())
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 5)) {
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.month().day(), centered: true)
                            }
                        }
                        .frame(height: 200)
                    }

                    // Nav Buttons
                    HStack(spacing: 20) {
                        bottomButton(icon: "note.text", label: "Log", destination: LogView())
                        bottomButton(icon: "chart.xyaxis.line", label: "Graph", destination: GraphView())
                        bottomButton(icon: "heart", label: "Favorite", destination: FavoriteRatesView())
                        bottomButton(icon: "bell", label: "Notification", destination: AlertSettingsView())
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .onAppear {
                fetchLiveRate()
                fetchRates()
            }
        }
    }

    func fetchLiveRate() {
        let urlString = "https://api.frankfurter.app/latest?from=\(base)&to=\(target)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let result = try? JSONDecoder().decode(ExchangeRateResponse.self, from: data),
                  let rate = result.rates[target] else { return }
            DispatchQueue.main.async {
                self.liveRate = rate
            }
        }.resume()
    }

    func fetchRates() {
        isLoading = true
        let today = Date()
        let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: today)!

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startDate = formatter.string(from: fiveDaysAgo)
        let endDate = formatter.string(from: today)

        let urlString = "https://api.frankfurter.app/\(startDate)..\(endDate)?from=\(base)&to=\(target)"
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let result = try? JSONDecoder().decode(ChartExchangeRateResponse.self, from: data) else {
                DispatchQueue.main.async { isLoading = false }
                return
            }

            let parsedRates = result.rates.compactMap { dateStr, rateDict -> HistoricalRate? in
                if let date = formatter.date(from: dateStr),
                   let rate = rateDict[target] {
                    return HistoricalRate(date: date, rate: rate)
                }
                return nil
            }.sorted(by: { $0.date < $1.date })

            DispatchQueue.main.async {
                rates = parsedRates
                isLoading = false
            }
        }.resume()
    }

    func bottomButton(icon: String, label: String, destination: some View) -> some View {
        NavigationLink(destination: destination) {
            VStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
            }
        }
    }
}

#Preview {
    DashboardView()
}
