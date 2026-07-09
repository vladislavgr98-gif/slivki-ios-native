import SwiftUI

private struct BootstrapReloadKey: EnvironmentKey {
    static let defaultValue: @Sendable () async -> Void = {}
}

public extension EnvironmentValues {
    var reloadBootstrap: @Sendable () async -> Void {
        get { self[BootstrapReloadKey.self] }
        set { self[BootstrapReloadKey.self] = newValue }
    }
}
