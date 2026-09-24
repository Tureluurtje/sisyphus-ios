//
//  ContentView.swift
//  sisyphus
//
//  Created by Arthur Kwak on 06/05/2026.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        RootView()
            .withErrorHost()
            .buttonStyle(.microInteraction)
            .onAppear {
                AppReviewManager.recordLaunch()
            }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
