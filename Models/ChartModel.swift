import Foundation

struct HistoricalRate: Identifiable {
    var id: Date { date }
    let date: Date
    let rate: Double
}

struct ChartExchangeRateResponse: Codable {
    let rates: [String: [String: Double]]
}

struct SingleDayRateResponse: Codable {
    let rates: [String: Double]
}
