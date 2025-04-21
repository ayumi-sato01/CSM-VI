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


    let currencyList = ["USD", "EUR", "JPY", "GBP", "AUD", "CAD", "CHF", "CNY", "KRW"]

    var body: some View {
        VStack(spacing: 20) {
            Text("📈 30-Day Exchange Rate")
                .font(.title2)
                .bold()
            
            // Currency selection
            VStack(alignment: .leading, spacing: 10) {
                Text("From:")
                Picker("From", selection: $baseCurrency) {
                    ForEach(currencyList, id: \.self) { currency in
                        Text(currency)
                    }
                }
                .pickerStyle(.menu)
                
                Text("To:")
                Picker("To", selection: $targetCurrency) {
                    ForEach(currencyList, id: \.self) { currency in
                        Text(currency)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Button("Load Chart") {
                fetchRates()
            }
            .buttonStyle(.borderedProminent)
            
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
                        .symbol(Circle()) // 👈 makes dots tappable
                        .annotation(position: .top) {
                            Text(String(format: "%.2f", rate.rate))
                                .font(.caption2)
                                .padding(5)
                                .background(Color.white)
                                .cornerRadius(5)
                                .shadow(radius: 2)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day(), centered: true)
                    }
                }
                .chartYScale(domain: minY...maxY)
                .chartScrollableAxes(.horizontal)
                .chartScrollPosition(x: $scrollPosition)
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle().fill(Color.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let location = value.location
                                        if let date: Date = proxy.value(atX: location.x) {
                                            if let closest = rates.min(by: {
                                                abs($0.date.timeIntervalSince1970 - date.timeIntervalSince1970) <
                                                abs($1.date.timeIntervalSince1970 - date.timeIntervalSince1970)
                                            }) {
                                                selectedRate = closest
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        selectedRate = nil
                                    }
                            )
                    }
                }

                .frame(height: 300)
                .padding()
                if let selected = selectedRate {
                    VStack(spacing: 5) {
                        Text("\(selected.date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                        Text(String(format: "%.2f %@", selected.rate, targetCurrency))
                            .bold()
                    }
                    .padding(8)
                    .background(.thinMaterial)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 1))
                    .transition(.opacity)
                }
            }
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
                }
                .sorted(by: { $0.date < $1.date })

                let minRate = parsedRates.map { $0.rate }.min() ?? 0
                let maxRate = parsedRates.map { $0.rate }.max() ?? 0

                DispatchQueue.main.async {
                    rates = parsedRates
                    minY = minRate
                    maxY = maxRate
                    isLoading = false
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

struct HistoricalRate: Identifiable {
    var id: Date { date }
    let date: Date
    let rate: Double
}

struct ChartExchangeRateResponse: Codable {
    let rates: [String: [String: Double]]
}
