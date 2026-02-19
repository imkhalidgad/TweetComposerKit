import Foundation

/// Protocol for the network client (dependency inversion).
public protocol NetworkClientProtocol: Sendable {
    func request<T: Decodable & Sendable>(
        _ endPoint: any APIEndPoint,
        responseType: T.Type
    ) async throws -> T
}

/// Performs HTTP requests using `APIConfiguration` and returns decoded responses.
public final class NetworkClient: NetworkClientProtocol, @unchecked Sendable {
    private let urlSession: URLSession
    private let configuration: APIConfiguration

    public init(
        urlSession: URLSession = .shared,
        configuration: APIConfiguration
    ) {
        self.urlSession = urlSession
        self.configuration = configuration
    }

    public func request<T: Decodable & Sendable>(
        _ endPoint: any APIEndPoint,
        responseType: T.Type
    ) async throws -> T {
        guard let url = buildURL(for: endPoint) else {
            throw NetworkError.invalidURL
        }

        let request = try buildURLRequest(url: url, endPoint: endPoint)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw NetworkError.timeout
            }
            throw NetworkError.urlSessionError(error)
        }

        try validateResponse(response, data: data)
        return try decodeResponse(data: data, to: responseType)
    }

    private func buildURL(for endPoint: APIEndPoint) -> URL? {
        URL(string: endPoint.path, relativeTo: configuration.baseURL)
    }

    private func buildURLRequest(url: URL, endPoint: APIEndPoint) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = endPoint.httpMethod.rawValue
        request.timeoutInterval = configuration.timeoutInterval

        configuration.defaultHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        endPoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let parameters = endPoint.parameters,
           endPoint.httpMethod == .post || endPoint.httpMethod == .put {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            } catch {
                throw NetworkError.encodingError(error)
            }
        }

        return request
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidHTTPResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpStatus(statusCode: httpResponse.statusCode, data: data)
        }
    }

    private func decodeResponse<T: Decodable>(data: Data, to type: T.Type) throws -> T {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
