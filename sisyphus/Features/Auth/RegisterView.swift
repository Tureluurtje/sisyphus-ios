//
//  RegisterView.swift
//  sisyphus
//

import SwiftUI

struct RegisterView: View {

    // MARK: - Inputs
    @State private var username: String = ""
    @State private var selectedGrade = 1
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    // MARK: - State
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var didSubmit: Bool = false
    @State private var didRegister: Bool = false
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false

    @FocusState private var focusedField: Field?

    @Environment(\.dismiss) private var dismiss

    enum Field {
        case name, email, password, confirmPassword
    }

    // MARK: - Validation (ONLY visible after submit)
    private var isEmailInvalid: Bool {
        didSubmit && !isValidEmail(email)
    }

    private var isPasswordInvalid: Bool {
        didSubmit && (!password.isEmpty && password.count < 6)
    }

    private var isConfirmPasswordInvalid: Bool {
        didSubmit && password != confirmPassword
    }

    private var isFormValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        isValidEmail(email) &&
        password.count >= 6
    }

    var body: some View {
        Group {
            if didRegister {
                RegisterVerifyEmailView(
                    email: email,
                    onBack: { dismiss() }
                )
            } else {
                registrationForm
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .trackScreen("Register")
    }

    // MARK: - Registration form

    private var registrationForm: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {

                header

                VStack(spacing: 12) {

                    // MARK: Username + Grade
                    HStack {
                        field(
                            title: "Username",
                            icon: "person",
                            isError: false,
                            content: {
                                TextField("Your username", text: $username)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .name)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .email }
                            }
                        )

                        field(
                            title: "Grade",
                            icon: nil,
                            isError: false,
                            content: {
                                Menu {
                                    ForEach(1...6, id: \.self) { grade in
                                        Button("\(grade)") { selectedGrade = grade }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "graduationcap")
                                            .foregroundColor(.secondary)
                                        Text("\(selectedGrade)")
                                    }
                                }
                            }
                        )
                    }

                    // MARK: Email
                    field(
                        title: "Email",
                        icon: "envelope",
                        isError: isEmailInvalid,
                        content: {
                            TextField("you@example.com", text: $email)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                        }
                    )

                    // MARK: Password
                    field(
                        title: "Password",
                        icon: "lock",
                        isError: isPasswordInvalid,
                        content: {
                            Group {
                                if isPasswordVisible {
                                    TextField("••••••••", text: $password)
                                } else {
                                    SecureField("••••••••", text: $password)
                                }
                            }
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .confirmPassword }
                        },
                        trailing: {
                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                        }
                    )

                    // MARK: Confirm Password
                    field(
                        title: "Confirm password",
                        icon: "lock.shield",
                        isError: isConfirmPasswordInvalid,
                        content: {
                            Group {
                                if isConfirmPasswordVisible {
                                    TextField("••••••••", text: $confirmPassword)
                                } else {
                                    SecureField("••••••••", text: $confirmPassword)
                                }
                            }
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .confirmPassword)
                            .submitLabel(.go)
                            .onSubmit { Task { await register() } }
                        },
                        trailing: {
                            Button {
                                isConfirmPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isConfirmPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(isConfirmPasswordVisible ? "Hide password" : "Show password")
                        }
                    )

                    if didSubmit && password != confirmPassword {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Passwords do not match")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(errorMessage)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await register() }
                    } label: {
                        ZStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Register")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.plain)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .opacity(isFormValid ? 1 : 0.5)
                    .disabled(isLoading)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )

                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.secondary)
                        Text("Login")
                            .foregroundColor(.accentColor)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 8) {
            Text("Create account")
                .font(.system(.largeTitle, weight: .semibold))

            Text("Incipe iter tuum | Start your journey")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Field (with trailing accessory)
    private func field<Content: View, Trailing: View>(
        title: String,
        icon: String?,
        isError: Bool,
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundColor(.secondary)
                        .frame(width: 18)
                }

                content()

                trailing()
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isError ? Color.red.opacity(0.05) : Color.clear)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isError ? Color.red : Color.secondary.opacity(0.15),
                        lineWidth: isError ? 2 : 1
                    )
            )
        }
    }

    // MARK: - Field (no trailing accessory)
    private func field<Content: View>(
        title: String,
        icon: String?,
        isError: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        field(title: title, icon: icon, isError: isError, content: content) {
            EmptyView()
        }
    }

    // MARK: - Register Logic
    @MainActor
    private func register() async {
        didSubmit = true

        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await registerService(
                username: username,
                grade: selectedGrade,
                email: email,
                password: password
            )

            // The server issues tokens on register, but the account is unverified.
            // Wipe them so the app can't silently auto-login via refresh — the user
            // must verify their email in the browser and then log in normally.
            clearLocalSession()

            isLoading = false
            Haptics.success()

            withAnimation(.easeInOut(duration: 0.25)) {
                didRegister = true
            }
        } catch let error as AuthError {
            isLoading = false
            errorMessage = error.userFacingMessage
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Post-registration verification screen

private struct RegisterVerifyEmailView: View {
    let email: String
    var onBack: () -> Void

    @State private var isResending = false
    @State private var resendMessage: String?
    @State private var resendError: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("VERIFICATIO")
                        .font(.caption.weight(.semibold))
                        .tracking(1.2)
                        .foregroundColor(.secondary)

                    Text("Check your inbox")
                        .font(.system(.title, design: .serif, weight: .semibold))
                        .multilineTextAlignment(.center)

                    Text("We sent a verification link to \(email). Open it in your browser to confirm your account, then come back here to log in.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }

                VStack(spacing: 12) {
                    Image(systemName: "envelope.badge.shield.half.filled")
                        .font(.system(size: 52))
                        .foregroundColor(.accentColor)
                        .padding(.vertical, 8)

                    Button {
                        Task { await resend() }
                    } label: {
                        ZStack {
                            if isResending {
                                ProgressView().tint(.white)
                            } else {
                                Text("Resend email")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.plain)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(isResending)

                    if let resendMessage {
                        Text(resendMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    if let resendError {
                        Text(resendError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )

                Button {
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Text("Already verified?")
                            .foregroundColor(.secondary)
                        Text("Log in")
                            .foregroundColor(.accentColor)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    private func resend() async {
        isResending = true
        resendMessage = nil
        resendError = nil

        do {
            try await requestAccountVerificationEmailService(email: email)
            await MainActor.run {
                isResending = false
                resendMessage = "Verification email sent. Check your inbox."
            }
        } catch {
            await MainActor.run {
                isResending = false
                resendError = error.localizedDescription
            }
        }
    }
}
