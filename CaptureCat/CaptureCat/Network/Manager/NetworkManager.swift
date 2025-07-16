//
//  NetworkManager.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import Foundation

class NetworkManager {
    private var baseURL: URL
    
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    // MARK: - Public
    func fetchData<Builder: BuilderProtocol>(_ builder: Builder, isRetry: Bool = false) async throws -> Builder.Response {
        let request = try await makeRequest(builder)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let string = String(data: data, encoding: .utf8) {
            print("Response Body:", string)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.responseNotFound
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try await builder.deserializer.deserialize(data)
        case 400:
            throw NetworkError.badRequest
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forBidden
        case 404:
            throw NetworkError.responseNotFound
        case 429:
            throw NetworkError.tooManyRequests
        case 500:
            throw NetworkError.internalServerError
        default:
            throw NetworkError.unknown(httpResponse.statusCode)
        }
    }
    
    func fetchLoginData<Builder: BuilderProtocol>(_ builder: Builder, isRetry: Bool = false) async throws -> Builder.Response {
        let request = try await makeRequest(builder)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let string = String(data: data, encoding: .utf8) {
            print("Response Body:", string)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.responseNotFound
        }
        
        if let accessToken = httpResponse.value(forHTTPHeaderField: "Authorization"),
           let refreshToken = httpResponse.value(forHTTPHeaderField: "Refresh-Token") {
            KeyChainModule.create(key: .accessToken, data: accessToken)
            KeyChainModule.create(key: .refreshToken, data: refreshToken)
        }
        
        debugPrint("httpResponse: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200...299:
            return try await builder.deserializer.deserialize(data)
        case 400:
            throw NetworkError.badRequest
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forBidden
        case 404:
            throw NetworkError.responseNotFound
        case 429:
            throw NetworkError.tooManyRequests
        case 500:
            throw NetworkError.internalServerError
        default:
            throw NetworkError.unknown(httpResponse.statusCode)
        }
    }
    
    // MARK: - Private
    private func makeRequest<Builder: BuilderProtocol>(_ builder: Builder) async throws -> URLRequest {
        let fullURL = baseURL.appendingPathComponent(builder.path)
        var components = URLComponents(url: fullURL, resolvingAgainstBaseURL: false)
        components?.queryItems = builder.queries
        
        guard let url = components?.url else {
            throw NetworkError.urlNotFound
        }
        
        var request = URLRequest(url: url)
        builder.headers.forEach { (key, value) in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if builder.useAuthorization {
            let accesstoken = KeyChainModule.read(key: .accessToken) ?? ""
            request.setValue("Bearer \(accesstoken)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpMethod = builder.method.typeName
        
        if builder.method != .get {
            request.httpBody = try await builder.serializer.serialize(builder.parameters)
        }
        
        debugPrint("✅ [Request Info]")
        debugPrint("URL:", request.url?.absoluteString ?? "nil")
        debugPrint("Method:", request.httpMethod ?? "nil")
        debugPrint("Headers:", request.allHTTPHeaderFields ?? [:])
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            debugPrint("Body:", bodyString)
        }
        
        return request
    }
}
