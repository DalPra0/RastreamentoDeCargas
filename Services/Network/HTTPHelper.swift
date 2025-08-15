import Foundation

struct HTTP {
    static func get(_ url: URL, headers: [String: String] = [:]) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return try await URLSession.shared.data(for: request)
    }
    
    static func post(_ url: URL, body: Data? = nil, headers: [String: String] = [:]) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return try await URLSession.shared.data(for: request)
    }
}

enum HTTPError: Error, LocalizedError {
    case invalidResponse
    case serverError(Int)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Resposta inválida do servidor"
        case .serverError(let code):
            return "Erro do servidor: \(code)"
        case .noData:
            return "Nenhum dado recebido"
        }
    }
}
