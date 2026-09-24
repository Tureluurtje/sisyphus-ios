import SwiftUI

struct UpdateRequiredView: View {
    let requirement: AppUpdateRequirement

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "arrow.down.app.fill")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Update required")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .multilineTextAlignment(.center)

                Text("A newer version of Sisyphus is ready. Update to keep learning and sync your progress.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 4) {
                Text("Current version \(requirement.currentVersion)")
                Text("Latest version \(requirement.latestVersion)")
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            if let storeURL = requirement.storeURL {
                Link(destination: storeURL) {
                    Label("Update Sisyphus", systemImage: "arrow.down.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("Open the App Store to update Sisyphus.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .interactiveDismissDisabled(true)
    }
}
