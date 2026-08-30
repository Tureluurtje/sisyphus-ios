// ProfileView

import SwiftUI
import OSLog
import SwiftData

struct ProfileView: View {
    let userProfile: UserProfile?

    let onFinished: (AppState) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.red.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 76, height: 76)

                        Image(systemName: "person.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(userProfile?.username ?? "?")
                            .font(.title2.weight(.semibold))
                        Text("Year \(userProfile.map { String($0.grade) } ?? "?")")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Activity")
                        .font(.caption)
                        .textCase(.uppercase)
                        .foregroundColor(.secondary)

                    HStack {
                        ProfileStat(title: "Streak", value: "\(userProfile.map { String($0.streak) } ?? "?")")
                        ProfileStat(title: "Learned", value: "\(userProfile.map { String($0.totalWordsLearned) } ?? "?")")
                    }
                }

                SettingsView(onFinished: onFinished, userProfile: userProfile)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .trackScreen("Profile")
    }
}

private struct ProfileStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.title3.weight(.semibold))
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.08)))
    }
}

struct SettingsView: View {

    @EnvironmentObject var errorManager: ErrorManager
    let onFinished: (AppState) -> Void
    let userProfile: UserProfile?

    @AppStorage("dailyReminderEnabled") private var notificationsEnabled = false
    @State private var isConfirming = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            settingsSection("Account") {
                row { LabeledContent("Username", value: userProfile?.username ?? "?") }
                divider
                row { LabeledContent("Email", value: userProfile?.email ?? "?") }
                divider
                row {
                    Button("Logout") {
                        Task { await handleLogout() }
                    }
                    .tint(.red)
                }
                divider
                row {
                    Button("Delete account") {
                        isConfirming = true
                    }
                    .confirmationDialog(
                        "Are you sure you want to logout?\nThis action is irreversible.",
                        isPresented: $isConfirming,
                        titleVisibility: .visible
                    ) {
                        Button("Continue", role: .destructive) {
                            Task { await handleAccountDeletion() }
                        }

                        Button("Cancel", role: .cancel) { }
                    }
                    .tint(.red)
                }
            }
            settingsSection("Learning") {
                row {
                    Toggle("Daily reminder", isOn: $notificationsEnabled)
                }
            }
            .onChange(of: notificationsEnabled) { _, isEnabled in
                Task { await handleNotificationsToggle(isEnabled) }
            }
            .task {
                await syncNotificationToggleWithSystemState()
            }

            settingsSection("About") {
                row { LabeledContent("Credits", value: "Arthur Kwak") }
                divider
                row {
                    Link("Contact support", destination: URL(string: "mailto:tureluurtje.1@gmail.com")!)
                }
                divider
                row {
                    Link("Legal", destination: URL(string: "https://sisyphus.kwako.nl/legal")!)
                }
            }

            #if DEBUG
            settingsSection("Debug") {
                row {
                    Button("Reset onboarding") {
                        OnboardingStore.hasCompletedOnboarding = false
                        OnboardingInstrumentation.resetForTesting()
                    }
                }
            }
            #endif
        }
    }

    // MARK: - Building blocks
    @ViewBuilder
    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                content()
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.08)))
        }
    }

    private func row<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
    }

    private var divider: some View {
        Divider()
            .padding(.leading, 16)
    }

    // MARK: - Actions
    private func handleLogout() async {
        do {
            try await logoutService()
        } catch {
            AppLogger.ui.error("Logout request failed, clearing local session anyway: \(error.localizedDescription, privacy: .public)")
            errorManager.show(error.localizedDescription)
        }
        await MainActor.run {
            onFinished(.unauthenticated)
        }
    }

    private func handleAccountDeletion() async {
        do {
            try await accountDeletionService()
        } catch {
            AppLogger.ui.error("Account deletion request failed, clearing local session anyway: \(error.localizedDescription, privacy: .public)")
            errorManager.show(error.localizedDescription)
        }
        await MainActor.run {
            onFinished(.unauthenticated)
        }
    }

    private func handleNotificationsToggle(_ isEnabled: Bool) async {
        if isEnabled {
            let granted = await NotificationManager.shared.requestAuthorization()
            if granted {
                await NotificationManager.shared.scheduleDailyReminder()
            } else {
                await MainActor.run {
                    notificationsEnabled = false
                    errorManager.show("Enable notifications for LatiLearn in Settings to turn this on.")
                }
            }
        } else {
            await NotificationManager.shared.cancelDailyReminder()
        }
    }

    /// The toggle reflects a stored preference, but the user can revoke
    /// notification permission from system Settings without touching it —
    /// re-check the real authorization status whenever this screen appears.
    private func syncNotificationToggleWithSystemState() async {
        guard notificationsEnabled else { return }

        let status = await NotificationManager.shared.authorizationStatus()
        if status != .authorized && status != .provisional {
            await MainActor.run {
                notificationsEnabled = false
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView(userProfile: UserProfile(userId: UUID(), username: "Preview", email: "preview@apple.com", grade: 3, totalWordsLearned: 200, streak: 57, createdAt: Date(), updatedAt: Date()), onFinished: { _ in })
        }
    }
}
