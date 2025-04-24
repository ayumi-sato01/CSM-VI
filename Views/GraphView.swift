import SwiftUI
import Charts

struct GraphView: View {
    @State private var baseCurrency = "USD"
    @State private var targetCurrency = "JPY"
    @State private var rates: [HistoricalRate] = []
    @State private var isLoading = false
    @State private var minY: Double = 0
    @State private var maxY: Double = 0
    @State private var scrollPosition: Date = Date()
    @State private var selectedRate: HistoricalRate?

    let currencyList = ["USD", "EUR", "JPY", "GBP", "AUD", "CAD", "CHF", "CNY", "KRW", "ZAR"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title
                Text("📈 30-Day Exchange Rate")
                    .font(.title2)
                    .fontWeight(.semibold)

                // Currency Selection
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("From:")
                            .font(.caption)
                        Picker("From", selection: $baseCurrency) {
                            ForEach(currencyList, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.menu)
                    }

                    VStack(alignment: .leading) {
                        Text("To:")
                            .font(.caption)
                        Picker("To", selection: $targetCurrency) {
                            ForEach(currencyList, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.menu)
                    }
                }

                // Load Button
                Button("Load Chart") {
                    fetchRates()
                }
                .buttonStyle(.borderedProminent)

                // Graph View
                if isLoading {
                    ProgressView()
                } else if rates.isEmpty {
                    Text("Select currencies and tap 'Load Chart'")
                        .foregroundColor(.gray)
                } else {
                    Chart {
                        ForEach(rates) { rate in
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
                        let formatter: DateFormatter = {
                            let f = DateFormatter()
                            f.dateFormat = "M/dd"
                            return f
                        }()

                        AxisMarks(values: .stride(by: .day, count: 5)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(formatter.string(from: date))
                                }
                            }
                        }
                    }
                    .chartYScale(domain: minY...maxY)
                    .chartOverlay { proxy in
                        GeometryReader { geo in
                            Rectangle().fill(Color.clear).contentShape(Rectangle())
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let location = value.location
                                            if let date: Date = proxy.value(atX: location.x) {
                                                selectedRate = rates.min(by: {
                                                    abs($0.date.timeIntervalSince1970 - date.timeIntervalSince1970) <
                                                    abs($1.date.timeIntervalSince1970 - date.timeIntervalSince1970)
                                                })
                                            }
                                        }
                                        .onEnded { _ in
                                            selectedRate = nil
                                        }
                                )
                        }
                    }
                    .frame(height: 300)
                    .padding(.bottom, selectedRate == nil ? 0 : 8)

                    if let selected = selectedRate {
                        VStack(spacing: 4) {
                            Text("\(selected.date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                            Text(String(format: "%.2f %@", selected.rate, targetCurrency))
                                .font(.headline)
                        }
                        .padding(8)
                        .background(.thinMaterial)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                        )
                        .transition(.opacity)
                    }
                }
            }
            .padding()
        }
    }

    func fetchRates() {
        isLoading = true
        let today = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: today)!

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let startDate = formatter.string(from: thirtyDaysAgo)
        let endDate = formatter.string(from: today)

        let urlString = "https://api.frankfurter.app/\(startDate)..\(endDate)?from=\(baseCurrency)&to=\(targetCurrency)"

        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }

            do {
                let result = try JSONDecoder().decode(ChartExchangeRateResponse.self, from: data)

                let parsedRates: [HistoricalRate] = result.rates.compactMap { dateStr, rateDict in
                    if let date = formatter.date(from: dateStr) {
                        return HistoricalRate(date: date, rate: rateDict[targetCurrency] ?? 0)
                    } else {
                        return nil
                    }
                }.sorted(by: { $0.date < $1.date })

                let minRate = parsedRates.map { $0.rate }.min() ?? 0
                let maxRate = parsedRates.map { $0.rate }.max() ?? 0

                DispatchQueue.main.async {
                    rates = parsedRates
                    minY = minRate
                    maxY = maxRate
                    isLoading = false
                    if let lastDate = parsedRates.last?.date {
                        scrollPosition = lastDate
                    }

                }
            } catch {
                print("Chart decode error:", error)
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }.resume()
    }
}
