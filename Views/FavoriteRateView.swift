import SwiftUI

struct FavoritePair: Identifiable, Codable, Hashable {
    var id = UUID()
    var base: String
    var target: String
}

struct FavoriteRatesView: View {
    @AppStorage("favoritePairs") private var favoritePairsData: Data = Data()
    @State private var favoritePairs: [FavoritePair] = []
    @State private var todayRates: [String: Double] = [:]
    @State private var yesterdayRates: [String: Double] = [:]
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
                            let today = todayRates[key] ?? 0
                            let yesterday = yesterdayRates[key] ?? 0
                            let change = today - yesterday
                            let symbol = change > 0 ? "🔺" : (change < 0 ? "🔻" : "➖")

                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(pair.base) → \(pair.target)")
                                    .font(.headline)
                                Text("Today: \(String(format: "%.2f", today))")
                                Text("Yesterday: \(String(format: "%.2f", yesterday))")
                                Text("Change: \(symbol) \(String(format: "%.2f", abs(change)))")
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
        todayRates = [:]
        yesterdayRates = [:]

        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let yesterdayStr = formatter.string(from: yesterday)

        for pair in favoritePairs {
            let key = "\(pair.base)_\(pair.target)"

            // Today's rate
            let todayURL = URL(string: "https://api.frankfurter.app/latest?from=\(pair.base)&to=\(pair.target)")!
            URLSession.shared.dataTask(with: todayURL) { data, _, _ in
                if let data = data,
                   let result = try? JSONDecoder().decode(ExchangeRateResponse.self, from: data),
                   let rate = result.rates[pair.target] {
                    DispatchQueue.main.async {
                        todayRates[key] = rate
                    }
                }
            }.resume()

            // Yesterday's rate
            let yesterdayURL = URL(string: "https://api.frankfurter.app/\(yesterdayStr)?from=\(pair.base)&to=\(pair.target)")!
            URLSession.shared.dataTask(with: yesterdayURL) { data, _, _ in
                if let data = data,
                   let result = try? JSONDecoder().decode(ExchangeRateResponse.self, from: data),
                   let rate = result.rates[pair.target] {
                    DispatchQueue.main.async {
                        yesterdayRates[key] = rate
                        isLoading = false
                    }
                }
            }.resume()
        }
    }
}
