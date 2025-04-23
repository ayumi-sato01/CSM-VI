import Foundation

struct LogEntry: Identifiable, Codable {
    var id = UUID()
    let timestamp: Date
    let base: String
    let target: String
    let amount: Double
    let convertedAmount: Double
    let rate: Double
    let note: String
}

