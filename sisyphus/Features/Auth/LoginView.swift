//
//  LoginView.swift
//  sisyphus
//

import SwiftUI
import OSLog

// MARK: - Login

struct LoginView: View {
    // MARK: - Inputs
    @State private var email: String = ""
    @State private var password: String = ""

    // MARK: - State
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var errorIsUnverified: Bool = false
    @State private var isResendingVerification: Bool = false
    @State private var verificationResentMessage: String?
    @State private var isPasswordVisible: Bool = false
    @State private var showForgotPassword = false
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    // MARK: - Dependencies
    var onAuthenticated: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                header

                VStack(spacing: 12) {
                    field(title: "Email", icon: "envelope") {
                        TextField("you@example.com", text: $email)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                            .onChange(of: email) { _, _ in
                                // The resend affordance is tied to the previous
                                // submission; clear it once the user edits the email.
                                if errorIsUnverified {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        errorIsUnverified = false
                                        verificationResentMessage = nil
                                    }
                                }
                            }
                    }

                    field(title: "Password", icon: "lock") {
                        Group {
                            if isPasswordVisible {
                                TextField("••••••••", text: $password)
                            } else {
                                SecureField("••••••••", text: $password)
                            }
                        }
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { submitLogin() }
                    } trailing: {
                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.microInteraction)
                        .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                    }

                    HStack {
                        Spacer()
                        Button("Forgot password?") {
                            showForgotPassword = true
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.accentColor)
                        .disabled(isLoading)
                    }
                    .padding(.top, -2)

                    if let errorMessage {
                        errorBanner(message: errorMessage)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    primaryButton(title: "Login", isLoading: isLoading, isEnabled: isFormValid) {
                        submitLogin()
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )

                NavigationLink {
                    RegisterView()
                } label: {
                    HStack(spacing: 4) {
                        Text("No account yet?")
                            .foregroundColor(.secondary)
                        Text("Register")
                            .foregroundColor(.accentColor)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.microInteraction)
                .disabled(isLoading)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .trackScreen("Login")
    }

    // MARK: - Error banner

    @ViewBuilder
    private func errorBanner(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                Text(message)
                    .font(.caption)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .leading)

            if errorIsUnverified {
                if let verificationResentMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text(verificationResentMessage)
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Button {
                        Task { await resendVerificationEmail() }
                    } label: {
                        HStack(spacing: 6) {
                            if isResendingVerification {
                                ProgressView()
                                    .controlSize(.mini)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.caption)
                            }
                            Text(isResendingVerification
                                 ? "Sending…"
                                 : "Resend verification email")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.microInteraction)
                    .disabled(isResendingVerification || email.isEmpty)
                }
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 8) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 64)

            Text("Sisyphus")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))

            Text("Bene venisti | Sign in to continue")
                .font(.system(.subheadline, design: .serif))
                .italic()
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Validation
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    // MARK: - Submit
    private func submitLogin() {
        guard !isLoading, isFormValid else { return }
        focusedField = nil
        errorMessage = nil
        errorIsUnverified = false
        verificationResentMessage = nil

        isLoading = true
        Haptics.light()

        Task { await performLogin() }
    }

    @MainActor
    private func performLogin() async {
        do {
            if !isValidEmail(email) {
                throw AuthError.invalidEmail
            }
            try await loginService(email: email, password: password)

            isLoading = false
            onAuthenticated()
        } catch let error as AuthError {
            withAnimation(.easeInOut(duration: 0.2)) {
                isLoading = false
                errorMessage = error.userFacingMessage
                errorIsUnverified = error.isUnverifiedAccount
                verificationResentMessage = nil
            }
            if error.isUnverifiedAccount {
                Haptics.error()
            }
        } catch {
            withAnimation(.easeInOut(duration: 0.2)) {
                isLoading = false
                errorMessage = error.localizedDescription
                errorIsUnverified = false
                verificationResentMessage = nil
            }
        }
    }

    // MARK: - Resend verification

    @MainActor
    private func resendVerificationEmail() async {
        guard !isResendingVerification, !email.isEmpty else { return }
        isResendingVerification = true

        do {
            try await requestAccountVerificationEmailService(email: email)
            withAnimation(.easeInOut(duration: 0.2)) {
                isResendingVerification = false
                verificationResentMessage = "Verification email sent. Check your inbox."
            }
            Haptics.success()
        } catch let error as AuthError {
            withAnimation(.easeInOut(duration: 0.2)) {
                isResendingVerification = false
                errorMessage = error.userFacingMessage
            }
            Haptics.error()
        } catch {
            withAnimation(.easeInOut(duration: 0.2)) {
                isResendingVerification = false
                errorMessage = error.localizedDescription
            }
            Haptics.error()
        }
    }
}

// MARK: - Forgot Password

struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var didSend = false
    @FocusState private var emailFocused: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                header

                VStack(spacing: 12) {
                    if didSend {
                        successCard
                    } else {
                        formCard
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Forgot password")
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("Forgot Password")
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("RECUPERATIO")
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundColor(.secondary)

            Text("Reset your password")
                .font(.system(.title, design: .serif, weight: .semibold))
                .multilineTextAlignment(.center)

            Text("We'll email you a secure link to set a new password.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
    }

    private var formCard: some View {
        VStack(spacing: 12) {
            field(title: "Email", icon: "envelope") {
                TextField("you@example.com", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .focused($emailFocused)
                    .submitLabel(.go)
                    .onSubmit { submit() }
            }

            if let errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(errorMessage)
                        .font(.caption)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            primaryButton(
                title: "Send reset link",
                isLoading: isLoading,
                isEnabled: !email.isEmpty
            ) {
                submit()
            }
            .padding(.top, 4)
        }
    }

    private var successCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)

            Text("Check your inbox")
                .font(.system(.title3, design: .serif, weight: .semibold))

            Text("If an account exists for \(email), we've sent a link to reset your password. Open it in your browser to set a new password, then come back here to log in.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                didSend = false
                errorMessage = nil
            } label: {
                Text("Use a different email")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.microInteraction)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private func submit() {
        guard !isLoading, !email.isEmpty else { return }
        emailFocused = false
        errorMessage = nil
        isLoading = true
        Haptics.light()

        Task { await performSend() }
    }

    @MainActor
    private func performSend() async {
        do {
            if !isValidEmail(email) {
                throw AuthError.invalidEmail
            }
            try await sendForgottenPasswordEmailService(email: email)

            isLoading = false
            withAnimation(.easeInOut(duration: 0.2)) {
                didSend = true
            }
        } catch let error as AuthError {
            withAnimation(.easeInOut(duration: 0.2)) {
                isLoading = false
                errorMessage = error.userFacingMessage
            }
        } catch {
            withAnimation(.easeInOut(duration: 0.2)) {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Shared Building Blocks

@ViewBuilder
private func primaryButton(
    title: String,
    isLoading: Bool,
    isEnabled: Bool,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        ZStack {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text(title)
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .contentShape(Rectangle())
    }
    .buttonStyle(.microInteraction)
    .background(Color.accentColor)
    .foregroundColor(.white)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .opacity(isEnabled ? 1 : 0.5)
    .disabled(isLoading || !isEnabled)
}

private func field<Content: View, Trailing: View>(
    title: String,
    icon: String,
    @ViewBuilder content: () -> Content,
    @ViewBuilder trailing: () -> Trailing
) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title)
            .font(.caption.weight(.semibold))
            .textCase(.uppercase)
            .foregroundColor(.secondary)
            .tracking(0.6)

        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .frame(width: 18)

            content()

            trailing()
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }
}

private func field<Content: View>(
    title: String,
    icon: String,
    @ViewBuilder content: () -> Content
) -> some View {
    field(title: title, icon: icon, content: content) { EmptyView() }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LoginView {
            AppLogger.ui.debug("Preview: login success")
        }
    }
}
