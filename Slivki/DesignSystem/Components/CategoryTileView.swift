import SwiftUI

public struct CategoryTileView: View {
    let category: Category

    public init(category: Category) {
        self.category = category
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SlivkiSpacing.xs) {
            categoryImage

            Text(category.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SlivkiColor.textPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(SlivkiSpacing.sm)
        .frame(minHeight: 112, alignment: .topLeading)
        .background(SlivkiColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(SlivkiColor.border, lineWidth: 1)
        )
    }

    private var categoryImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(SlivkiColor.groupedBackground)

            if let imageURL = category.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(SlivkiSpacing.xs)
                    case .failure:
                        placeholderImage
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var placeholderImage: some View {
        Image(systemName: "shippingbox")
            .font(.title3)
            .foregroundStyle(SlivkiColor.brand)
    }
}
