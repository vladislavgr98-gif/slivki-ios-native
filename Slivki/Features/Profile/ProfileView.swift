import SwiftUI

public struct ProfileView: View {
    @Environment(\.apiClient) private var apiClient
    @EnvironmentObject private var bootstrapStore: BootstrapStore
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var addressStore: DeliveryAddressStore
    @EnvironmentObject private var router: AppRouter
    @State private var recentOrder: Order?
    @State private var showsAddresses = false
    @State private var showsPaymentMethods = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
                if sessionStore.isAuthenticated, let user = sessionStore.currentUser {
                    ProfileCabinetCard(
                        user: user,
                        recentOrder: recentOrder,
                        quickActions: quickActions,
                        onLogout: {
                            sessionStore.logout()
                            recentOrder = nil
                        },
                        onRecentOrderTap: { order in
                            router.navigate(to: .order(id: order.id), in: .profile)
                        }
                    )
                } else {
                    LoginView()
                }

                accountMenu
                StorefrontFooter(
                    site: bootstrapStore.site,
                    onFavorites: { router.navigate(to: .favorites, in: .profile) },
                    onAbout: { router.navigate(to: .legal(path: "/pages/rules.html"), in: .profile) },
                    onFeedback: { router.selectedTab = .profile },
                    onRules: { router.navigate(to: .legal(path: "/pages/rules.html"), in: .profile) },
                    onAgreement: { router.navigate(to: .legal(path: "/pages/agreement.html"), in: .profile) }
                )
            }
            .padding(SlivkiSpacing.md)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: SlivkiSpacing.sm) {
                StorefrontHeader(
                    variant: .standard,
                    siteName: bootstrapStore.site?.name ?? "Сливки"
                )
                profileContactStrip
            }
            .padding(.horizontal, SlivkiSpacing.md)
            .padding(.top, SlivkiSpacing.md)
            .padding(.bottom, SlivkiSpacing.sm)
            .background(SlivkiColor.surface)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(SlivkiColor.border.opacity(0.8))
                    .frame(height: 1)
            }
        }
        .background(SlivkiColor.groupedBackground)
        .navigationTitle("Профиль")
        .slivkiHideNavigationBar()
        .task(id: sessionStore.isAuthenticated) {
            if sessionStore.isAuthenticated {
                await loadRecentOrder()
            } else {
                recentOrder = nil
            }
        }
        .sheet(isPresented: $showsAddresses) {
            DeliveryAddressesView()
        }
        .sheet(isPresented: $showsPaymentMethods) {
            PaymentMethodsView()
        }
    }

    private var addressSubtitle: String {
        if let address = addressStore.defaultAddress {
            return "\(address.city), \(address.line1)"
        }
        return sessionStore.currentUser?.city?.title ?? "Можно выбрать при оформлении"
    }

    private var quickActions: [ProfileQuickAction] {
        [
            ProfileQuickAction(title: "Заказы", systemImage: "bag") {
                router.navigate(to: .orders, in: .profile)
            },
            ProfileQuickAction(title: "Избранное", systemImage: "heart") {
                router.navigate(to: .favorites, in: .profile)
            },
            ProfileQuickAction(title: "Корзина", systemImage: "cart") {
                router.selectedTab = .cart
            }
        ]
    }

    private var profileContactStrip: some View {
        HStack(spacing: SlivkiSpacing.md) {
            Label(bootstrapStore.selectedCity?.title ?? "Львовское", systemImage: "mappin.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SlivkiColor.textPrimary)
                .lineLimit(1)

            Spacer()

            if let phone = bootstrapStore.site?.phone, !phone.isEmpty {
                Label(phone, systemImage: "phone.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SlivkiColor.textSecondary)
                    .lineLimit(1)
            }

            Button("Обратная связь") {
                router.selectedTab = .profile
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(SlivkiColor.brandDark)
        }
    }

    private var accountMenu: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
            if !sessionStore.isAuthenticated {
                SlivkiSectionTitle("Информация", subtitle: nil)
            }

            if sessionStore.isAuthenticated {
                menuButton("Мои заказы", subtitle: "История и статусы", systemImage: "bag", badge: nil) {
                    router.navigate(to: .orders, in: .profile)
                }
            } else {
                menuButton("Кабинет клиента", subtitle: "Войдите по телефону выше", systemImage: "person.crop.circle", badge: "вход") {}
            }

            menuButton("Избранное", subtitle: "Сохраненные товары", systemImage: "heart", badge: nil) {
                router.navigate(to: .favorites, in: .profile)
            }

            menuButton(
                "Адрес доставки",
                subtitle: addressSubtitle,
                systemImage: "mappin.and.ellipse",
                badge: nil
            ) {
                showsAddresses = true
            }

            menuButton("Доставка", subtitle: "Условия и время доставки", systemImage: "truck.box", badge: nil) {
                router.navigate(to: .legal(path: "/pages/rules.html"), in: .profile)
            }
            menuButton("Оплата", subtitle: "Наличными или картой при получении", systemImage: "creditcard", badge: nil) {
                showsPaymentMethods = true
            }
            menuButton("Контакты", subtitle: "Связаться со Сливки", systemImage: "phone", badge: nil) {
                router.selectedTab = .profile
            }

            menuButton("Правила", subtitle: "Условия сервиса", systemImage: "doc.text", badge: nil) {
                router.navigate(to: .legal(path: "/pages/rules.html"), in: .profile)
            }

            menuButton("Соглашение", subtitle: "Пользовательские условия", systemImage: "doc.plaintext", badge: nil) {
                router.navigate(to: .legal(path: "/pages/agreement.html"), in: .profile)
            }
        }
    }

    private func menuButton(_ title: String, subtitle: String?, systemImage: String, badge: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            SlivkiSiteMenuRow(title, subtitle: subtitle, systemImage: systemImage, badge: badge)
        }
        .buttonStyle(.plain)
    }

    private func loadRecentOrder() async {
        guard sessionStore.isAuthenticated else {
            recentOrder = nil
            return
        }

        do {
            let response: OrderListResponse = try await apiClient.get(.orders)
            guard !Task.isCancelled else {
                return
            }
            recentOrder = response.items.first
        } catch {
            recentOrder = nil
        }
    }
}
