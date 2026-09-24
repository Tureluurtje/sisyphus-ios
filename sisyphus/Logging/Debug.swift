//
//  Debug.swift
//  sisyphus
//

import Foundation

enum Debug {
    /// Multiplier applied to artificial delays used purely to make
    /// transitions visible during development. Set to 1 in release,
    /// crank to 8–10 in debug while you're tuning animations.
    static var animationSlowdown: Double {
        #if DEBUG
        return 8.0
        #else
        return 1.0
        #endif
    }

    /// Convenience: `await Debug.pause(0.18)` respects the multiplier.
    static func pause(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds * animationSlowdown))
    }
}
