import SwiftUI

struct AuthView: View {
    @AppStorage("isLoggedIn")        private var isLoggedIn   = false
    @AppStorage("hasSeenOnboarding") private var hasSeen      = false
    @State private var showLogin     = true
    @State private var showDemo      = false
    @State private var animateIn     = false
    @State private var showGuestAlert = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0F0C29"), Color(hex: "1a1040"), Color(hex: "0F0C29")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()

            Circle().fill(Color(hex: "6366F1").opacity(0.15))
                .frame(width: 350).blur(radius: 80).offset(x: -80, y: -200)
            Circle().fill(Color(hex: "059669").opacity(0.1))
                .frame(width: 280).blur(radius: 70).offset(x: 120, y: 250)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 10) {
                    Text("🗺️").font(.system(size: 60))
                        .scaleEffect(animateIn ? 1 : 0.5).opacity(animateIn ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateIn)

                    Text("MoodMap")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.15), value: animateIn)

                    Text("Discover places that match how you feel")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.25), value: animateIn)
                }
                .padding(.bottom, 32)

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Button { withAnimation { showLogin = true } } label: {
                            Text("Sign In")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(showLogin ? .white : .white.opacity(0.4))
                                .frame(maxWidth: .infinity).padding(.vertical, 11)
                                .background(showLogin ? Color(hex: "6366F1") : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        Button { withAnimation { showLogin = false } } label: {
                            Text("Create Account")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(!showLogin ? .white : .white.opacity(0.4))
                                .frame(maxWidth: .infinity).padding(.vertical, 11)
                                .background(!showLogin ? Color(hex: "6366F1") : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                    .padding(.horizontal, 22)
                    .padding(.top, 22)

                    if showLogin {
                        LoginForm(onLogin: { isLoggedIn = true },
                                  onSwitch: { withAnimation { showLogin = false } })
                    } else {
                        SignupForm(onSignup: { isLoggedIn = true })
                    }
                }
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.1), lineWidth: 1))
                .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 12) {
                    Button { showGuestAlert = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "person.fill.questionmark")
                                .font(.system(size: 15))
                                .foregroundStyle(Color(hex: "818CF8"))
                            Text("Continue without signing in")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    .padding(.horizontal, 20)

                    Button { showDemo = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.circle.fill").font(.system(size: 13))
                            Text("See how it works").font(.system(size: 13, design: .rounded))
                        }
                        .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .padding(.bottom, 34)
            }
        }
        .onAppear { withAnimation { animateIn = true } }
        .sheet(isPresented: $showDemo) { AppDemoView() }
        .sheet(isPresented: $showGuestAlert) {
            GuestSheet(onContinue: {
                hasSeen    = true
                isLoggedIn = true
            })
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(hex: "1a1040"))
        }
    }
}

struct LocalAuth {
    static func register(email: String, password: String) -> Bool {
        var users = loadUsers()
        guard !users.keys.contains(email.lowercased()) else { return false }
        users[email.lowercased()] = password
        saveUsers(users)
        UserDefaults.standard.set(email.lowercased(), forKey: "loggedInEmail")
        return true
    }

    static func login(email: String, password: String) -> Bool {
        let users = loadUsers()
        guard let stored = users[email.lowercased()] else { return false }
        let success = stored == password
        if success { UserDefaults.standard.set(email.lowercased(), forKey: "loggedInEmail") }
        return success
    }

    static func isRegistered(email: String) -> Bool {
        loadUsers().keys.contains(email.lowercased())
    }

    private static func loadUsers() -> [String: String] {
        guard let data = UserDefaults.standard.data(forKey: "moodmap_users"),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return decoded
    }

    private static func saveUsers(_ users: [String: String]) {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: "moodmap_users")
        }
    }
}

struct LoginForm: View {
    let onLogin:  () -> Void
    let onSwitch: () -> Void

    @State private var email    = ""
    @State private var password = ""
    @State private var errorMsg = ""

    var body: some View {
        VStack(spacing: 14) {
            AuthField(icon: "envelope.fill",
                      placeholder: "Enter your email",
                      text: $email, secure: false)

            AuthField(icon: "lock.fill",
                      placeholder: "Enter your password",
                      text: $password, secure: true)

            if !errorMsg.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 13))
                    Text(errorMsg).font(.system(size: 12, design: .rounded))
                }
                .foregroundStyle(Color(hex: "F87171"))
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                errorMsg = ""
                guard !email.isEmpty else { errorMsg = "Please enter your email."; return }
                guard !password.isEmpty else { errorMsg = "Please enter your password."; return }
                guard isValidEmail(email) else { errorMsg = "Please enter a valid email address."; return }

                if LocalAuth.login(email: email, password: password) {
                    onLogin()
                } else if !LocalAuth.isRegistered(email: email) {
                    errorMsg = "No account found. Please create an account first."
                } else {
                    errorMsg = "Incorrect password. Please try again."
                }
            } label: {
                Text("Sign In")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(LinearGradient(colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                                               startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 13))
            }

            Button { onSwitch() } label: {
                Text("Don't have an account? Create one")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Color(hex: "818CF8"))
            }
        }
        .padding(22)
    }

    func isValidEmail(_ s: String) -> Bool {
        s.contains("@") && s.contains(".")
    }
}

struct SignupForm: View {
    let onSignup: () -> Void

    @State private var name     = ""
    @State private var email    = ""
    @State private var password = ""
    @State private var confirm  = ""
    @State private var errorMsg = ""
    @State private var success  = false

    var body: some View {
        VStack(spacing: 12) {
            AuthField(icon: "person.fill",
                      placeholder: "Enter your full name",
                      text: $name, secure: false)

            AuthField(icon: "envelope.fill",
                      placeholder: "Enter your email",
                      text: $email, secure: false)

            AuthField(icon: "lock.fill",
                      placeholder: "Create a password (6+ chars)",
                      text: $password, secure: true)

            AuthField(icon: "lock.fill",
                      placeholder: "Confirm your password",
                      text: $confirm, secure: true)

            if !errorMsg.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 13))
                    Text(errorMsg).font(.system(size: 12, design: .rounded))
                }
                .foregroundStyle(Color(hex: "F87171"))
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if success {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                    Text("Account created! Signing you in…")
                        .font(.system(size: 12, design: .rounded))
                }
                .foregroundStyle(Color(hex: "34D399"))
            }

            Button {
                errorMsg = ""
                guard !name.isEmpty     else { errorMsg = "Please enter your name."; return }
                guard !email.isEmpty    else { errorMsg = "Please enter your email."; return }
                guard isValidEmail(email) else { errorMsg = "Please enter a valid email address."; return }
                guard !password.isEmpty else { errorMsg = "Please create a password."; return }
                guard password.count >= 6 else { errorMsg = "Password must be at least 6 characters."; return }
                guard password == confirm else { errorMsg = "Passwords do not match."; return }

                if LocalAuth.isRegistered(email: email) {
                    errorMsg = "An account with this email already exists. Please sign in."
                    return
                }

                UserDefaults.standard.set(name, forKey: "userName")
                if LocalAuth.register(email: email, password: password) {
                    success = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { onSignup() }
                }
            } label: {
                Text("Create Account")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(LinearGradient(colors: [Color(hex: "059669"), Color(hex: "047857")],
                                               startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 13))
            }
        }
        .padding(22)
    }

    func isValidEmail(_ s: String) -> Bool {
        s.contains("@") && s.contains(".")
    }
}

struct AuthField: View {
    let icon:        String
    let placeholder: String
    @Binding var text: String
    let secure:      Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "818CF8"))
                .frame(width: 18)

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.white.opacity(0.3))
                }
                if secure {
                    SecureField("", text: $text)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.white)
                        .tint(Color(hex: "818CF8"))
                } else {
                    TextField("", text: $text)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.white)
                        .tint(Color(hex: "818CF8"))
                        .keyboardType(placeholder.lowercased().contains("email") ? .emailAddress : .default)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.1), lineWidth: 1))
    }
}

struct GuestSheet: View {
    let onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 24)

            ZStack {
                Circle()
                    .fill(Color(hex: "6366F1").opacity(0.15))
                    .frame(width: 72, height: 72)
                Circle()
                    .strokeBorder(Color(hex: "6366F1").opacity(0.3), lineWidth: 1.5)
                    .frame(width: 72, height: 72)
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 30))
                    .foregroundStyle(Color(hex: "818CF8"))
            }
            .padding(.bottom, 16)

            Text("Continue as Guest")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 10)

            Text("You can explore all features without an account. Your saved places, history, and reviews will be stored locally on this device.")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 28)
                .padding(.bottom, 28)

            VStack(spacing: 10) {
                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onContinue()
                    }
                } label: {
                    Text("Yes, continue as guest")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(LinearGradient(
                            colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                            startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button { dismiss() } label: {
                    Text("Back to sign in")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}
