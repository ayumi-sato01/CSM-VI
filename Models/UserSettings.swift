import Foundation

class UserSettings: ObservableObject {
    @Published var baseCurrency: String = "USD"
    @Published var targetCurrency: String = "JPY"
    @Published var alertRate: Double = 140.0
    @Published var isAlertEnabled: Bool = true
}
