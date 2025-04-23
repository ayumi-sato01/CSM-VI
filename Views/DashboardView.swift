import SwiftUI

struct DashboardView: View {
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack{
            ScrollView {
                VStack(spacing: 16) {
                    // Top Header: Zenny + Date/Time
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Zenny")
                                .font(.system(size: 28, weight: .bold)) // slightly smaller
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
                    .onReceive(timer) { _ in
                        currentTime = Date()
                    }
                    
                    // Exchange Rate Input + Result
                    VStack(spacing: 12) {
                        HStack {
                            Text("From:")
                            TextField("USD", text: .constant(""))
                                .textFieldStyle(.roundedBorder)
                            
                            Text("To:")
                            TextField("JPY", text: .constant(""))
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 60)
                            Text("Rate: 153.22")
                                .font(.title3) // smaller font
                        }
                    }
                    
                    // Graph Placeholder
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 150)
                        .overlay(Text("5-Day Trend Graph").foregroundColor(.gray))
                    
                    // Bottom nav buttons with Log
                    HStack(spacing: 20) {
                        bottomButton(icon: "note.text", label: "Log", destination: LogView())
                        bottomButton(icon: "chart.xyaxis.line", label: "Graph", destination: GraphView())
                        bottomButton(icon: "heart", label: "Favorite", destination: Text("Favorites Coming Soon"))
                        bottomButton(icon: "gear", label: "Settings", destination: AlertSettingsView())
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Helper for bottom buttons
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
