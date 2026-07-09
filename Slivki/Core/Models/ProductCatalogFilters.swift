import Foundation

public struct ProductCatalogFilters: Equatable {
    public var inStockOnly: Bool
    public var onSaleOnly: Bool

    public var hasActiveFilters: Bool {
        inStockOnly || onSaleOnly
    }

    public init(inStockOnly: Bool = false, onSaleOnly: Bool = false) {
        self.inStockOnly = inStockOnly
        self.onSaleOnly = onSaleOnly
    }
}
