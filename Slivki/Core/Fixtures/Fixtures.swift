import Foundation

public enum Fixtures {
    public static let city = City(id: "minsk", title: "Минск", region: "Минская область")

    public static let categories: [Category] = [
        Category(id: "food", title: "Продукты", imageURL: nil),
        Category(id: "frozen", title: "Заморозка", imageURL: nil),
        Category(id: "home", title: "Для дома", imageURL: nil),
        Category(id: "beauty", title: "Красота", imageURL: nil)
    ]

    public static let products: [Product] = [
        Product(
            id: "icecream-azart",
            title: "Мороженое Азарт ванильное с джемом киви",
            imageURL: nil,
            price: Decimal(149.90),
            oldPrice: Decimal(179.90),
            unit: "шт",
            isAvailable: true,
            sellerTitle: "Сливки"
        ),
        Product(
            id: "berries-mix",
            title: "Ягодный микс замороженный",
            imageURL: nil,
            price: Decimal(229.00),
            oldPrice: nil,
            unit: "уп",
            isAvailable: true,
            sellerTitle: "Сливки"
        ),
        Product(
            id: "coffee",
            title: "Кофе зерновой",
            imageURL: nil,
            price: Decimal(399.00),
            oldPrice: Decimal(459.00),
            unit: "шт",
            isAvailable: false,
            sellerTitle: "Партнер"
        )
    ]
}
