import SwiftUI

private struct APIClientKey: EnvironmentKey {
    static let defaultValue = APIClient()
}

public extension EnvironmentValues {
    var apiClient: APIClient {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }
}
