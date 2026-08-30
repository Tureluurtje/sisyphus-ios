//
//  LoginView.swift
//  sisyphus
//
//  Created by Arthur Kwak on 15/06/2026.
//

import SwiftUI
import OSLog

struct LoginView: View {

    // MARK: - Inputs
    @State private var email: String = ""
    @State private var password: String = ""

    // MARK: - State
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var isPasswordVisible: Bool = false
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

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
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
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
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { Task { await login() } }
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
                        .buttonStyle(.plain)
                        .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
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

                    Button {
                        Task { await login() }
                    } label: {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Login")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .opacity(isFormValid ? 1 : 0.5)
                    .disabled(isLoading || !isFormValid)
                    .padding(.top, 4)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
                /*
                dividerWithLabel

                Button {
                    // Apple sign-in action
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                        Text("Continue with Apple")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.plain)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                 */
                NavigationLink(destination: RegisterView(onAuthenticated: onAuthenticated)) {
                    HStack(spacing: 4) {
                        Text("No account yet?")
                            .foregroundColor(.secondary)
                        Text("Register")
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
        .scrollDismissesKeyboard(.interactively)
        .navigationBarBackButtonHidden(true)
        .trackScreen("Login")
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

    // MARK: - Field
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

    // MARK: - Field (no trailing accessory)
    private func field<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        field(title: title, icon: icon, content: content) {
            EmptyView()
        }
    }

    // MARK: - Divider
    private var dividerWithLabel: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 1)
            Text("or")
                .font(.caption)
                .foregroundColor(.secondary)
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 1)
        }
    }

    // MARK: - Validation
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty
    }

    // MARK: - Login Logic
    @MainActor
    private func login() async {
        guard isFormValid else { return }
        isLoading = true
        errorMessage = nil

        do {
            if !isValidEmail(email) {
                throw AuthError.invalidEmail
            }
            try await loginService(
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

#Preview {
    NavigationStack {
        LoginView(
            onAuthenticated: {
                // preview-only behavior
                AppLogger.ui.debug("Preview: login success")
            }
        )
    }
}
