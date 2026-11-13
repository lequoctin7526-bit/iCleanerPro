import Foundation

/// Service to query official Apple public iTunes Search & Lookup APIs.
/// 100% compliant with Apple terms: no API keys required, safe HTTPS queries.
final class AppStoreLookupService: @unchecked Sendable {
    static let shared = AppStoreLookupService()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Looks up an app by its numeric App Store ID (trackId).
    func lookup(appStoreId: String, country: String = "vn") async throws -> AppStoreLookupItem? {
        guard let encodedId = appStoreId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/lookup?id=\(encodedId)&country=\(country)&entity=software") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.cachePolicy = .useProtocolCachePolicy

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return nil
        }

        let decoded = try JSONDecoder().decode(AppStoreLookupResponse.self, from: data)
        return decoded.results.first
    }

    /// Looks up an app by its bundle identifier.
    func lookup(bundleId: String, country: String = "vn") async throws -> AppStoreLookupItem? {
        guard let encodedBundle = bundleId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(encodedBundle)&country=\(country)&entity=software") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return nil
        }

        let decoded = try JSONDecoder().decode(AppStoreLookupResponse.self, from: data)
        return decoded.results.first
    }

    /// Searches apps on App Store by keyword query.
    func search(term: String, country: String = "vn", limit: Int = 15) async throws -> [AppStoreLookupItem] {
        guard !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let encodedTerm = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(encodedTerm)&entity=software&country=\(country)&limit=\(limit)") else {
            return []
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 12

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return []
        }

        let decoded = try JSONDecoder().decode(AppStoreLookupResponse.self, from: data)
        return decoded.results
    }
}
