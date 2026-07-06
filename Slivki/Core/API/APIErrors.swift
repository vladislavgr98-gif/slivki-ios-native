import Foundation

public enum APIError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed(String)
    case encodingFailed(String)
    case networkUnavailable(String)
}
