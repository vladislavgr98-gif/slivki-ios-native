import SwiftUI

public struct LegalWebView: View {
    let path: String

    public init(path: String) {
        self.path = path
    }

    public var body: some View {
        VStack(spacing: SlivkiSpacing.md) {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundStyle(SlivkiColor.brand)

            Text(title)
                .font(.title3.weight(.semibold))

            Text("На Mac добавим WKWebView только для юридических и статических страниц. Основные покупательские сценарии остаются нативными.")
                .font(.callout)
                .foregroundStyle(SlivkiColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(SlivkiSpacing.lg)
        .navigationTitle(title)
    }

    private var title: String {
        switch path {
        case "/pages/rules.html":
            "Правила"
        case "/pages/agreement.html":
            "Соглашение"
        default:
            "Документ"
        }
    }
}
