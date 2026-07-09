import Combine
import Foundation

public struct SavedDeliveryAddress: Identifiable, Codable, Equatable {
    public let id: String
    public var city: String
    public var street: String
    public var house: String
    public var line1: String
    public var entrance: String?
    public var floor: String?
    public var apartment: String?
    public var intercom: String?
    public var comment: String?
    public var isDefault: Bool

    public var formattedLine: String {
        var parts: [String] = []
        let streetLine = [street.trimmingCharacters(in: .whitespacesAndNewlines), {
            let trimmedHouse = house.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedHouse.isEmpty ? nil : "д. \(trimmedHouse)"
        }()]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        if streetLine.isEmpty {
            let legacy = line1.trimmingCharacters(in: .whitespacesAndNewlines)
            if !legacy.isEmpty {
                parts.append(legacy)
            }
        } else {
            parts.append(streetLine)
        }

        if let apartment = apartment?.trimmingCharacters(in: .whitespacesAndNewlines), !apartment.isEmpty {
            parts.append("кв. \(apartment)")
        }
        if let entrance = entrance?.trimmingCharacters(in: .whitespacesAndNewlines), !entrance.isEmpty {
            parts.append("подъезд \(entrance)")
        }
        if let floor = floor?.trimmingCharacters(in: .whitespacesAndNewlines), !floor.isEmpty {
            parts.append("этаж \(floor)")
        }
        if let intercom = intercom?.trimmingCharacters(in: .whitespacesAndNewlines), !intercom.isEmpty {
            parts.append("домофон \(intercom)")
        }
        return parts.joined(separator: ", ")
    }

    public init(
        id: String = UUID().uuidString,
        city: String,
        street: String = "",
        house: String = "",
        line1: String = "",
        entrance: String? = nil,
        floor: String? = nil,
        apartment: String? = nil,
        intercom: String? = nil,
        comment: String? = nil,
        isDefault: Bool = false
    ) {
        self.id = id
        self.city = city
        self.street = street
        self.house = house
        self.line1 = line1
        self.entrance = entrance
        self.floor = floor
        self.apartment = apartment
        self.intercom = intercom
        self.comment = comment
        self.isDefault = isDefault
    }

    enum CodingKeys: String, CodingKey {
        case id, city, street, house, line1, entrance, floor, apartment, intercom, comment, isDefault
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        city = try container.decode(String.self, forKey: .city)
        street = try container.decodeIfPresent(String.self, forKey: .street) ?? ""
        house = try container.decodeIfPresent(String.self, forKey: .house) ?? ""
        line1 = try container.decodeIfPresent(String.self, forKey: .line1) ?? ""
        entrance = try container.decodeIfPresent(String.self, forKey: .entrance)
        floor = try container.decodeIfPresent(String.self, forKey: .floor)
        apartment = try container.decodeIfPresent(String.self, forKey: .apartment)
        intercom = try container.decodeIfPresent(String.self, forKey: .intercom)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false

        if street.isEmpty, !line1.isEmpty {
            street = line1
        }
    }
}

@MainActor
public final class DeliveryAddressStore: ObservableObject {
    @Published public private(set) var addresses: [SavedDeliveryAddress] {
        didSet {
            persist()
        }
    }

    private let storage: UserDefaults?
    private let storageKey: String

    public var defaultAddress: SavedDeliveryAddress? {
        addresses.first(where: \.isDefault) ?? addresses.first
    }

    public init(addresses: [SavedDeliveryAddress] = [], storage: UserDefaults? = nil, storageKey: String = "slivki.deliveryAddresses") {
        self.storage = storage
        self.storageKey = storageKey

        if addresses.isEmpty,
           let data = storage?.data(forKey: storageKey),
           let decoded = try? JSONDecoder.slivki.decode([SavedDeliveryAddress].self, from: data) {
            self.addresses = decoded
        } else {
            self.addresses = addresses
        }
    }

    public func upsert(_ address: SavedDeliveryAddress) {
        var next = addresses
        if let index = next.firstIndex(where: { $0.id == address.id }) {
            next[index] = address
        } else {
            next.append(address)
        }

        if address.isDefault {
            next = next.map { item in
                var copy = item
                copy.isDefault = item.id == address.id
                return copy
            }
        } else if !next.contains(where: \.isDefault), let index = next.firstIndex(where: { $0.id == address.id }) {
            next[index].isDefault = true
        }

        addresses = next
    }

    public func remove(id: String) {
        var next = addresses.filter { $0.id != id }
        if !next.isEmpty, !next.contains(where: \.isDefault) {
            next[0].isDefault = true
        }
        addresses = next
    }

    public func setDefault(id: String) {
        addresses = addresses.map { item in
            var copy = item
            copy.isDefault = item.id == id
            return copy
        }
    }

    private func persist() {
        if let data = try? JSONEncoder.slivki.encode(addresses) {
            storage?.set(data, forKey: storageKey)
        }
    }
}
