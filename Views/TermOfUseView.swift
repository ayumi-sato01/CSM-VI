import SwiftUI

struct TermsOfUseView: View {
    @AppStorage("hasAgreedToTerms") private var hasAgreedToTerms = false

    var body: some View {
        VStack(spacing: 24) {
            Text("📄 Terms of Use")
                .font(.title2)
                .bold()

            ScrollView {
                Text("""
Welcome to Zenny! By using this app, you agree to the following:

- This app provides currency exchange rates for informational purposes only.
- We are not licensed financial advisors and do not provide trading or investment advice.
- Exchange rates are provided via third-party APIs and may not always be 100% accurate or up to date.
- This app does not support exchange rate tracking for countries under U.S. sanctions.
- Use of the app is at your own risk.

Please review the full Terms of Use before continuing.
""")
                .font(.footnote)
                .padding()
            }

            Button("I Agree and Continue") {
                hasAgreedToTerms = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
