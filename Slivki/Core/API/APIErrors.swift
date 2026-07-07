import Foundation

public enum APIError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case server(String, String)
    case decodingFailed(String)
    case encodingFailed(String)
    case networkUnavailable(String)
}
