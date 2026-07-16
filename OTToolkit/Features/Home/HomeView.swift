import SwiftUI

struct HomeView: View {
    var body: some View {
        Text("home.title")
            .font(.title)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("home.title")
    }
}
