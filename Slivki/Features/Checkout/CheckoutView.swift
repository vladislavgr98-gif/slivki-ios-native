import SwiftUI

public struct CheckoutView: View {
    @Environment(\.apiClient) private var apiClient
    @EnvironmentObject private var cartStore: CartStore
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var addressStore: DeliveryAddressStore
    @EnvironmentObject private var bootstrapStore: BootstrapStore
    @EnvironmentObject private var checkoutStore: CheckoutStore
    @EnvironmentObject private var router: AppRouter

    @State private var customerName = ""
    @State private var phone = ""
    @State private var city = Fixtures.city.title
    @State private var street = ""
    @State private var house = ""
    @State private var apartment = ""
    @State private var entrance = ""
    @State private var floor = ""
    @State private var intercom = ""
    @State private var comment = ""
    @State private var deliveryMethod: DeliveryMethod = .delivery
    @State private var paymentMethodID = "card_on_delivery"
    @State private var deliveryTimeSummary = "Ближайший доступный интервал"
    @State private var promoCode = ""
    @State private var showsPromoSheet = false
    @State private var showsDeliveryTimeSheet = false
    @State private var deliverySelections: [String: CheckoutDeliverySelection] = [:]
    @State private var selectedServerAddressID: String?
    @State private var selectedServerRecipientID: String?
    @State private var preparedOrder: CheckoutOrderDraft?
    @State private var createdOrderID: String?
    @State private var createdOrderNumber: String?
    @State private var createdOrderIsDraft = true
    @State private var isDraftPrepared = false
    @State private var showsSaveAddressPrompt = false
    @State private var isSubmitting = false
    @State private var submitMessage: String?
    @State private var showsRecipientSheet = false
    @State private var showsAddressSheet = false
    @State private var showsCommentSheet = false

    public init() {}

    public var body: some View {
        let draft = CheckoutDraft(customerName: customerName, phone: phone, city: city, address: checkoutAddress, comment: comment)

        ScrollView {
            VStack(alignment: .leading, spacing: SlivkiSpacing.lg) {
                SlivkiMobilePageHeader("Оформление заказа", subtitle: selectedCityTitle)

                if !cartStore.checkoutItems.isEmpty {
                    CheckoutMobileCard("Товары в заказе", subtitle: "\(cartStore.checkoutItems.count) шт.") {
                        VStack(spacing: SlivkiSpacing.sm) {
                            ForEach(cartStore.checkoutItems.prefix(3)) { item in
                                HStack(alignment: .top, spacing: SlivkiSpacing.sm) {
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
                            if cartStore.checkoutItems.count > 3 {
                                Text("Еще \(cartStore.checkoutItems.count - 3) товаров в заказе")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(SlivkiColor.textSecondary)
                            }
                        }
                    }
                }

                CheckoutMobileCard("Способ получения") {
                    HStack(spacing: SlivkiSpacing.sm) {
                        CheckoutFulfillmentOption(
                            title: "Доставка",
                            subtitle: "курьером по адресу",
                            isSelected: deliveryMethod == .delivery
                        ) {
                            deliveryMethod = .delivery
                        }
                        CheckoutFulfillmentOption(
                            title: "Самовывоз",
                            subtitle: "без доставки",
                            isSelected: deliveryMethod == .pickup
                        ) {
                            deliveryMethod = .pickup
                        }
                    }
                }

                CheckoutMobileCard("Данные заказа") {
                    VStack(spacing: SlivkiSpacing.sm) {
                        CheckoutSettingRow(
                            label: "Получатель",
                            value: recipientSummary,
                            systemImage: "person.fill"
                        ) {
                            showsRecipientSheet = true
                        }

                        if deliveryMethod == .delivery {
                            CheckoutSettingRow(
                                label: "Адрес доставки",
                                value: addressSummary,
                                systemImage: "mappin.and.ellipse"
                            ) {
                                showsAddressSheet = true
                            }

                            CheckoutSettingRow(
                                label: "Время доставки",
                                value: deliveryTimeSummary,
                                systemImage: "clock"
                            ) {
                                if sessionStore.isAuthenticated {
                                    showsDeliveryTimeSheet = true
                                }
                            }
                        } else {
                            CheckoutSettingRow(
                                label: "Пункт самовывоза",
                                value: pickupAddress,
                                systemImage: "bag.fill"
                            ) {}
                        }

                        CheckoutSettingRow(
                            label: "Комментарий к заказу",
                            value: commentSummary,
                            systemImage: "text.bubble"
                        ) {
                            showsCommentSheet = true
                        }

                        if sessionStore.isAuthenticated {
                            CheckoutSettingRow(
                                label: "Промокод",
                                value: promoSummary,
                                systemImage: "tag.fill"
                            ) {
                                showsPromoSheet = true
                            }
                        }
                    }
                }

                CheckoutMobileCard("Способ оплаты") {
                    HStack(spacing: SlivkiSpacing.sm) {
                        CheckoutPaymentOption(
                            title: "Картой / QR",
                            subtitle: "при получении",
                            systemImage: "creditcard",
                            isSelected: paymentMethodID == "card_on_delivery"
                        ) {
                            paymentMethodID = "card_on_delivery"
                        }
                        CheckoutPaymentOption(
                            title: "Наличными",
                            subtitle: "при получении",
                            systemImage: "banknote",
                            isSelected: paymentMethodID == "cash"
                        ) {
                            paymentMethodID = "cash"
                        }
                    }
                }

                CheckoutMobileCard("Состав заказа") {
                    VStack(spacing: SlivkiSpacing.sm) {
                        CheckoutSummaryRow(title: "Товары", value: SlivkiMoney.format(displayItemsTotal))
                        if displayDiscountTotal > 0 {
                            CheckoutSummaryRow(title: "Скидка", value: "-\(SlivkiMoney.format(displayDiscountTotal))")
                        }
                        CheckoutSummaryRow(
                            title: deliveryMethod == .pickup ? "Самовывоз" : "Доставка",
                            value: SlivkiMoney.format(displayDeliveryTotal)
                        )
                        Divider()
                        CheckoutSummaryRow(title: "Итого", value: SlivkiMoney.format(displayPayableTotal), isTotal: true)
                    }
                }

                if checkoutStore.isLoadingQuote {
                    ProgressView("Рассчитываем доставку...")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(SlivkiColor.textSecondary)
                } else if let quoteError = checkoutStore.quoteError, sessionStore.isAuthenticated {
                    Text(quoteError)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(SlivkiColor.warning)
                }

                if let message = draft.validationErrors.first?.message {
                    Text(message)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(SlivkiColor.warning)
                }

                if let submitMessage {
                    Text(submitMessage)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(SlivkiColor.textSecondary)
                }
            }
            .padding(SlivkiSpacing.md)
            .padding(.bottom, 96)
        }
        .background(SlivkiColor.groupedBackground)
        .navigationTitle("Оформление")
        .slivkiHideNavigationBar()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            checkoutStickyBar(draft: draft)
        }
        .onAppear {
            prefillFromSession()
            syncDefaultPaymentMethod()
            Task {
                await loadServerCheckoutData()
                await refreshCheckoutQuote()
            }
        }
        .onChange(of: cartStore.checkoutTotal) { _ in
            syncDefaultPaymentMethod()
            Task { await refreshCheckoutQuote() }
        }
        .onChange(of: deliveryMethod) { _ in
            Task { await refreshCheckoutQuote() }
        }
        .onChange(of: promoCode) { _ in
            Task { await refreshCheckoutQuote() }
        }
        .onChange(of: formattedDeliveryAddress) { _ in
            Task { await refreshCheckoutQuote() }
        }
        .sheet(isPresented: $showsRecipientSheet) {
            CheckoutRecipientSheet(customerName: $customerName, phone: $phone)
        }
        .sheet(isPresented: $showsAddressSheet) {
            CheckoutAddressSheet(
                city: $city,
                street: $street,
                house: $house,
                apartment: $apartment,
                entrance: $entrance,
                floor: $floor,
                intercom: $intercom,
                selectedCityTitle: selectedCityTitle
            )
        }
        .sheet(isPresented: $showsCommentSheet) {
            CheckoutCommentSheet(comment: $comment)
        }
        .sheet(isPresented: $showsPromoSheet) {
            CheckoutPromoSheet(promoCode: $promoCode)
        }
        .sheet(isPresented: $showsDeliveryTimeSheet) {
            CheckoutDeliveryTimeSheet(
                groups: checkoutStore.quote?.groups ?? [],
                selections: $deliverySelections,
                summary: $deliveryTimeSummary
            )
        }
        .alert(createdOrderIsDraft ? "Заказ подготовлен" : "Заказ принят", isPresented: $isDraftPrepared) {
            if let createdOrderID {
                Button("К заказу") {
                    router.navigate(to: .order(id: createdOrderID), in: .cart)
                }
            }
            if sessionStore.isAuthenticated {
                Button("Все заказы") {
                    router.navigate(to: .orders, in: .cart)
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            let count = preparedOrder?.items.count ?? 0
            if createdOrderIsDraft {
                Text("В заказе \(count) позиций. Для отправки на кухню войдите в аккаунт.")
            } else if let createdOrderNumber {
                Text("Заказ № \(createdOrderNumber) принят. В заказе \(count) позиций.")
            } else {
                Text("Заказ принят. В заказе \(count) позиций.")
            }
        }
        .alert("Сохранить адрес?", isPresented: $showsSaveAddressPrompt) {
            Button("Сохранить") {
                saveCurrentAddress()
            }
            Button("Не сейчас", role: .cancel) {}
        } message: {
            Text("Сохранить адрес доставки для следующих заказов?")
        }
    }

    private var selectedCityTitle: String {
        bootstrapStore.selectedCity?.title ?? city
    }

    private var pickupAddress: String {
        bootstrapStore.site?.address ?? "Самовывоз: Сливки-Шоп"
    }

    private var recipientSummary: String {
        let name = customerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneValue = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty, phoneValue.isEmpty {
            return "Укажите имя и телефон"
        }
        if phoneValue.isEmpty {
            return name
        }
        if name.isEmpty {
            return phoneValue
        }
        return "\(name)  \(phoneValue)"
    }

    private var addressSummary: String {
        let formatted = formattedDeliveryAddress
        return formatted.isEmpty ? "Выберите адрес доставки" : formatted
    }

    private var commentSummary: String {
        let trimmed = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Не указан" : trimmed
    }

    private var promoSummary: String {
        let trimmed = promoCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Не указан" : trimmed
    }

    private var displayItemsTotal: Decimal {
        checkoutStore.quote?.itemsTotal ?? cartStore.checkoutTotal
    }

    private var displayDiscountTotal: Decimal {
        checkoutStore.quote?.discountTotal ?? 0
    }

    private var displayDeliveryTotal: Decimal {
        if deliveryMethod == .pickup {
            return 0
        }
        return checkoutStore.quote?.deliveryTotal ?? 0
    }

    private var displayPayableTotal: Decimal {
        checkoutStore.quote?.payableTotal ?? cartStore.checkoutTotal
    }

    private var fulfillmentTypeValue: String {
        deliveryMethod == .pickup ? "pickup" : "delivery"
    }

    private var formattedDeliveryAddress: String {
        SavedDeliveryAddress(
            city: city,
            street: street,
            house: house,
            entrance: entrance.nilIfEmpty,
            floor: floor.nilIfEmpty,
            apartment: apartment.nilIfEmpty,
            intercom: intercom.nilIfEmpty
        ).formattedLine
    }

    private var checkoutAddress: String {
        deliveryMethod == .pickup ? pickupAddress : formattedDeliveryAddress
    }

    @ViewBuilder
    private func checkoutStickyBar(draft: CheckoutDraft) -> some View {
        VStack(spacing: SlivkiSpacing.xs) {
            Button {
                Task {
                    await submit(draft)
                }
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isSubmitting ? "Обработка..." : "Оформить заказ")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Text(SlivkiMoney.format(displayPayableTotal))
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, SlivkiSpacing.md)
                .frame(height: 54)
                .background(SlivkiColor.brandDark)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(cartStore.checkoutItems.isEmpty || !draft.isValid || isSubmitting)

            if !draft.isValid {
                Text(checkoutPrerequisiteMessage(for: draft))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SlivkiColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, SlivkiSpacing.md)
        .padding(.top, SlivkiSpacing.sm)
        .padding(.bottom, SlivkiSpacing.sm)
        .background(SlivkiColor.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(SlivkiColor.border.opacity(0.8))
                .frame(height: 1)
        }
    }

    private func checkoutPrerequisiteMessage(for draft: CheckoutDraft) -> String {
        if customerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Пожалуйста, укажите получателя."
        }
        if deliveryMethod == .delivery, formattedDeliveryAddress.isEmpty {
            return "Пожалуйста, выберите адрес доставки."
        }
        return draft.validationErrors.first?.message ?? "Заполните данные для оформления."
    }

    private func prefillFromSession() {
        city = selectedCityTitle

        if let user = sessionStore.currentUser {
            if customerName.isEmpty {
                customerName = user.name ?? ""
            }
            if phone.isEmpty {
                phone = user.phone ?? ""
            }
        }

        if let recipient = checkoutStore.selectedRecipient {
            customerName = recipient.name
            phone = recipient.phone
            selectedServerRecipientID = recipient.id
        }

        if let serverAddress = checkoutStore.selectedAddress {
            applyServerAddress(serverAddress)
            selectedServerAddressID = serverAddress.id
        } else if let saved = addressStore.defaultAddress {
            city = saved.city
            street = saved.street.isEmpty ? saved.line1 : saved.street
            house = saved.house
            apartment = saved.apartment ?? ""
            entrance = saved.entrance ?? ""
            floor = saved.floor ?? ""
            intercom = saved.intercom ?? ""
            if comment.isEmpty, let savedComment = saved.comment {
                comment = savedComment
            }
        }
    }

    private func applyServerAddress(_ address: CheckoutServerAddress) {
        city = address.city.isEmpty ? selectedCityTitle : address.city
        street = address.street
        house = address.house
        apartment = address.apartment ?? ""
        entrance = address.entrance ?? ""
        floor = address.floor ?? ""
        intercom = address.intercom ?? ""
        if comment.isEmpty, let serverComment = address.comment {
            comment = serverComment
        }
    }

    private func loadServerCheckoutData() async {
        guard sessionStore.isAuthenticated else {
            return
        }
        await checkoutStore.loadAddresses(using: apiClient)
        await checkoutStore.loadRecipients(using: apiClient)
        prefillFromSession()
    }

    private func refreshCheckoutQuote() async {
        guard sessionStore.isAuthenticated else {
            checkoutStore.clearQuote()
            return
        }

        await checkoutStore.refreshQuote(
            items: cartStore.checkoutItems,
            fulfillmentType: fulfillmentTypeValue,
            addressId: selectedServerAddressID,
            cityId: bootstrapStore.selectedCity?.id,
            promoCode: promoCode,
            using: apiClient
        )

        if deliverySelections.isEmpty, let groups = checkoutStore.quote?.groups {
            for group in groups {
                if let interval = group.intervals.today.first ?? group.intervals.tomorrow.first {
                    let date = group.intervals.today.isEmpty
                        ? tomorrowDateString()
                        : todayDateString()
                    deliverySelections[group.id] = CheckoutDeliverySelection(
                        groupId: group.id,
                        date: date,
                        interval: interval.value
                    )
                }
            }
            deliveryTimeSummary = deliverySelections.values.first?.interval ?? deliveryTimeSummary
        }
    }

    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func tomorrowDateString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
    }

    private func syncDefaultPaymentMethod() {
        if cartStore.checkoutTotal < 11 {
            paymentMethodID = "cash"
        } else if paymentMethodID != "cash" && paymentMethodID != "card_on_delivery" {
            paymentMethodID = "card_on_delivery"
        }
    }

    private func saveCurrentAddress() {
        guard deliveryMethod == .delivery else {
            return
        }

        let saved = SavedDeliveryAddress(
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            street: street.trimmingCharacters(in: .whitespacesAndNewlines),
            house: house.trimmingCharacters(in: .whitespacesAndNewlines),
            line1: formattedDeliveryAddress,
            entrance: entrance.nilIfEmpty,
            floor: floor.nilIfEmpty,
            apartment: apartment.nilIfEmpty,
            intercom: intercom.nilIfEmpty,
            comment: comment.nilIfEmpty,
            isDefault: addressStore.addresses.isEmpty
        )
        addressStore.upsert(saved)
    }

    private var shouldOfferSavingAddress: Bool {
        guard deliveryMethod == .delivery else {
            return false
        }
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCity.isEmpty, !formattedDeliveryAddress.isEmpty else {
            return false
        }
        return !addressStore.addresses.contains {
            $0.city == trimmedCity && $0.formattedLine == formattedDeliveryAddress
        }
    }

    private func submit(_ draft: CheckoutDraft) async {
        guard draft.isValid, !cartStore.checkoutItems.isEmpty else {
            return
        }

        isSubmitting = true
        submitMessage = nil

        var addressId = selectedServerAddressID
        var recipientId = selectedServerRecipientID

        if sessionStore.isAuthenticated {
            do {
                let recipient = try await checkoutStore.saveRecipient(
                    CheckoutRecipientSaveRequest(
                        id: recipientId,
                        name: draft.trimmedCustomerName,
                        phone: draft.normalizedPhone
                    ),
                    using: apiClient
                )
                recipientId = recipient.id

                if deliveryMethod == .delivery {
                    let savedAddress = try await checkoutStore.saveAddress(
                        CheckoutAddressSaveRequest(
                            id: addressId,
                            cityId: bootstrapStore.selectedCity?.id,
                            city: draft.trimmedCity,
                            street: street.trimmingCharacters(in: .whitespacesAndNewlines),
                            house: house.trimmingCharacters(in: .whitespacesAndNewlines),
                            apartment: apartment.nilIfEmpty,
                            entrance: entrance.nilIfEmpty,
                            floor: floor.nilIfEmpty,
                            intercom: intercom.nilIfEmpty,
                            comment: comment.nilIfEmpty,
                            isDefault: true
                        ),
                        using: apiClient
                    )
                    addressId = savedAddress.id
                    selectedServerAddressID = savedAddress.id
                }
            } catch {
                submitMessage = "Не удалось сохранить данные заказа."
                isSubmitting = false
                return
            }
        }

        let orderDraft = CheckoutOrderDraft(
            draft: draft,
            items: cartStore.checkoutItems,
            total: displayPayableTotal,
            paymentMethodID: paymentMethodID,
            fulfillmentType: fulfillmentTypeValue,
            addressId: deliveryMethod == .delivery ? addressId : nil,
            recipientId: recipientId,
            promoCode: promoCode.nilIfEmpty,
            pickupAddress: deliveryMethod == .pickup ? pickupAddress : nil,
            deliverySelections: deliveryMethod == .delivery ? Array(deliverySelections.values) : nil
        )
        preparedOrder = orderDraft

        do {
            let response: OrderCreateResponse = try await apiClient.post(.orders, body: orderDraft)
            guard !Task.isCancelled else {
                return
            }
            createdOrderID = response.order.id
            createdOrderNumber = response.order.number
            createdOrderIsDraft = response.order.id.hasPrefix("mobile-draft")
            cartStore.clearCheckoutItems()
            submitMessage = createdOrderIsDraft
                ? "Черновик \(response.order.number) сохранён."
                : "Заказ № \(response.order.number) принят."
            isDraftPrepared = true
            if shouldOfferSavingAddress, !sessionStore.isAuthenticated {
                showsSaveAddressPrompt = true
            }
        } catch {
            submitMessage = "Не удалось отправить заказ. Проверьте связь и повторите."
        }

        isSubmitting = false
    }
}

private struct CheckoutRecipientSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var customerName: String
    @Binding var phone: String

    var body: some View {
        NavigationStack {
            Form {
                Section("Получатель") {
                    TextField("Имя и фамилия", text: $customerName)
                    TextField("Телефон", text: $phone)
                        .slivkiKeyboardType(.phonePad)
                }
            }
            .navigationTitle("Получатель")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }
}

private struct CheckoutAddressSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var city: String
    @Binding var street: String
    @Binding var house: String
    @Binding var apartment: String
    @Binding var entrance: String
    @Binding var floor: String
    @Binding var intercom: String
    let selectedCityTitle: String

    var body: some View {
        NavigationStack {
            Form {
                Section("Город") {
                    Text(selectedCityTitle)
                }
                Section("Адрес") {
                    TextField("Улица", text: $street)
                    TextField("Дом", text: $house)
                    TextField("Квартира", text: $apartment)
                }
                Section("Детали") {
                    TextField("Подъезд", text: $entrance)
                    TextField("Этаж", text: $floor)
                    TextField("Домофон", text: $intercom)
                }
            }
            .navigationTitle("Адрес доставки")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                if city.isEmpty {
                    city = selectedCityTitle
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                        .fontWeight(.bold)
                        .disabled(street.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || house.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct CheckoutPromoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var promoCode: String

    var body: some View {
        NavigationStack {
            Form {
                Section("Промокод") {
                    TextField("Введите промокод", text: $promoCode)
                }
            }
            .navigationTitle("Промокод")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }
}

private struct CheckoutDeliveryTimeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let groups: [CheckoutQuoteGroup]
    @Binding var selections: [String: CheckoutDeliverySelection]
    @Binding var summary: String

    var body: some View {
        NavigationStack {
            Form {
                if groups.isEmpty {
                    Text("Интервалы появятся после расчёта доставки.")
                        .foregroundStyle(SlivkiColor.textSecondary)
                } else {
                    ForEach(groups) { group in
                        Section(group.title) {
                            if !group.intervals.today.isEmpty {
                                Text("Сегодня")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(SlivkiColor.textSecondary)
                                ForEach(group.intervals.today) { interval in
                                    intervalButton(group: group, interval: interval, date: todayDateString())
                                }
                            }
                            if !group.intervals.tomorrow.isEmpty {
                                Text("Завтра")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(SlivkiColor.textSecondary)
                                ForEach(group.intervals.tomorrow) { interval in
                                    intervalButton(group: group, interval: interval, date: tomorrowDateString())
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Время доставки")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }

    private func intervalButton(group: CheckoutQuoteGroup, interval: CheckoutIntervalOption, date: String) -> some View {
        let isSelected = selections[group.id]?.interval == interval.value && selections[group.id]?.date == date
        return Button {
            selections[group.id] = CheckoutDeliverySelection(groupId: group.id, date: date, interval: interval.value)
            summary = interval.label
            dismiss()
        } label: {
            HStack {
                Text(interval.label)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(SlivkiColor.brandBright)
                }
            }
        }
    }

    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func tomorrowDateString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
    }
}

private struct CheckoutCommentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var comment: String

    var body: some View {
        NavigationStack {
            Form {
                Section("Комментарий курьеру") {
                    TextField("Введите комментарий", text: $comment, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section {
                    ForEach(["Позвонить перед доставкой", "Не звонить в домофон", "Оставить у двери"], id: \.self) { suggestion in
                        Button(suggestion) {
                            comment = suggestion
                        }
                    }
                }
            }
            .navigationTitle("Комментарий")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private enum DeliveryMethod: CaseIterable {
    case delivery
    case pickup
}
