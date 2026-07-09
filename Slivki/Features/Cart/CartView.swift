import SwiftUI

public struct CartView: View {
    @EnvironmentObject private var bootstrapStore: BootstrapStore
    @EnvironmentObject private var cartStore: CartStore
    @EnvironmentObject private var router: AppRouter
    @State private var selectedItemIDs = Set<String>()
    @State private var acceptsTerms = true

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
                if cartStore.isEmpty {
                    emptyCart
                } else {
                    Text("Корзина")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(SlivkiColor.textPrimary)

                    Text("\(cartStore.items.count) товаров")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SlivkiColor.textSecondary)

                    selectionBar

                    VStack(spacing: SlivkiSpacing.xs) {
                        ForEach(cartStore.items) { item in
                            CartRow(
                                item: item,
                                isSelected: selectedItemIDs.contains(item.id),
                                onToggleSelected: {
                                    toggleSelection(item.id)
                                }
                            )
                        }
                    }

                    totalCard
                }
            }
            .padding(.horizontal, SlivkiSpacing.md)
            .padding(.bottom, cartStore.isEmpty ? SlivkiSpacing.md : 120)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !cartStore.isEmpty {
                stickyCheckoutBar
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                StorefrontHeader(
                    variant: .cart,
                    siteName: bootstrapStore.site?.name ?? "Сливки"
                )
                .padding(.horizontal, SlivkiSpacing.md)
                .padding(.top, SlivkiSpacing.md)
                .padding(.bottom, SlivkiSpacing.sm)

                if !cartStore.isEmpty {
                    deliveryStrip
                        .padding(.horizontal, SlivkiSpacing.md)
                        .padding(.bottom, SlivkiSpacing.sm)
                }
            }
            .background(SlivkiColor.surface)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(SlivkiColor.border.opacity(0.8))
                    .frame(height: 1)
            }
        }
        .background(SlivkiColor.groupedBackground)
        .navigationTitle("Корзина")
        .slivkiHideNavigationBar()
        .onAppear {
            syncSelection()
        }
        .onChange(of: cartStore.items) { _ in
            syncSelection()
        }
    }

    private var selectedItems: [CartItem] {
        cartStore.items.filter { selectedItemIDs.contains($0.id) }
    }

    private var selectedTotal: Decimal {
        selectedItems.reduce(Decimal.zero) { $0 + $1.lineTotal }
    }

    private var selectedCount: Int {
        selectedItems.reduce(0) { $0 + $1.quantity }
    }

    private var freeDeliveryRemaining: Decimal {
        max(Decimal(500) - selectedTotal, .zero)
    }

    private var deliveryProgress: Double {
        min((NSDecimalNumber(decimal: selectedTotal).doubleValue / 500.0), 1.0)
    }

    private var selectionBar: some View {
        VStack(spacing: SlivkiSpacing.sm) {
            HStack {
                Button {
                    if selectedItemIDs.count == cartStore.items.count {
                        selectedItemIDs.removeAll()
                    } else {
                        selectedItemIDs = Set(cartStore.items.map(\.id))
                    }
                } label: {
                    Label(selectedItemIDs.count == cartStore.items.count ? "Снять выбор" : "Выбрать все", systemImage: selectedItemIDs.count == cartStore.items.count ? "checkmark.circle.fill" : "circle")
                        .font(.subheadline.weight(.bold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(SlivkiColor.textPrimary)

                Spacer()

                Button(role: .destructive) {
                    selectedItemIDs.forEach { cartStore.remove(itemID: $0) }
                    selectedItemIDs.removeAll()
                } label: {
                    Label("Удалить", systemImage: "trash")
                        .font(.subheadline.weight(.bold))
                }
                .buttonStyle(.plain)
                .disabled(selectedItemIDs.isEmpty)
            }

            VStack(alignment: .leading, spacing: SlivkiSpacing.xs) {
                ProgressView(value: deliveryProgress)
                    .tint(SlivkiColor.brandBright)
                Text(freeDeliveryRemaining == .zero ? "Бесплатная доставка доступна" : "До бесплатной доставки \(SlivkiMoney.format(freeDeliveryRemaining))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SlivkiColor.textSecondary)
            }
        }
        .padding(SlivkiSpacing.md)
        .background(SlivkiColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(SlivkiColor.border.opacity(0.75), lineWidth: 1))
    }

    private var deliveryStrip: some View {
        HStack(spacing: SlivkiSpacing.sm) {
            Label("Доставка от 30 мин", systemImage: "scooter")
                .frame(maxWidth: .infinity)
            Divider()
                .frame(height: 20)
            Label("Бесплатная от 500 ₽", systemImage: "gift")
                .frame(maxWidth: .infinity)
        }
        .font(.footnote.weight(.bold))
        .foregroundStyle(SlivkiColor.textPrimary)
        .padding(.horizontal, SlivkiSpacing.sm)
        .frame(height: 46)
        .background(SlivkiColor.surface)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(SlivkiColor.border.opacity(0.8), lineWidth: 1)
        )
    }

    private var emptyCart: some View {
        VStack(spacing: SlivkiSpacing.lg) {
            Spacer(minLength: 100)

            Text("В Вашей корзине нет товаров")
                .font(.body.weight(.medium))
                .foregroundStyle(SlivkiColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Button {
                router.selectedTab = .catalog
            } label: {
                Label("Перейти в каталог", systemImage: "square.grid.2x2")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(SlivkiColor.brandBright)

            Spacer(minLength: 100)
        }
        .frame(maxWidth: .infinity)
    }

    private var stickyCheckoutBar: some View {
        VStack(spacing: SlivkiSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Итого")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SlivkiColor.textSecondary)
                    Text(SlivkiMoney.format(selectedTotal))
                        .font(.title3.weight(.black))
                        .foregroundStyle(SlivkiColor.textPrimary)
                }

                Spacer()

                Button {
                    cartStore.prepareCheckout(with: selectedItemIDs)
                    router.navigate(to: .checkout, in: .cart)
                } label: {
                    Label("Оформить", systemImage: "checkmark.circle.fill")
                        .font(.headline.weight(.black))
                        .frame(minWidth: 160)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(SlivkiColor.brandBright)
                .disabled(selectedItemIDs.isEmpty || !acceptsTerms)
            }

            Button {
                acceptsTerms.toggle()
            } label: {
                HStack(alignment: .top, spacing: SlivkiSpacing.sm) {
                    Image(systemName: acceptsTerms ? "checkmark.square.fill" : "square")
                        .foregroundStyle(acceptsTerms ? SlivkiColor.brandDark : SlivkiColor.textSecondary)
                    Text("Согласен с условиями сервиса и обработки заказа")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SlivkiColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(SlivkiSpacing.md)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(SlivkiColor.border.opacity(0.7))
                .frame(height: 1)
        }
    }

    private var totalCard: some View {
        VStack(spacing: SlivkiSpacing.md) {
            totalLine("Выбрано", value: "\(selectedCount) шт")
            totalLine("Товары", value: SlivkiMoney.format(selectedTotal))
            totalLine("Скидка", value: "0 ₽")
            totalLine("Доставка", value: "рассчитаем при оформлении")
            Divider()
            totalLine("Итого", value: SlivkiMoney.format(selectedTotal), isTotal: true)
        }
        .padding(SlivkiSpacing.md)
        .background(SlivkiColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(SlivkiColor.border.opacity(0.75), lineWidth: 1)
        )
    }

    private func totalLine(_ title: String, value: String, isTotal: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(isTotal ? .headline.weight(.bold) : .subheadline.weight(.medium))
                .foregroundStyle(isTotal ? SlivkiColor.textPrimary : SlivkiColor.textSecondary)
            Spacer()
            Text(value)
                .font(isTotal ? .title3.weight(.bold) : .subheadline.weight(.semibold))
                .foregroundStyle(SlivkiColor.textPrimary)
        }
    }

    private func toggleSelection(_ id: String) {
        if selectedItemIDs.contains(id) {
            selectedItemIDs.remove(id)
        } else {
            selectedItemIDs.insert(id)
        }
    }

    private func syncSelection() {
        let currentIDs = Set(cartStore.items.map(\.id))
        if selectedItemIDs.isEmpty {
            selectedItemIDs = currentIDs
        } else {
            selectedItemIDs = selectedItemIDs.intersection(currentIDs)
            if selectedItemIDs.isEmpty, !currentIDs.isEmpty {
                selectedItemIDs = currentIDs
            }
        }
    }
}

private struct CartRow: View {
    @EnvironmentObject private var cartStore: CartStore
    let item: CartItem
    let isSelected: Bool
    let onToggleSelected: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
            HStack(alignment: .top, spacing: SlivkiSpacing.md) {
                Button(action: onToggleSelected) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(isSelected ? SlivkiColor.brandBright : SlivkiColor.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSelected ? "Товар выбран" : "Выбрать товар")

                productPlaceholder

                VStack(alignment: .leading, spacing: SlivkiSpacing.xs) {
                    Text(item.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(SlivkiColor.textPrimary)
                        .lineLimit(3)

                    Text(SlivkiMoney.format(item.price))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(SlivkiColor.textSecondary)
                    Text("В наличии")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SlivkiColor.brandDark)
                }

                Spacer()

                Button {
                    cartStore.remove(itemID: item.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SlivkiColor.textSecondary)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
            }

            HStack {
                QuantityStepper(
                    quantity: Binding(
                        get: { item.quantity },
                        set: { cartStore.setQuantity(itemID: item.id, quantity: $0) }
                    )
                )

                Spacer()

                Text(SlivkiMoney.format(item.lineTotal))
                    .font(.headline.weight(.black))
                    .foregroundStyle(SlivkiColor.textPrimary)
            }
        }
        .padding(SlivkiSpacing.md)
        .background(SlivkiColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(SlivkiColor.border.opacity(0.75), lineWidth: 1)
        )
    }

    private var productPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(SlivkiColor.groupedBackground)
            if let imageURL = item.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit().padding(4)
                    case .failure, .empty:
                        Image(systemName: "shippingbox")
                            .font(.title3)
                            .foregroundStyle(SlivkiColor.brandDark)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "shippingbox")
                    .font(.title3)
                    .foregroundStyle(SlivkiColor.brandDark)
            }
        }
        .frame(width: 64, height: 64)
    }
}
