// ProfileView

import SwiftUI
import OSLog
import SwiftData

// MARK: - Supported languages

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case dutch   = "nl"
    case french  = "fr"
    case german  = "de"
    case spanish = "es"

    var id: String { rawValue }

    /// Label shown in the picker.
    var displayName: String {
        switch self {
        case .system:  return "System"
        case .english: return "English"
        case .dutch:   return "Nederlands"
        case .french:  return "Français"
        case .german:  return "Deutsch"
        case .spanish: return "Español"
        }
    }

    /// Resolved locale for the whole app. `system` falls through to the
    /// device locale so SwiftUI handles it automatically.
    var locale: Locale? {
        switch self {
        case .system:  return nil
        case .english: return Locale(identifier: "en")
        case .dutch:   return Locale(identifier: "nl")
        case .french:  return Locale(identifier: "fr")
        case .german:  return Locale(identifier: "de")
        case .spanish: return Locale(identifier: "es")
        }
    }
}

// MARK: - Profile

struct ProfileView: View {
    let userProfile: UserProfile?
    let onFinished: (AppState) -> Void

    /// Called when the user changes their year. The closure is expected to
    /// PATCH the backend and then trigger an app-wide refresh.
    var onGradeChanged: ((Int) async -> Void)? = nil

    @State private var selectedGrade: Int

    init(
        userProfile: UserProfile?,
        onFinished: @escaping (AppState) -> Void,
        onGradeChanged: ((Int) async -> Void)? = nil
    ) {
        self.userProfile = userProfile
        self.onFinished = onFinished
        self.onGradeChanged = onGradeChanged
        _selectedGrade = State(initialValue: userProfile?.grade ?? 1)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                profileCard
                activitySection
                SettingsView(
                    onFinished: onFinished,
                    userProfile: userProfile,
                    selectedGrade: $selectedGrade,
                    onGradeChanged: onGradeChanged
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("Profile")
    }

    // MARK: Identity card
    private var profileCard: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))

                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(userProfile?.username ?? "?")
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Year \(selectedGrade)")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundColor(.secondary)

                if let email = userProfile?.email, !email.isEmpty {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: Activity
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                ProfileStat(
                    title: "Streak",
                    value: userProfile.map { String($0.streak) } ?? "?"
                )
                ProfileStat(
                    title: "Learned",
                    value: userProfile.map { String($0.totalWordsLearned) } ?? "?"
                )
            }
        }
    }
}

// MARK: - Stat card

private struct ProfileStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject var errorManager: ErrorManager
    let onFinished: (AppState) -> Void
    let userProfile: UserProfile?
    @Binding var selectedGrade: Int
    var onGradeChanged: ((Int) async -> Void)? = nil

    @AppStorage("dailyReminderEnabled") private var notificationsEnabled = false
    @AppStorage("repeatIncorrectWords") private var repeatIncorrectWords = true
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.system.rawValue
    @AppStorage("appLaunchCount") private var appLaunchCount = 0

    @State private var isConfirming = false
    @State private var isConfirmingGradeChange = false
    @State private var isConfirmingGradeRefresh = false
    @State private var pendingGrade: Int?

    private let gradeRange: ClosedRange<Int> = 1...6

    /// Bound view of the raw `@AppStorage` string.
    private var appLanguage: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage(rawValue: appLanguageRaw) ?? .system },
            set: { appLanguageRaw = $0.rawValue }
        )
    }

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
                gradeRow
                divider
                // languageRow
                divider
                row {
                    Toggle("Daily reminder", isOn: $notificationsEnabled)
                }
                divider
                row {
                    Toggle("Repeat missed words", isOn: $repeatIncorrectWords)
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
                if appLaunchCount >= 5 && AppReviewManager.canShowRateButton {
                    divider
                    row {
                        Button("Rate Sisyphus") {
                            AppReviewManager.requestReview()
                        }
                        .tint(.accentColor)
                    }
                }
            }
        }
        .onChange(of: selectedGrade) { _, newValue in
            guard newValue != userProfile?.grade else { return }
            Task {
                await onGradeChanged?(newValue)
            }
        }
    }

    // MARK: Grade row
    private var gradeRow: some View {
        row {
            Button {
                isConfirmingGradeChange = true
            } label: {
                HStack {
                    Text("Grade")
                        .foregroundColor(.primary)

                    Spacer()

                    Text("Grade \(selectedGrade)")
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Color.secondary.opacity(0.5))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .confirmationDialog(
                "Change year",
                isPresented: $isConfirmingGradeChange,
                titleVisibility: .visible
            ) {
                ForEach(gradeRange, id: \.self) { grade in
                    if grade != selectedGrade {
                        Button("Year \(grade)") {
                            pendingGrade = grade
                            isConfirmingGradeRefresh = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .confirmationDialog(
                "This will refresh the app",
                isPresented: $isConfirmingGradeRefresh,
                titleVisibility: .visible
            ) {
                Button("Change to Year \(pendingGrade ?? selectedGrade)", role: .destructive) {
                    if let pendingGrade {
                        selectedGrade = pendingGrade
                    }
                    pendingGrade = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingGrade = nil
                }
            }
        }
    }

    // MARK: Language row
    private var languageRow: some View {
        row {
            HStack {
                Text("Language")

                Spacer()

                Picker("Language", selection: appLanguage) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(.secondary)
            }
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
                .tracking(1.2)
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
            )
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
                    errorManager.show("Enable notifications for Sisyphus in Settings to turn this on.")
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
            ProfileView(
                userProfile: UserProfile(
                    userId: UUID(),
                    username: "Preview",
                    email: "preview@apple.com",
                    grade: 3,
                    totalWordsLearned: 200,
                    streak: 57,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                onFinished: { _ in }
            )
        }
    }
}
