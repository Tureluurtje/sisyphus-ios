// NavBar

import SwiftUI

struct MicroInteractionButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.78 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(
                reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}

extension ButtonStyle where Self == MicroInteractionButtonStyle {
    static var microInteraction: MicroInteractionButtonStyle { .init() }
}

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
        .onChange(of: selected) { _, _ in
            Haptics.selection()
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
