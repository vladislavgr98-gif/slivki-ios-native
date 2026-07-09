import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @State private var flowState = CallFirstAuthFlowState()
    @State private var phoneInput = ""
    @State private var emailCode = ""
    @State private var registerName = ""
    @State private var registerEmail = ""
    @State private var fieldErrors: [String: String] = [:]
    @State private var isLoading = false
    @State private var pollTask: Task<Void, Never>?

    private let authService = CallFirstAuthService()

    var body: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
            switch flowState.step {
            case .phone:
                phoneStep
            case .call:
                callStep
            case .email:
                emailStep
            case .register:
                registerStep
            }

            if let commonError = fieldErrors["common"] {
                Text(commonError)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.red)
            }
        }
        .padding(SlivkiSpacing.md)
        .background(SlivkiColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(SlivkiColor.border.opacity(0.75), lineWidth: 1)
        )
        .onAppear {
            restartPollingIfNeeded()
        }
        .onDisappear {
            pollTask?.cancel()
        }
        .onChange(of: flowState.step) { _ in
            restartPollingIfNeeded()
        }
    }

    private var phoneStep: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
            authPromoCard

            Text("Войти или зарегистрироваться")
                .font(.title2.weight(.black))
                .foregroundStyle(SlivkiColor.textPrimary)

            Text("Введите номер телефона. Мы подтвердим его бесплатным звонком.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SlivkiColor.textSecondary)

            VStack(alignment: .leading, spacing: SlivkiSpacing.xs) {
                Text("Телефон")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SlivkiColor.textSecondary)

                HStack(spacing: SlivkiSpacing.sm) {
                    Image(systemName: "phone.fill")
                        .foregroundStyle(SlivkiColor.brandDark)
                    TextField("+7 999 123-45-67", text: $phoneInput)
                        .font(.subheadline.weight(.medium))
                        .slivkiKeyboardType(.phonePad)
                        .onChange(of: phoneInput) { _ in
                            fieldErrors.removeValue(forKey: "phone")
                        }
                }
                .padding(.horizontal, SlivkiSpacing.sm)
                .frame(height: 50)
                .background(SlivkiColor.groupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if let error = fieldErrors["phone"] {
                    Text(error)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.red)
                }
            }

            Button {
                Task { await startPhoneFlow() }
            } label: {
                loadingLabel("Продолжить", loading: "Подтверждаем...")
            }
            .buttonStyle(.borderedProminent)
            .tint(SlivkiColor.accent)
            .disabled(!CallFirstAuthService.isValidPhone(phoneInput) || isLoading)

            noteCard(
                title: "Один номер — для входа и регистрации.",
                body: "Подтверждаем номер бесплатным звонком, без SMS."
            )

            VStack(alignment: .leading, spacing: SlivkiSpacing.xs) {
                Text("Впервые на Сливки?")
                    .font(.subheadline.weight(.bold))
                Text("Отдельная регистрация больше не нужна: начните с номера телефона.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SlivkiColor.textSecondary)
            }
            .padding(SlivkiSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SlivkiColor.groupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var callStep: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
            Text("Подтвердите звонком")
                .font(.title2.weight(.black))

            Text("Позвоните на бесплатный номер с телефона \(flowState.maskedPhone.isEmpty ? phoneInput : flowState.maskedPhone).")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SlivkiColor.textSecondary)

            VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
                Text("Бесплатный номер для звонка")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SlivkiColor.textSecondary)

                if let url = callURL {
                    Link(flowState.callPhonePretty.isEmpty ? "Позвонить" : flowState.callPhonePretty, destination: url)
                        .font(.title3.weight(.black))
                        .foregroundStyle(SlivkiColor.brandDark)
                } else {
                    Text(flowState.callPhonePretty.isEmpty ? "8 800 XXX-XX-XX" : flowState.callPhonePretty)
                        .font(.title3.weight(.black))
                }

                Text("Звонок бесплатный. После звонка вернитесь в приложение — мы проверим номер автоматически.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SlivkiColor.textSecondary)
            }
            .padding(SlivkiSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SlivkiColor.groupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(alignment: .top, spacing: SlivkiSpacing.sm) {
                ProgressView()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Проверяем звонок...")
                        .font(.subheadline.weight(.bold))
                    Text("Обычно это занимает несколько секунд после возврата в приложение.")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SlivkiColor.textSecondary)
                }
            }
            .padding(SlivkiSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SlivkiColor.brandBright.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button("Я уже позвонил") {
                Task { await refreshStatus() }
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(SlivkiColor.brandDark)

            Button("Изменить номер") {
                Task { await resetFlow() }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(SlivkiColor.textSecondary)

            if flowState.hasEmailFallback {
                Divider()
                Text("Не получается войти?")
                    .font(.subheadline.weight(.bold))
                Button("Получить код на почту") {
                    flowState.step = .email
                }
                .buttonStyle(.bordered)
                .tint(SlivkiColor.brandDark)
            }
        }
    }

    private var emailStep: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
            Text("Код на почту")
                .font(.title2.weight(.black))

            Text("Отправим код на почту, привязанную к аккаунту.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SlivkiColor.textSecondary)

            VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
                Text("Почта аккаунта")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SlivkiColor.textSecondary)
                Text(flowState.maskedEmail.isEmpty ? "Почта не найдена" : flowState.maskedEmail)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(SlivkiSpacing.sm)
                    .background(SlivkiColor.groupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    Task { await sendEmailCode() }
                } label: {
                    loadingLabel("Отправить код", loading: "Отправляем...")
                }
                .buttonStyle(.bordered)
                .tint(SlivkiColor.brandDark)
                .disabled(!flowState.hasEmailFallback || isLoading)

                if flowState.emailCodeSent {
                    Text("Введите код из письма")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SlivkiColor.textSecondary)

                    TextField("0000", text: $emailCode)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                        .slivkiKeyboardType(.numberPad)
                        .frame(height: 52)
                        .background(SlivkiColor.groupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: emailCode) { newValue in
                            emailCode = String(newValue.filter(\.isNumber).prefix(4))
                            fieldErrors.removeValue(forKey: "code")
                        }

                    if let error = fieldErrors["code"] ?? fieldErrors["email"] {
                        Text(error)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task { await verifyEmailCode() }
                    } label: {
                        loadingLabel("Войти", loading: "Проверяем...")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SlivkiColor.accent)
                    .disabled(emailCode.count != 4 || isLoading)
                }
            }

            Button("Вернуться к звонку") {
                flowState.step = .call
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(SlivkiColor.textSecondary)
        }
    }

    private var registerStep: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
            Text("Завершите регистрацию")
                .font(.title2.weight(.black))

            Text("Осталось указать имя и почту для нового аккаунта.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SlivkiColor.textSecondary)

            HStack(spacing: SlivkiSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(SlivkiColor.brandDark)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Телефон подтверждён")
                        .font(.subheadline.weight(.bold))
                    Text(flowState.maskedPhone)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SlivkiColor.textSecondary)
                }
                Spacer()
                Button("Изменить") {
                    Task { await resetFlow() }
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(SlivkiColor.brandDark)
            }
            .padding(SlivkiSpacing.sm)
            .background(SlivkiColor.brandBright.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            authField("Имя", text: $registerName, errorKey: "nickname", systemImage: "person")
            authField("Почта", text: $registerEmail, errorKey: "email", systemImage: "envelope")
                .slivkiKeyboardType(.emailAddress)

            Button {
                Task { await submitRegistration() }
            } label: {
                loadingLabel("Создать аккаунт", loading: "Создаём профиль...")
            }
            .buttonStyle(.borderedProminent)
            .tint(SlivkiColor.accent)
            .disabled(registerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || registerEmail.isEmpty || isLoading)

            Text("Регистрируясь, вы подтверждаете согласие с пользовательским соглашением и политикой конфиденциальности.")
                .font(.caption.weight(.medium))
                .foregroundStyle(SlivkiColor.textSecondary)
        }
    }

    private var authPromoCard: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
            Text("Сливки shop")
                .font(.caption.weight(.black))
                .foregroundStyle(SlivkiColor.brandDark)
                .padding(.horizontal, SlivkiSpacing.sm)
                .padding(.vertical, 4)
                .background(SlivkiColor.brandBright.opacity(0.2))
                .clipShape(Capsule())

            Text("Один номер для входа и регистрации")
                .font(.headline.weight(.black))
                .foregroundStyle(SlivkiColor.textPrimary)

            Text("Подтверждаем номер бесплатным звонком, без SMS и лишних шагов.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SlivkiColor.textSecondary)
        }
        .padding(SlivkiSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [SlivkiColor.brandBright.opacity(0.14), SlivkiColor.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SlivkiColor.brandBright.opacity(0.25), lineWidth: 1)
        )
    }

    private var callURL: URL? {
        guard !flowState.callPhone.isEmpty else { return nil }
        return URL(string: "tel:\(flowState.callPhone)")
    }

    private func authField(_ title: String, text: Binding<String>, errorKey: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.xs) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(SlivkiColor.textSecondary)
            HStack(spacing: SlivkiSpacing.sm) {
                Image(systemName: systemImage)
                    .foregroundStyle(SlivkiColor.brandDark)
                TextField(title, text: text)
                    .font(.subheadline.weight(.medium))
                    .onChange(of: text.wrappedValue) { _ in
                        fieldErrors.removeValue(forKey: errorKey)
                    }
            }
            .padding(.horizontal, SlivkiSpacing.sm)
            .frame(height: 50)
            .background(SlivkiColor.groupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if let error = fieldErrors[errorKey] {
                Text(error)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.red)
            }
        }
    }

    private func noteCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.bold))
            Text(body)
                .font(.caption.weight(.medium))
                .foregroundStyle(SlivkiColor.textSecondary)
        }
        .padding(SlivkiSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SlivkiColor.brandBright.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func loadingLabel(_ title: String, loading: String) -> some View {
        HStack {
            if isLoading {
                ProgressView()
                    .tint(.white)
            }
            Text(isLoading ? loading : title)
        }
        .font(.headline.weight(.bold))
        .frame(maxWidth: .infinity)
        .frame(height: 50)
    }

    private func startPhoneFlow() async {
        isLoading = true
        fieldErrors = [:]
        defer { isLoading = false }

        do {
            flowState = try await authService.start(phone: phoneInput)
        } catch let error as CallFirstAuthError {
            applyErrors(error)
        } catch {
            fieldErrors = ["phone": error.localizedDescription]
        }
    }

    private func refreshStatus() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let next = try await authService.status(current: flowState)
            handleFlowUpdate(next)
        } catch let error as CallFirstAuthError {
            applyErrors(error)
        } catch {
            fieldErrors = ["common": error.localizedDescription]
        }
    }

    private func sendEmailCode() async {
        isLoading = true
        fieldErrors = [:]
        defer { isLoading = false }

        do {
            let next = try await authService.sendEmailCode(current: flowState)
            handleFlowUpdate(next)
        } catch let error as CallFirstAuthError {
            applyErrors(error)
        } catch {
            fieldErrors = ["email": error.localizedDescription]
        }
    }

    private func verifyEmailCode() async {
        isLoading = true
        fieldErrors = [:]
        defer { isLoading = false }

        do {
            let next = try await authService.verifyEmailCode(emailCode, current: flowState)
            handleFlowUpdate(next)
        } catch let error as CallFirstAuthError {
            applyErrors(error)
        } catch {
            fieldErrors = ["code": error.localizedDescription]
        }
    }

    private func submitRegistration() async {
        isLoading = true
        fieldErrors = [:]
        defer { isLoading = false }

        do {
            let next = try await authService.register(
                name: registerName,
                email: registerEmail,
                current: flowState
            )
            handleFlowUpdate(next)
        } catch let error as CallFirstAuthError {
            applyErrors(error)
        } catch {
            fieldErrors = ["common": error.localizedDescription]
        }
    }

    private func resetFlow() async {
        pollTask?.cancel()
        isLoading = true
        defer { isLoading = false }

        do {
            flowState = try await authService.reset()
            phoneInput = ""
            emailCode = ""
            registerName = ""
            registerEmail = ""
            fieldErrors = [:]
        } catch {
            flowState = CallFirstAuthFlowState()
            phoneInput = ""
        }
    }

    private func handleFlowUpdate(_ next: CallFirstAuthFlowState) {
        if next.verified && next.step == .phone {
            completeSession(from: next, name: registerName.nilIfEmpty, email: registerEmail.nilIfEmpty)
            return
        }

        flowState = next
    }

    private func completeSession(from state: CallFirstAuthFlowState, name: String?, email: String?) {
        pollTask?.cancel()
        let user = User(
            id: state.phone.isEmpty ? UUID().uuidString : state.phone,
            name: name,
            phone: state.maskedPhone.nilIfEmpty ?? CallFirstAuthService.formatPhone(state.phone),
            email: email
        )
        try? sessionStore.applyWebSession(user: user)
        flowState = CallFirstAuthFlowState()
        phoneInput = ""
        emailCode = ""
        registerName = ""
        registerEmail = ""
        fieldErrors = [:]
    }

    private func applyErrors(_ error: CallFirstAuthError) {
        switch error {
        case .requestFailed(let message):
            fieldErrors = ["common": message]
        case .serverErrors(let errors):
            fieldErrors = errors
        }
    }

    private func restartPollingIfNeeded() {
        pollTask?.cancel()
        guard flowState.step == .call else { return }

        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                guard !Task.isCancelled, flowState.step == .call else { return }
                await refreshStatus()
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
