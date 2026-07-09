import Combine
import Foundation

@MainActor
public final class FavoritesStore: ObservableObject {
    @Published public private(set) var productIDs: Set<String> {
        didSet {
            persist()
        }
    }
    @Published public private(set) var products: [Product] {
        didSet {
            persist()
        }
    }

    private let storage: UserDefaults?
    private let storageKey: String
    private let productsStorageKey: String

    public init(
        productIDs: Set<String> = [],
        products: [Product] = [],
        storage: UserDefaults? = .standard,
        storageKey: String = "slivki.favoriteProductIDs",
        productsStorageKey: String = "slivki.favoriteProducts"
    ) {
        self.storage = storage
        self.storageKey = storageKey
        self.productsStorageKey = productsStorageKey

        if productIDs.isEmpty,
           let stored = storage?.stringArray(forKey: storageKey) {
            self.productIDs = Set(stored)
        } else {
            self.productIDs = productIDs
        }

        if products.isEmpty,
           let data = storage?.data(forKey: productsStorageKey),
           let decoded = try? JSONDecoder.slivki.decode([Product].self, from: data) {
            self.products = decoded
        } else {
            self.products = products
        }

        if self.productIDs.isEmpty, !self.products.isEmpty {
            self.productIDs = Set(self.products.map(\.id))
        }
    }

    public func contains(_ product: Product) -> Bool {
        productIDs.contains(product.id)
    }

    public func toggle(_ product: Product) {
        if productIDs.contains(product.id) {
            productIDs.remove(product.id)
            products.removeAll { $0.id == product.id }
        } else {
            productIDs.insert(product.id)
            products.removeAll { $0.id == product.id }
            products.insert(product, at: 0)
        }
    }

    public func removeAll() {
        productIDs.removeAll()
        products.removeAll()
    }

    private func persist() {
        storage?.set(Array(productIDs).sorted(), forKey: storageKey)
        if let data = try? JSONEncoder.slivki.encode(products) {
            storage?.set(data, forKey: productsStorageKey)
        }
    }
}
