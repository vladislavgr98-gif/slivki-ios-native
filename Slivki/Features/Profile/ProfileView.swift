import SwiftUI

public struct ProfileView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var router: AppRouter

    public init() {}

    public var body: some View {
        List {
            Section {
                if sessionStore.isAuthenticated {
                    Text(sessionStore.currentUser?.displayName ?? "Покупатель")
                    Button("Выйти", role: .destructive) {
                        sessionStore.logout()
                    }
                } else {
                    LoginView()
                }
            }

            Section {
                Button {
                    router.navigate(to: .legal(path: "/pages/rules.html"), in: .profile)
                } label: {
                    Label("Правила", systemImage: "doc.text")
                }

                Button {
                    router.navigate(to: .legal(path: "/pages/agreement.html"), in: .profile)
                } label: {
                    Label("Соглашение", systemImage: "doc.text")
                }
            }
        }
        .navigationTitle("Профиль")
    }
}

private struct LoginView: View {
    @State private var login = ""
    @State private var password = ""
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
            TextField("Телефон или email", text: $login)
                .slivkiKeyboardType(.emailAddress)

            SecureField("Пароль", text: $password)

            Button("Войти") {
                message = "Вход будет подключен к /api/mobile/v1/auth/login."
            }
            .buttonStyle(.borderedProminent)
            .disabled(login.isEmpty || password.isEmpty)

            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(SlivkiColor.textSecondary)
            }
        }
    }
}
