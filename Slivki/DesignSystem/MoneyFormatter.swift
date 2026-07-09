import Foundation

public enum SlivkiMoney {
    public static func format(_ amount: Decimal, currencyCode: String = "RUB") -> String {
        var rounded = Decimal()
        var value = amount
        NSDecimalRound(&rounded, &value, 0, .plain)
        let hasFraction = rounded != amount

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = hasFraction ? 2 : 0
        formatter.maximumFractionDigits = hasFraction ? 2 : 0
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = ","

        let numberPart = formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
        // Storefront is RUB; ignore foreign codes for now and never print "RUB".
        _ = currencyCode
        return "\(numberPart) ₽"
    }
}
