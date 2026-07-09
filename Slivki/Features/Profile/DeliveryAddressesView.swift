import SwiftUI

public struct DeliveryAddressesView: View {
    @EnvironmentObject private var addressStore: DeliveryAddressStore
    @Environment(\.dismiss) private var dismiss
    @State private var editorAddress: SavedDeliveryAddress?
    @State private var isCreating = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if addressStore.addresses.isEmpty {
                    VStack(spacing: SlivkiSpacing.md) {
                        EmptyStateView(
                            "Адресов пока нет",
                            systemImage: "mappin.and.ellipse",
                            message: "Сохраните адрес доставки, чтобы быстрее оформлять заказы."
                        )
                        Button("Добавить адрес") {
                            isCreating = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SlivkiColor.brandBright)
                    }
                    .padding(SlivkiSpacing.md)
                } else {
                    List {
                        ForEach(addressStore.addresses) { address in
                            Button {
                                editorAddress = address
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(address.city)
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(SlivkiColor.textPrimary)
                                        if address.isDefault {
                                            Text("Основной")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(SlivkiColor.brandDark)
                                                .padding(.horizontal, 8)
                                                .frame(height: 22)
                                                .background(SlivkiColor.brandBright.opacity(0.18))
                                                .clipShape(Capsule())
                                        }
                                    }
                                    Text(address.formattedLine)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(SlivkiColor.textSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    addressStore.remove(id: address.id)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                if !address.isDefault {
                                    Button {
                                        addressStore.setDefault(id: address.id)
                                    } label: {
                                        Label("Основной", systemImage: "star.fill")
                                    }
                                    .tint(SlivkiColor.brandDark)
                                }
                            }
                        }
                    }
                    #if os(iOS)
                    .listStyle(.insetGrouped)
                    #else
                    .listStyle(.sidebar)
                    #endif
                }
            }
            .navigationTitle("Адреса доставки")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Добавить") {
                        isCreating = true
                    }
                }
            }
            .sheet(item: $editorAddress) { address in
                DeliveryAddressEditorView(address: address)
            }
            .sheet(isPresented: $isCreating) {
                DeliveryAddressEditorView(
                    address: SavedDeliveryAddress(city: "Львовское", street: "", house: "", isDefault: addressStore.addresses.isEmpty)
                )
            }
        }
    }
}

private struct DeliveryAddressEditorView: View {
    @EnvironmentObject private var addressStore: DeliveryAddressStore
    @Environment(\.dismiss) private var dismiss

    @State private var city: String
    @State private var street: String
    @State private var house: String
    @State private var entrance: String
    @State private var floor: String
    @State private var apartment: String
    @State private var intercom: String
    @State private var comment: String
    @State private var isDefault: Bool
    private let addressID: String

    init(address: SavedDeliveryAddress) {
        _city = State(initialValue: address.city)
        _street = State(initialValue: address.street.isEmpty ? address.line1 : address.street)
        _house = State(initialValue: address.house)
        _entrance = State(initialValue: address.entrance ?? "")
        _floor = State(initialValue: address.floor ?? "")
        _apartment = State(initialValue: address.apartment ?? "")
        _intercom = State(initialValue: address.intercom ?? "")
        _comment = State(initialValue: address.comment ?? "")
        _isDefault = State(initialValue: address.isDefault)
        addressID = address.id
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Адрес") {
                    TextField("Город", text: $city)
                    TextField("Улица", text: $street)
                    TextField("Дом", text: $house)
                    TextField("Квартира", text: $apartment)
                }

                Section("Детали") {
                    TextField("Подъезд", text: $entrance)
                    TextField("Этаж", text: $floor)
                    TextField("Домофон", text: $intercom)
                }

                Section("Комментарий") {
                    TextField("Комментарий для курьера", text: $comment, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Toggle("Сделать основным", isOn: $isDefault)
                }
            }
            .navigationTitle("Адрес")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        save()
                    }
                    .fontWeight(.bold)
                    .disabled(
                        city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || street.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || house.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
        }
    }

    private func save() {
        let address = SavedDeliveryAddress(
            id: addressID,
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            street: street.trimmingCharacters(in: .whitespacesAndNewlines),
            house: house.trimmingCharacters(in: .whitespacesAndNewlines),
            line1: SavedDeliveryAddress(
                city: city,
                street: street,
                house: house,
                entrance: entrance.nilIfEmpty,
                floor: floor.nilIfEmpty,
                apartment: apartment.nilIfEmpty,
                intercom: intercom.nilIfEmpty
            ).formattedLine,
            entrance: entrance.nilIfEmpty,
            floor: floor.nilIfEmpty,
            apartment: apartment.nilIfEmpty,
            intercom: intercom.nilIfEmpty,
            comment: comment.nilIfEmpty,
            isDefault: isDefault
        )
        addressStore.upsert(address)
        dismiss()
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
