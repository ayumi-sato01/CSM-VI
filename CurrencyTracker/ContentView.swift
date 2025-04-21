import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("💱 Currency Tracker")
                    .font(.largeTitle)
                    .bold()

                NavigationLink("Check Exchange Rate", destination: HomeView())
                    .buttonStyle(.borderedProminent)

                NavigationLink("Set Alert", destination: AlertSettingsView())
                    .buttonStyle(.bordered)

                NavigationLink("View Monthly Graph", destination: GraphView())
                    .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
