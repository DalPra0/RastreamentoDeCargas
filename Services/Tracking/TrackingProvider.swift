import Foundation

struct TrackingResult {
    let status: OrderStatus
    let events: [TrackingEvent]
    let carrier: Carrier
}

protocol TrackingProvider {
    func normalizeIfTrackingCode(_ text: String) -> String?
    func fetchTracking(code: String, carrierHint: Carrier?) async throws -> TrackingResult
}

// Regex Correios: 2 letras + 9 dígitos + 2 letras (ex.: LB123456789CN)
fileprivate let correiosRegex = try! NSRegularExpression(pattern: "^[A-Z]{2}\\d{9}[A-Z]{2}$")

extension TrackingProvider {
    func looksLikeCorreios(_ code: String) -> Bool {
        let range = NSRange(location: 0, length: code.utf16.count)
        return correiosRegex.firstMatch(in: code.uppercased(), options: [], range: range) != nil
    }
    
    func extractTrackingCodes(from text: String) -> [String] {
        var found = Set<String>()
        
        // Regex para códigos dos Correios
        let correiosPattern = "\\b[A-Z]{2}\\d{9}[A-Z]{2}\\b"
        if let regex = try? NSRegularExpression(pattern: correiosPattern) {
            let range = NSRange(location: 0, length: text.utf16.count)
            regex.enumerateMatches(in: text.uppercased(), options: [], range: range) { match, _, _ in
                if let match, let range = Range(match.range, in: text) {
                    found.insert(String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
        
        // Regex para códigos genéricos (8+ caracteres alfanuméricos)
        let genericPattern = "\\b[A-Z0-9\\-]{8,}\\b"
        if let regex = try? NSRegularExpression(pattern: genericPattern) {
            let range = NSRange(location: 0, length: text.utf16.count)
            regex.enumerateMatches(in: text.uppercased(), options: [], range: range) { match, _, _ in
                if let match, let range = Range(match.range, in: text) {
                    let code = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if code.count >= 8 && code.count <= 30 { // Filtro básico
                        found.insert(code)
                    }
                }
            }
        }
        
        return Array(found)
    }
}
