import SwiftUI

#if os(iOS)
import UIKit

public typealias SlivkiKeyboardType = UIKeyboardType
#else
public enum SlivkiKeyboardType {
    case emailAddress
    case numberPad
    case phonePad
}
#endif

public extension View {
    @ViewBuilder
    func slivkiKeyboardType(_ type: SlivkiKeyboardType) -> some View {
        #if os(iOS)
        keyboardType(type)
        #else
        self
        #endif
    }

    @ViewBuilder
    func slivkiInlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func slivkiHideNavigationBar() -> some View {
        #if os(iOS)
        toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }
}
