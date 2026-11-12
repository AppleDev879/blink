import Foundation

enum BookDownloadError: LocalizedError {
    case noPlainTextURL
    case badStatus(Int)
    case emptyBody

    var errorDescription: String? {
        switch self {
        case .noPlainTextURL:
            return "No plain-text edition is listed for this book."
        case .badStatus(let code):
            return "Download failed (\(code))."
        case .emptyBody:
            return "Downloaded file was empty."
        }
    }
}

actor BookDownloadService {
    static let shared = BookDownloadService()

    private let session: URLSession

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.httpAdditionalHeaders = [
                "User-Agent": GutendexClient.userAgent,
                "Accept": "text/plain, */*"
            ]
            config.timeoutIntervalForRequest = 60
            self.session = URLSession(configuration: config)
        }
    }

    func download(summary: BookSummary, to destination: URL) async throws {
        var candidates: [URL] = []
        if let primary = summary.resolvedPlainTextURL {
            candidates.append(primary)
        }
        if let fallback = StarterCatalog.fallbackPlainTextURL(bookID: summary.id),
           fallback != summary.plainTextURL {
            candidates.append(fallback)
        }
        guard !candidates.isEmpty else { throw BookDownloadError.noPlainTextURL }

        var lastError: Error = BookDownloadError.noPlainTextURL
        for url in candidates {
            do {
                try await download(from: url, to: destination)
                return
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    private func download(from url: URL, to destination: URL) async throws {
        var request = URLRequest(url: url)
        request.setValue(GutendexClient.userAgent, forHTTPHeaderField: "User-Agent")

        let (tempURL, response) = try await session.download(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw BookDownloadError.badStatus(http.statusCode)
        }

        let attrs = try FileManager.default.attributesOfItem(atPath: tempURL.path)
        let size = attrs[.size] as? NSNumber
        if let size, size.intValue == 0 {
            throw BookDownloadError.emptyBody
        }

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: tempURL, to: destination)
    }
}
