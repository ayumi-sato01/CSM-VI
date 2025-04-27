import SwiftUI

struct FavoritePair: Identifiable, Codable, Hashable {
    var id = UUID()
    var base: String
    var target: String
}

struct FavoriteRatesView: View {
    @AppStorage("favoritePairs") private var favoritePairsData: Data = Data()
    @State private var favoritePairs: [FavoritePair] = []
    @State private var latestRates: [String: (rate: Double, date: String)] = [:]
    @State private var previousRates: [String: (rate: Double, date: String)] = [:]
    @State private var isLoading = false

    @State private var selectedBase = "USD"
    @State private var selectedTarget = "JPY"

    let currencyList = ["USD", "EUR", "JPY", "GBP", "AUD", "CAD", "CHF", "CNY", "KRW", "ZAR"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("⭐️ Favorite Rates")
                    .font(.title2)
                    .bold()

                HStack {
                    VStack(alignment: .leading) {
                        Text("From")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Picker("Base", selection: $selectedBase) {
                            ForEach(currencyList, id: \.self) { currency in
                                Text(currency)
                            }
                        }.pickerStyle(.menu)
                    }

                    VStack(alignment: .leading) {
                        Text("To")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Picker("Target", selection: $selectedTarget) {
                            ForEach(currencyList, id: \.self) { currency in
                                Text(currency)
                            }
                        }.pickerStyle(.menu)
                    }

                    Button("Add") {
                        if selectedBase != selectedTarget {
                            let pair = FavoritePair(base: selectedBase, target: selectedTarget)
                            if !favoritePairs.contains(pair) {
                                favoritePairs.append(pair)
                                saveFavorites()
                                fetchRates()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                if favoritePairs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)
                        Text("Let’s set up your favorite currency exchange!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                } else if isLoading {
                    ProgressView()
                } else {
                    List {
                        ForEach(favoritePairs) { pair in
                            let key = "\(pair.base)_\(pair.target)"
                            if let latest = latestRates[key], let previous = previousRates[key] {
                                let change = latest.rate - previous.rate
                                let symbol = change > 0 ? "🔺" : (change < 0 ? "🔻" : "➖")

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(pair.base) → \(pair.target)")
                                        .font(.headline)
                                    Text("Latest (\(latest.date)): \(String(format: "%.4f", latest.rate))")
                                    Text("Previous (\(previous.date)): \(String(format: "%.4f", previous.rate))")
                                    Text("Change: \(symbol) \(String(format: "%.5f", abs(change)))")
                                        .foregroundColor(change > 0 ? .green : (change < 0 ? .red : .gray))
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        if let index = favoritePairs.firstIndex(of: pair) {
                                            deletePairs(at: IndexSet(integer: index))
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .onAppear {
                loadFavorites()
                fetchRates()
            }
        }
    }

    func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoritePairs) {
            favoritePairsData = data
        }
    }

    func loadFavorites() {
        if let decoded = try? JSONDecoder().decode([FavoritePair].self, from: favoritePairsData) {
            favoritePairs = decoded
        }
    }

    func deletePairs(at offsets: IndexSet) {
        favoritePairs.remove(atOffsets: offsets)
        saveFavorites()
        fetchRates()
    }

    func fetchRates() {
        isLoading = true
        latestRates = [:]
        previousRates = [:]

        var completedRequests = 0
        let totalRequests = favoritePairs.count * 2

        for pair in favoritePairs {
            let key = "\(pair.base)_\(pair.target)"
            let latestURL = URL(string: "https://api.frankfurter.app/latest?from=\(pair.base)&to=\(pair.target)")!
            URLSession.shared.dataTask(with: latestURL) { data, _, _ in
                if let data = data,
                   let latestResult = try? JSONDecoder().decode(ExchangeRateResponseWithDate.self, from: data),
                   let latestRate = latestResult.rates[pair.target] {
                    
                    let latestDateStr = latestResult.date
                    
                    DispatchQueue.main.async {
                        latestRates[key] = (latestRate, latestDateStr)
                        completedRequests += 1
                    }
                    
                    if let latestDate = latestResult.date.toDate() {
                        let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: latestDate)!
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        let previousDateStr = formatter.string(from: previousDate)
                        
                        let previousURL = URL(string: "https://api.frankfurter.app/\(previousDateStr)?from=\(pair.base)&to=\(pair.target)")!
                        URLSession.shared.dataTask(with: previousURL) { pdata, _, _ in
                            if let pdata = pdata,
                               let previousResult = try? JSONDecoder().decode(ExchangeRateResponseWithDate.self, from: pdata),
                               let previousRate = previousResult.rates[pair.target] {
                                DispatchQueue.main.async {
                                    previousRates[key] = (previousRate, previousResult.date)
                                    completedRequests += 1
                                    if completedRequests == totalRequests {
                                        isLoading = false
                                    }
                                }
                            } else {
                                DispatchQueue.main.async {
                                    completedRequests += 1
                                    if completedRequests == totalRequests {
                                        isLoading = false
                                    }
                                }
                            }
                        }.resume()
                    }
                } else {
                    DispatchQueue.main.async {
                        completedRequests += 2 // because we won't fetch previous if failed
                        if completedRequests == totalRequests {
                            isLoading = false
                        }
                    }
                }
            }.resume()
        }
    }
}

struct ExchangeRateResponseWithDate: Codable {
    var amount: Double
    var base: String
    var date: String
    var rates: [String: Double]
}

extension String {
    func toDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: self)
    }
}
