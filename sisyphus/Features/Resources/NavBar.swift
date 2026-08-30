// NavBar

import SwiftUI

struct NavBar<Content: View>: View {
    @Binding var selected: String
    private let content: Content

    init(selected: Binding<String>, @ViewBuilder content: () -> Content) {
        self._selected = selected
        self.content = content()
    }

    var body: some View {
        TabView(selection: $selected) {
            content
        }
    }
}

struct NavBar_Previews: PreviewProvider {
    static var previews: some View {
        NavBar(selected: .constant("home")) {
            Text("Home")
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag("home")

            Text("Learn")
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }
                .tag("learn")

            Text("Profile")
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag("profile")
        }
    }
}
