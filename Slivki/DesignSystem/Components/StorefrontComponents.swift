import SwiftUI

public struct SlivkiSearchBar: View {
    @Binding private var text: String
    private let placeholder: String
    private let onSubmit: () -> Void

    public init(text: Binding<String>, placeholder: String = "Что вы хотите найти?", onSubmit: @escaping () -> Void = {}) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: SlivkiSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SlivkiColor.textSecondary)

            TextField(placeholder, text: $text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SlivkiColor.textPrimary)
                .submitLabel(.search)
                .onSubmit(onSubmit)
        }
        .padding(.horizontal, SlivkiSpacing.md)
        .frame(height: 52)
        .background(SlivkiColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(SlivkiColor.border.opacity(0.85), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

public struct StorefrontDeliveryStrip: View {
    public init() {}

    public var body: some View {
        HStack(spacing: SlivkiSpacing.sm) {
            HStack(spacing: SlivkiSpacing.xs) {
                Image(systemName: "truck.box")
                    .font(.footnote.weight(.semibold))
                Text("Доставка от 30 мин")
                    .font(.footnote.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 28)

            HStack(spacing: SlivkiSpacing.xs) {
                Image(systemName: "gift")
                    .font(.footnote.weight(.semibold))
                Text("Бесплатная доставка от 500 ₽")
                    .font(.footnote.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(SlivkiColor.textPrimary)
        .padding(.horizontal, SlivkiSpacing.sm)
        .padding(.vertical, SlivkiSpacing.sm)
        .frame(minHeight: 48)
        .frame(maxWidth: .infinity)
        .background(SlivkiColor.surface)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(SlivkiColor.border, lineWidth: 1)
        )
    }
}

public struct StorefrontHeader: View {
    public enum Variant {
        case home
        case cart
        case standard
    }

    private let variant: Variant
    private let siteName: String
    private let logoURL = URL(string: "https://slivki-shop.ru/templates/default/images/mobile-logo-wordmark.png?v=20260527")

    @EnvironmentObject private var bootstrapStore: BootstrapStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var sessionStore: SessionStore

    @State private var showsCityPicker = false

    public init(variant: Variant, siteName: String = "Сливки") {
        self.variant = variant
        self.siteName = siteName
    }

    public var body: some View {
        HStack(spacing: 6) {
            logo

            Spacer(minLength: 0)

            Button {
                showsCityPicker = true
            } label: {
                HStack(spacing: SlivkiSpacing.xs) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(SlivkiColor.brandBright)
                    Text(cityTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SlivkiColor.textPrimary)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SlivkiColor.textSecondary)
                }
                .padding(.horizontal, SlivkiSpacing.sm)
                .frame(height: 42)
                .frame(minWidth: 118, maxWidth: 140)
                .background(SlivkiColor.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(SlivkiColor.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Город \(cityTitle)")
            .accessibilityHint("Открывает выбор города")

            if variant == .home {
                Button {
                    router.selectedTab = .cart
                } label: {
                    Image(systemName: "cart")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(SlivkiColor.textSecondary)
                        .frame(width: 40, height: 40)
                        .background(SlivkiColor.groupedBackground)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(SlivkiColor.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Корзина")
            }

            if variant != .cart {
                Button {
                    router.selectedTab = .profile
                } label: {
                    Image(systemName: sessionStore.isAuthenticated ? "person.fill" : "person")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(SlivkiColor.textSecondary)
                        .frame(width: 40, height: 40)
                        .background(SlivkiColor.groupedBackground)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(SlivkiColor.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(sessionStore.isAuthenticated ? "Кабинет" : "Войти")
            }
        }
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showsCityPicker) {
            CityPickerSheet(
                cities: bootstrapStore.cities,
                selectedCityID: bootstrapStore.selectedCity?.id
            ) { city in
                bootstrapStore.selectCity(city)
            }
        }
    }

    private var cityTitle: String {
        bootstrapStore.selectedCity?.title ?? "Львовское"
    }

    private var logo: some View {
        Group {
            if let logoURL {
                AsyncImage(url: logoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure, .empty:
                        Text(siteName)
                            .font(.largeTitle.weight(.black))
                            .foregroundStyle(SlivkiColor.brandDark)
                    @unknown default:
                        Text(siteName)
                            .font(.largeTitle.weight(.black))
                            .foregroundStyle(SlivkiColor.brandDark)
                    }
                }
            } else {
                Text(siteName)
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(SlivkiColor.brandDark)
            }
        }
        .frame(width: 98, height: 54, alignment: .leading)
        .clipped()
        .accessibilityLabel(siteName)
    }
}

public struct CityPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let cities: [City]
    private let selectedCityID: String?
    private let onSelect: (City) -> Void

    public init(cities: [City], selectedCityID: String?, onSelect: @escaping (City) -> Void) {
        self.cities = cities
        self.selectedCityID = selectedCityID
        self.onSelect = onSelect
    }

    public var body: some View {
        NavigationStack {
            List {
                if cities.isEmpty {
                    Text("Список городов пока недоступен")
                        .foregroundStyle(SlivkiColor.textSecondary)
                } else {
                    ForEach(cities) { city in
                        Button {
                            onSelect(city)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(city.title)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(SlivkiColor.textPrimary)
                                    if let region = city.region, !region.isEmpty {
                                        Text(region)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(SlivkiColor.textSecondary)
                                    }
                                }
                                Spacer()
                                if city.id == selectedCityID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(SlivkiColor.brandDark)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Выберите город")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        #endif
    }
}

public struct ProductSortToolbar: View {
    @Binding private var sort: ProductSort
    @Binding private var filters: ProductCatalogFilters
    @State private var showsFilterSheet = false

    public init(sort: Binding<ProductSort>, filters: Binding<ProductCatalogFilters> = .constant(ProductCatalogFilters())) {
        self._sort = sort
        self._filters = filters
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
            Button {
                showsFilterSheet = true
            } label: {
                HStack(spacing: SlivkiSpacing.xs) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.subheadline.weight(.bold))
                    Text(filters.hasActiveFilters ? "Фильтр • \(activeFilterCount)" : "Фильтр")
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SlivkiColor.textSecondary)
                }
                .foregroundStyle(SlivkiColor.textPrimary)
                .padding(.horizontal, SlivkiSpacing.md)
                .frame(height: 44)
                .background(SlivkiColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(filters.hasActiveFilters ? SlivkiColor.brandBright : SlivkiColor.border.opacity(0.75), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SlivkiSpacing.xs) {
                    sortButton("Новые", sort: .new)
                    sortButton("Популярные", sort: .popular)
                    priceSortButton()
                    sortButton("По скидке", sort: .sale)
                }
            }
        }
        .sheet(isPresented: $showsFilterSheet) {
            ProductFilterSheet(filters: $filters)
        }
    }

    private var activeFilterCount: Int {
        [filters.inStockOnly, filters.onSaleOnly].filter { $0 }.count
    }

    private func priceSortButton() -> some View {
        let isSelected = sort == .priceAsc || sort == .priceDesc
        let title = sort == .priceDesc ? "По цене ↓" : "По цене ↑"

        return Button {
            if sort == .priceAsc {
                sort = .priceDesc
            } else {
                sort = .priceAsc
            }
        } label: {
            SlivkiChip(title, isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }

    private func sortButton(_ title: String, sort targetSort: ProductSort) -> some View {
        Button {
            sort = targetSort
        } label: {
            SlivkiChip(title, isSelected: sort == targetSort)
        }
        .buttonStyle(.plain)
    }
}

private struct ProductFilterSheet: View {
    @Binding var filters: ProductCatalogFilters
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Показать") {
                    Toggle("В наличии", isOn: $filters.inStockOnly)
                    Toggle("Только акции", isOn: $filters.onSaleOnly)
                }
            }
            .navigationTitle("Фильтр")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Сбросить") {
                        filters = ProductCatalogFilters()
                    }
                    .disabled(!filters.hasActiveFilters)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium])
        #endif
    }
}

public struct SlivkiSectionTitle: View {
    private let title: String
    private let subtitle: String?

    public init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(SlivkiColor.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(SlivkiColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

public struct SlivkiMobilePageHeader<Trailing: View>: View {
    private let title: String
    private let subtitle: String?
    private let trailing: Trailing

    public init(_ title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .top, spacing: SlivkiSpacing.md) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(SlivkiColor.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SlivkiColor.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            trailing
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

public extension SlivkiMobilePageHeader where Trailing == EmptyView {
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = EmptyView()
    }
}

public struct SlivkiSiteMenuRow: View {
    private let title: String
    private let subtitle: String?
    private let systemImage: String
    private let badge: String?

    public init(_ title: String, subtitle: String? = nil, systemImage: String, badge: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.badge = badge
    }

    public var body: some View {
        HStack(spacing: SlivkiSpacing.md) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(SlivkiColor.brandDark)
                .frame(width: 38, height: 38)
                .background(SlivkiColor.brandBright.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(SlivkiColor.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SlivkiColor.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: SlivkiSpacing.sm)

            if let badge {
                Text(badge)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SlivkiColor.brandDark)
                    .padding(.horizontal, SlivkiSpacing.sm)
                    .frame(height: 26)
                    .background(SlivkiColor.brandBright.opacity(0.18))
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(SlivkiColor.textSecondary)
        }
        .padding(.horizontal, SlivkiSpacing.md)
        .frame(minHeight: 64)
        .background(SlivkiColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(SlivkiColor.border.opacity(0.75), lineWidth: 1)
        )
    }
}

public struct ProfileQuickAction: Identifiable {
    public let id = UUID()
    public let title: String
    public let systemImage: String
    public let action: () -> Void

    public init(title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }
}

public struct ProfileCabinetCard: View {
    private let user: User
    private let recentOrder: Order?
    private let quickActions: [ProfileQuickAction]
    private let onLogout: () -> Void
    private let onRecentOrderTap: ((Order) -> Void)?

    public init(
        user: User,
        recentOrder: Order? = nil,
        quickActions: [ProfileQuickAction],
        onLogout: @escaping () -> Void,
        onRecentOrderTap: ((Order) -> Void)? = nil
    ) {
        self.user = user
        self.recentOrder = recentOrder
        self.quickActions = quickActions
        self.onLogout = onLogout
        self.onRecentOrderTap = onRecentOrderTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
            HStack(alignment: .center, spacing: SlivkiSpacing.md) {
                Text(userInitials)
                    .font(.title3.weight(.black))
                    .foregroundStyle(SlivkiColor.brandDark)
                    .frame(width: 54, height: 54)
                    .background(SlivkiColor.brandBright.opacity(0.2))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.title3.weight(.black))
                        .foregroundStyle(SlivkiColor.textPrimary)
                    if let phone = user.phone, !phone.isEmpty {
                        Text(phone)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(SlivkiColor.textSecondary)
                    }
                    if let email = user.email, !email.isEmpty {
                        Text(email)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(SlivkiColor.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }

            if !quickActions.isEmpty {
                HStack(spacing: SlivkiSpacing.sm) {
                    ForEach(quickActions) { action in
                        Button(action: action.action) {
                            VStack(spacing: SlivkiSpacing.xs) {
                                Image(systemName: action.systemImage)
                                    .font(.headline.weight(.bold))
                                Text(action.title)
                                    .font(.caption.weight(.bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundStyle(SlivkiColor.brandDark)
                            .frame(maxWidth: .infinity)
                            .frame(height: 72)
                            .background(SlivkiColor.brandBright.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let recentOrder {
                Button {
                    onRecentOrderTap?(recentOrder)
                } label: {
                    VStack(alignment: .leading, spacing: SlivkiSpacing.xs) {
                        Text("Последний заказ")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(SlivkiColor.textSecondary)
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("№ \(recentOrder.number)")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(SlivkiColor.textPrimary)
                                Text(recentOrder.status.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(SlivkiColor.brandDark)
                            }
                            Spacer()
                            Text(SlivkiMoney.format(recentOrder.total))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(SlivkiColor.textPrimary)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(SlivkiColor.textSecondary)
                        }
                    }
                    .padding(SlivkiSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SlivkiColor.groupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }

            Button("Выйти", role: .destructive, action: onLogout)
                .font(.subheadline.weight(.bold))
        }
        .padding(SlivkiSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SlivkiColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(SlivkiColor.border.opacity(0.75), lineWidth: 1)
        )
    }

    private var userInitials: String {
        let parts = user.displayName
            .split(whereSeparator: { $0.isWhitespace })
            .prefix(2)
            .compactMap { $0.first }
        if parts.isEmpty {
            return "С"
        }
        return String(parts).uppercased()
    }
}

public struct SlivkiChip: View {
    private let title: String
    private let systemImage: String?
    private let isSelected: Bool

    public init(_ title: String, systemImage: String? = nil, isSelected: Bool = false) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
    }

    public var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
            }

            Text(title)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(isSelected ? .white : SlivkiColor.textPrimary)
        .padding(.horizontal, SlivkiSpacing.sm)
        .frame(height: 34)
        .background(isSelected ? SlivkiColor.brandDark : SlivkiColor.surface)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isSelected ? SlivkiColor.brandDark : SlivkiColor.border.opacity(0.8), lineWidth: 1)
        )
    }
}

public struct SlivkiCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(SlivkiSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SlivkiColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(SlivkiColor.border.opacity(0.6), lineWidth: 1)
            )
    }
}

public struct StorefrontFooter: View {
    private let site: MobileSiteInfo?
    private let email: String
    private let onFavorites: (() -> Void)?
    private let onAbout: (() -> Void)?
    private let onFeedback: (() -> Void)?
    private let onRules: (() -> Void)?
    private let onAgreement: (() -> Void)?

    public init(
        site: MobileSiteInfo?,
        email: String = "grig-svetlana@yandex.ru",
        onFavorites: (() -> Void)? = nil,
        onAbout: (() -> Void)? = nil,
        onFeedback: (() -> Void)? = nil,
        onRules: (() -> Void)? = nil,
        onAgreement: (() -> Void)? = nil
    ) {
        self.site = site
        self.email = email
        self.onFavorites = onFavorites
        self.onAbout = onAbout
        self.onFeedback = onFeedback
        self.onRules = onRules
        self.onAgreement = onAgreement
    }

    public var body: some View {
        VStack(spacing: SlivkiSpacing.sm) {
            brandCard

            VStack(spacing: 0) {
                if let phone = site?.phone, !phone.isEmpty {
                    footerRow(phone, subtitle: "Звонок в магазин", systemImage: "phone")
                }
                footerRow(email, subtitle: "Задайте вопрос по почте", systemImage: "envelope")
                footerRow(hours, subtitle: "Без выходных", systemImage: "clock")
                footerRow(address, subtitle: hours, systemImage: "mappin.and.ellipse")
            }
            .background(SlivkiColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack(spacing: SlivkiSpacing.sm) {
                quickButton("О сервисе", systemImage: "info.circle", action: onAbout)
                quickButton("Обратная связь", systemImage: "bubble.left.and.bubble.right", action: onFeedback)
                quickButton("Избранное", systemImage: "heart", action: onFavorites)
                quickButton("Правила", systemImage: "doc.text", action: onRules)
            }

            if onRules != nil || onAgreement != nil {
                VStack(alignment: .leading, spacing: 4) {
                    if let onRules {
                        Button("Правила сервиса", action: onRules)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SlivkiColor.brandDark)
                    }
                    if let onAgreement {
                        Button("Пользовательское соглашение", action: onAgreement)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SlivkiColor.brandDark)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, SlivkiSpacing.xs)
            }
        }
    }

    private var hours: String {
        site?.hours ?? "С 8:00 до 20:00"
    }

    private var address: String {
        site?.address ?? "Краснодарский край, Северский р-н, с. Львовское, ул.Советская, д. 46"
    }

    private var brandCard: some View {
        HStack(spacing: SlivkiSpacing.md) {
            RoundedRectangle(cornerRadius: 8)
                .fill(SlivkiColor.accent)
                .frame(width: 48, height: 48)
                .overlay(Text("C").font(.title2.weight(.black)).foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text(site?.name ?? "Сливки")
                    .font(.headline.weight(.black))
                Text("доставка продуктов")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SlivkiColor.textSecondary)
            }
            Spacer()
            Circle().fill(SlivkiColor.brandBright).frame(width: 10, height: 10)
        }
        .padding(SlivkiSpacing.md)
        .background(SlivkiColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func footerRow(_ title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: SlivkiSpacing.md) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(SlivkiColor.brandDark)
                .frame(width: 34, height: 34)
                .background(SlivkiColor.brandBright.opacity(0.14))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(SlivkiColor.textPrimary)
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SlivkiColor.textSecondary)
            }
            Spacer()
        }
        .padding(SlivkiSpacing.md)
    }

    @ViewBuilder
    private func quickButton(_ title: String, systemImage: String, action: (() -> Void)?) -> some View {
        if let action {
            Button(action: action) {
                quickButtonLabel(title, systemImage: systemImage)
            }
            .buttonStyle(.plain)
        } else {
            quickButtonLabel(title, systemImage: systemImage)
                .opacity(0.45)
        }
    }

    private func quickButtonLabel(_ title: String, systemImage: String) -> some View {
        VStack(spacing: SlivkiSpacing.xs) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
            Text(title)
                .font(.caption2.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(SlivkiColor.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, SlivkiSpacing.sm)
        .background(SlivkiColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#if os(iOS)
public struct SlivkiFloatingTabBar: View {
    @Binding private var selectedTab: AppTab
    private let cartCount: Int
    private let profileTitle: String

    public init(selectedTab: Binding<AppTab>, cartCount: Int, profileTitle: String) {
        self._selectedTab = selectedTab
        self.cartCount = cartCount
        self.profileTitle = profileTitle
    }

    public var body: some View {
        HStack(spacing: 0) {
            tabButton(.home, title: "Главная", systemImage: "house")
            tabButton(.catalog, title: "Каталог", systemImage: "square.grid.2x2")
            tabButton(.cart, title: "Корзина", systemImage: "cart", badge: cartCount)
            tabButton(.profile, title: profileTitle, systemImage: "person")
        }
        .padding(.horizontal, SlivkiSpacing.md)
        .padding(.vertical, SlivkiSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(SlivkiColor.surface)
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(SlivkiColor.border.opacity(0.65), lineWidth: 1)
        )
        .padding(.horizontal, SlivkiSpacing.md)
        .padding(.bottom, SlivkiSpacing.xs)
    }

    private func tabButton(_ tab: AppTab, title: String, systemImage: String, badge: Int = 0) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: systemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(selectedTab == tab ? SlivkiColor.brandBright : SlivkiColor.textSecondary)

                    if badge > 0 {
                        Text(badge > 99 ? "99+" : "\(badge)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(SlivkiColor.brandDark)
                            .clipShape(Capsule())
                            .offset(x: 10, y: -8)
                    }
                }
                .frame(height: 28)

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(selectedTab == tab ? SlivkiColor.brandDark : SlivkiColor.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SlivkiSpacing.xs)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
#endif
