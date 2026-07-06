import SwiftUI

public struct CategoryTileView: View {
    let category: Category

    public init(category: Category) {
        self.category = category
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.xs) {
            Image(systemName: "shippingbox")
                .font(.title3)
                .foregroundStyle(SlivkiColor.brand)

            Text(category.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SlivkiColor.textPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(SlivkiSpacing.sm)
        .frame(minHeight: 84, alignment: .topLeading)
        .background(SlivkiColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(SlivkiColor.border, lineWidth: 1)
        )
    }
}
