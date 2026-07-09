import SwiftUI

public struct OrdersView: View {
    @Environment(\.apiClient) private var apiClient
    @EnvironmentObject private var cartStore: CartStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var sessionStore: SessionStore
    @State private var state: LoadState<OrderListResponse> = .idle
    @State private var repeatMessage: String?

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SlivkiSpacing.lg) {
                SlivkiSectionTitle("Заказы", subtitle: "История покупок и статусы доставки")
                content
            }
            .padding(SlivkiSpacing.md)
        }
        .background(SlivkiColor.groupedBackground)
        .navigationTitle("Заказы")
        .slivkiHideNavigationBar()
        .task(id: sessionStore.isAuthenticated) {
            if sessionStore.isAuthenticated {
                await loadOrders()
            } else {
                state = .idle
            }
        }
        .alert("Корзина обновлена", isPresented: Binding(
            get: { repeatMessage != nil },
            set: { if !$0 { repeatMessage = nil } }
        )) {
            Button("В корзину") {
                router.selectedTab = .cart
                repeatMessage = nil
            }
            Button("OK", role: .cancel) {
                repeatMessage = nil
            }
        } message: {
            Text(repeatMessage ?? "")
        }
    }

    @ViewBuilder
    private var content: some View {
        if sessionStore.isAuthenticated {
            LoadStateView(state: state, retry: {
                Task {
                    await loadOrders()
                }
            }) { response in
                if response.items.isEmpty {
                    SlivkiCard {
                        EmptyStateView("Заказов пока нет", systemImage: "list.clipboard")
                    }
                } else {
                    ordersList(response.items)
                }
            }
        } else {
            SlivkiCard {
                EmptyStateView(
                    "Войдите, чтобы увидеть заказы",
                    systemImage: "person.crop.circle",
                    message: "После входа здесь появятся покупки, статусы доставки и повтор заказа."
                )
            }
        }
    }

    private func ordersList(_ orders: [Order]) -> some View {
        VStack(spacing: SlivkiSpacing.sm) {
            ForEach(orders) { order in
                OrderRowView(
                    order: order,
                    onOpen: {
                        router.navigate(to: .order(id: order.id), in: .profile)
                    },
                    onRepeat: {
                        repeatOrder(order)
                    }
                )
            }
        }
    }

    private func repeatOrder(_ order: Order) {
        guard !order.items.isEmpty else {
            return
        }
        cartStore.add(orderItems: order.items)
        repeatMessage = "Добавлено \(order.items.count) позиций из заказа № \(order.number)."
    }

    private func loadOrders() async {
        state = .loading

        do {
            let response: OrderListResponse = try await apiClient.get(.orders)
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(response)
        } catch is CancellationError {
            return
        } catch {
            state = .failed("Не удалось загрузить заказы.")
        }
    }
}

public struct OrderDetailView: View {
    @Environment(\.apiClient) private var apiClient
    @EnvironmentObject private var cartStore: CartStore
    @EnvironmentObject private var router: AppRouter
    let orderID: String
    @State private var state: LoadState<Order> = .idle
    @State private var repeatMessage: String?

    public init(orderID: String) {
        self.orderID = orderID
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SlivkiSpacing.lg) {
                LoadStateView(state: state, retry: {
                    Task {
                        await loadOrder()
                    }
                }) { order in
                    SlivkiSectionTitle("Заказ \(order.number)", subtitle: order.status.title)

                    OrderStatusTimelineView(status: order.status)

                    SlivkiCard {
                        VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
                            detailRow("Создан", value: order.createdAt.formatted(date: .abbreviated, time: .shortened))
                            if let paymentTitle = order.paymentTitle {
                                detailRow("Оплата", value: paymentTitle)
                            }
                            if let phone = order.contactPhone {
                                detailRow("Телефон", value: phone)
                            }
                            if let comment = order.comment, !comment.isEmpty {
                                detailRow("Комментарий", value: comment)
                            }
                        }
                    }

                    SlivkiCard {
                        VStack(alignment: .leading, spacing: SlivkiSpacing.md) {
                            Text("Состав")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(SlivkiColor.textPrimary)

                            ForEach(order.items) { item in
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.footnote.weight(.semibold))
                                            .foregroundStyle(SlivkiColor.textPrimary)
                                            .lineLimit(2)
                                        Text("\(item.quantity) x \(SlivkiMoney.format(item.price))")
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(SlivkiColor.textSecondary)
                                    }
                                    Spacer()
                                    Text(SlivkiMoney.format(item.lineTotal))
                                        .font(.footnote.weight(.bold))
                                        .foregroundStyle(SlivkiColor.textPrimary)
                                }
                            }

                            Divider()

                            HStack {
                                Text("Итого")
                                    .font(.headline.weight(.bold))
                                Spacer()
                                Text(SlivkiMoney.format(order.total))
                                    .font(.headline.weight(.bold))
                            }
                            .foregroundStyle(SlivkiColor.textPrimary)

                            Button {
                                repeatOrder(order)
                            } label: {
                                Label("Повторить заказ", systemImage: "arrow.clockwise.circle.fill")
                                    .font(.headline.weight(.bold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(SlivkiColor.brandBright)
                            .disabled(order.items.isEmpty)
                        }
                    }
                }
            }
            .padding(SlivkiSpacing.md)
            .padding(.bottom, SlivkiSpacing.lg)
        }
        .background(SlivkiColor.groupedBackground)
        .navigationTitle("Заказ")
        .slivkiHideNavigationBar()
        .task(id: orderID) {
            await loadOrder()
        }
        .alert("Корзина обновлена", isPresented: Binding(
            get: { repeatMessage != nil },
            set: { if !$0 { repeatMessage = nil } }
        )) {
            Button("В корзину") {
                router.selectedTab = .cart
                repeatMessage = nil
            }
            Button("OK", role: .cancel) {
                repeatMessage = nil
            }
        } message: {
            Text(repeatMessage ?? "")
        }
    }

    private func repeatOrder(_ order: Order) {
        cartStore.add(orderItems: order.items)
        repeatMessage = "Добавлено \(order.items.count) позиций из заказа № \(order.number)."
    }

    private func loadOrder() async {
        state = .loading

        do {
            let response: OrderDetailResponse = try await apiClient.get(.order(id: orderID))
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(response.order)
        } catch is CancellationError {
            return
        } catch {
            state = .failed("Не удалось загрузить заказ.")
        }
    }

    private func detailRow(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SlivkiColor.textSecondary)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SlivkiColor.textPrimary)
        }
    }
}

struct OrderRowView: View {
    let order: Order
    let onOpen: () -> Void
    let onRepeat: () -> Void

    var body: some View {
        SlivkiCard {
            VStack(alignment: .leading, spacing: SlivkiSpacing.sm) {
                Button(action: onOpen) {
                    HStack(alignment: .center, spacing: SlivkiSpacing.md) {
                        VStack(alignment: .leading, spacing: SlivkiSpacing.xs) {
                            Text("Заказ \(order.number)")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(SlivkiColor.textPrimary)

                            Text(order.status.title)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(statusColor)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: SlivkiSpacing.xs) {
                            Text(SlivkiMoney.format(order.total))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(SlivkiColor.textPrimary)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(SlivkiColor.textSecondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Button(action: onRepeat) {
                    Label("Повторить заказ", systemImage: "arrow.clockwise")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SlivkiColor.brandDark)
                }
                .buttonStyle(.plain)
                .disabled(order.items.isEmpty)
            }
        }
    }

    private var statusColor: Color {
        switch order.status {
        case .cancelled:
            return SlivkiColor.warning
        case .completed, .paid:
            return SlivkiColor.brandDark
        default:
            return SlivkiColor.textSecondary
        }
    }
}
