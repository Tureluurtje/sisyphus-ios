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
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false

    @FocusState private var focusedField: Field?

    @Environment(\.dismiss) private var dismiss

    enum Field {
        case name, email, password, confirmPassword
    }

    // MARK: - Dependencies
    var onAuthenticated: () -> Void

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
                                    Button("1") { selectedGrade = 1 }
                                    Button("2") { selectedGrade = 2 }
                                    Button("3") { selectedGrade = 3 }
                                    Button("4") { selectedGrade = 4 }
                                    Button("5") { selectedGrade = 5 }
                                    Button("6") { selectedGrade = 6 }
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

                    // MARK: Password mismatch message
                    if didSubmit && password != confirmPassword {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Passwords do not match")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // MARK: Backend error
                    if let errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(errorMessage)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // MARK: Button
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

                // Register is always reached by pushing from LoginView, so
                // returning to it should pop back rather than push a second
                // instance (which — combined with the hidden back button —
                // would let Login/Register push onto each other endlessly).
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
        .background(Color(UIColor.systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .navigationBarBackButtonHidden(true)
        .trackScreen("Register")
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

            isLoading = false
            onAuthenticated()

        } catch let error as AuthError {
            isLoading = false
            errorMessage = error.userFacingMessage
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
