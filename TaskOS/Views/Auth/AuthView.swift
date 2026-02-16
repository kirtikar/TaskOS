import SwiftUI
import AuthenticationServices

// MARK: - AuthView
// Root authentication screen — shown when no user is signed in.
// Tabs between Sign In and Sign Up.

struct AuthView: View {
    @Environment(AuthenticationService.self) private var auth
    @State private var mode: AuthMode = .signIn
    @State private var animateIn = false

    enum AuthMode { case signIn, signUp }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [DS.Colors.accent.opacity(0.08), DS.Colors.groupedBG],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.Spacing.xl) {
                    Spacer().frame(height: DS.Spacing.xxxl)

                    // Logo + wordmark
                    logoSection

                    // Mode picker
                    modePicker

                    // Form
                    if mode == .signIn {
                        SignInForm()
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    } else {
                        SignUpForm()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    divider

                    // Social sign-in
                    socialButtons

                    Spacer().frame(height: DS.Spacing.xxxl)
                }
                .padding(.horizontal, DS.Spacing.xl)
            }
        }
        .onAppear {
            withAnimation(DS.Animation.standard.delay(0.1)) {
                animateIn = true
            }
        }
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: DS.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .fill(DS.Colors.accent)
                    .frame(width: 72, height: 72)
                    .shadow(color: DS.Colors.accent.opacity(0.35), radius: 16, x: 0, y: 6)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
            .scaleEffect(animateIn ? 1 : 0.5)
            .opacity(animateIn ? 1 : 0)

            Text("TaskOS")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Colors.label)

            Text("Get things done.")
                .font(DS.Typography.subheadline)
                .foregroundStyle(DS.Colors.secondaryLabel)
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach([AuthMode.signIn, AuthMode.signUp], id: \.self) { m in
                Button {
                    withAnimation(DS.Animation.quick) { mode = m }
                } label: {
                    Text(m == .signIn ? "Sign In" : "Sign Up")
                        .font(DS.Typography.headline)
                        .foregroundStyle(mode == m ? .white : DS.Colors.secondaryLabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.xs)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: DS.Radius.sm - 2)
                    .fill(DS.Colors.accent)
                    .frame(width: geo.size.width / 2)
                    .offset(x: mode == .signIn ? 0 : geo.size.width / 2)
                    .animation(DS.Animation.quick, value: mode)
            }
        )
        .background(DS.Colors.secondaryBG)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
    }

    // MARK: - Divider

    private var divider: some View {
        HStack {
            Rectangle().fill(DS.Colors.separator).frame(height: 0.5)
            Text("or continue with")
                .font(DS.Typography.caption1)
                .foregroundStyle(DS.Colors.tertiaryLabel)
                .fixedSize()
            Rectangle().fill(DS.Colors.separator).frame(height: 0.5)
        }
    }

    // MARK: - Social Buttons

    private var socialButtons: some View {
        VStack(spacing: DS.Spacing.sm) {
            // Sign in with Apple
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { _ in
                // Handled by AuthenticationService delegate
            }
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
            .onTapGesture {
                Task {
                    do {
                        try await auth.signInWithApple()
                    } catch AuthError.signInCancelled {
                        // user tapped cancel — no-op
                    } catch {
                        // handled in form
                    }
                }
            }
            // Use the real button above for correct Apple HIG appearance,
            // but drive the action from our service for consistency.

            // Google Sign-In
            SocialSignInButton(
                icon: "globe",
                label: "Continue with Google",
                foreground: DS.Colors.label,
                background: DS.Colors.secondaryBG,
                border: DS.Colors.separator
            ) {
                Task {
                    guard let vc = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.windows.first?.rootViewController })
                        .first else { return }
                    do {
                        try await auth.signInWithGoogle(presentingViewController: vc)
                    } catch {
                        // Show error
                    }
                }
            }
        }
    }
}

// MARK: - SignInForm

struct SignInForm: View {
    @Environment(AuthenticationService.self) private var auth
    @State private var email    = ""
    @State private var password = ""
    @State private var errorMsg: String? = nil
    @State private var showForgotPassword = false

    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            AuthTextField(
                icon: "envelope",
                placeholder: "Email address",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )

            AuthTextField(
                icon: "lock",
                placeholder: "Password",
                text: $password,
                isSecure: true,
                textContentType: .password
            )

            if let errorMsg {
                Text(errorMsg)
                    .font(DS.Typography.caption1)
                    .foregroundStyle(DS.Colors.destructive)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, -4)
            }

            Button("Forgot password?") {
                showForgotPassword = true
            }
            .font(DS.Typography.footnote)
            .foregroundStyle(DS.Colors.accent)
            .frame(maxWidth: .infinity, alignment: .trailing)

            PrimaryAuthButton(
                label: "Sign In",
                isLoading: auth.isLoading
            ) {
                Task { await signIn() }
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
                .presentationDetents([.medium])
                .presentationCornerRadius(DS.Radius.lg)
        }
    }

    private func signIn() async {
        errorMsg = nil
        do {
            try await auth.signInWithEmail(email: email.trimmingCharacters(in: .whitespaces), password: password)
        } catch let e as AuthError {
            errorMsg = e.errorDescription
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}

// MARK: - SignUpForm

struct SignUpForm: View {
    @Environment(AuthenticationService.self) private var auth
    @State private var name         = ""
    @State private var email        = ""
    @State private var password     = ""
    @State private var confirmPass  = ""
    @State private var errorMsg: String? = nil

    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            AuthTextField(
                icon: "person",
                placeholder: "Full name",
                text: $name,
                textContentType: .name
            )

            AuthTextField(
                icon: "envelope",
                placeholder: "Email address",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )

            AuthTextField(
                icon: "lock",
                placeholder: "Password (min 6 chars)",
                text: $password,
                isSecure: true,
                textContentType: .newPassword
            )

            AuthTextField(
                icon: "lock.fill",
                placeholder: "Confirm password",
                text: $confirmPass,
                isSecure: true,
                textContentType: .newPassword
            )

            if let errorMsg {
                Text(errorMsg)
                    .font(DS.Typography.caption1)
                    .foregroundStyle(DS.Colors.destructive)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryAuthButton(
                label: "Create Account",
                isLoading: auth.isLoading
            ) {
                Task { await signUp() }
            }

            Text("By signing up you agree to our Terms of Service and Privacy Policy.")
                .font(DS.Typography.caption2)
                .foregroundStyle(DS.Colors.tertiaryLabel)
                .multilineTextAlignment(.center)
        }
    }

    private func signUp() async {
        errorMsg = nil
        guard password == confirmPass else {
            errorMsg = "Passwords don't match."
            return
        }
        guard password.count >= 6 else {
            errorMsg = "Password must be at least 6 characters."
            return
        }
        do {
            try await auth.createAccount(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                displayName: name.trimmingCharacters(in: .whitespaces)
            )
        } catch let e as AuthError {
            errorMsg = e.errorDescription
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}

// MARK: - ForgotPasswordView

struct ForgotPasswordView: View {
    @Environment(AuthenticationService.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var sent  = false
    @State private var error: String? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.lg) {
                if sent {
                    VStack(spacing: DS.Spacing.md) {
                        Image(systemName: "envelope.badge.checkmark.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(DS.Colors.success)
                        Text("Check your inbox")
                            .font(DS.Typography.title2)
                        Text("A password reset link was sent to \(email)")
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colors.secondaryLabel)
                            .multilineTextAlignment(.center)
                        Button("Done") { dismiss() }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        Text("Enter your email and we'll send you a reset link.")
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colors.secondaryLabel)

                        AuthTextField(
                            icon: "envelope",
                            placeholder: "Email address",
                            text: $email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress
                        )

                        if let error {
                            Text(error)
                                .font(DS.Typography.caption1)
                                .foregroundStyle(DS.Colors.destructive)
                        }

                        PrimaryAuthButton(label: "Send Reset Link", isLoading: false) {
                            Task {
                                do {
                                    try await auth.sendPasswordReset(email: email)
                                    sent = true
                                } catch {
                                    self.error = error.localizedDescription
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Reusable Auth Components

struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil

    @State private var showPassword = false

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(DS.Colors.tertiaryLabel)
                .frame(width: 20)

            Group {
                if isSecure && !showPassword {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textContentType(textContentType)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                }
            }
            .font(DS.Typography.body)

            if isSecure {
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundStyle(DS.Colors.tertiaryLabel)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DS.Spacing.sm)
        .background(DS.Colors.secondaryBG)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.sm)
                .strokeBorder(DS.Colors.separator, lineWidth: 0.5)
        )
    }
}

struct PrimaryAuthButton: View {
    let label: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(label)
                        .font(DS.Typography.headline)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.sm)
            .background(DS.Colors.accent)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

struct SocialSignInButton: View {
    let icon: String
    let label: String
    let foreground: Color
    let background: Color
    let border: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(label)
                    .font(DS.Typography.headline)
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .strokeBorder(border, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AuthView()
        .environment(AuthenticationService())
        .environment(ThemeManager.shared)
}
