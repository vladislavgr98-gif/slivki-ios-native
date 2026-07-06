import Foundation

public enum SlivkiMoney {
    public static func format(_ amount: Decimal, currencyCode: String = "BYN") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount) \(currencyCode)"
    }
}
