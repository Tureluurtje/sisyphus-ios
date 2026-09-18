import Foundation

enum APIEndpointConfiguration {
    private static let productionBaseURL = URL(string: "https://sisyphus.kwako.nl")!

    static var baseURL: URL {
#if DEBUG
        guard
            environment["USE_DEV_API"]?.lowercased() == "true",
            let endpoint = environment["API_BASE_URL"],
            let url = URL(string: endpoint),
            url.scheme != nil,
            url.host != nil
        else {
            return productionBaseURL
        }

        return url
#else
        return productionBaseURL
#endif
    }

    private static var environment: [String: String] {
        guard
            let resourceURL = Bundle.main.resourceURL?.appendingPathComponent(".env"),
            let contents = try? String(contentsOf: resourceURL, encoding: .utf8)
        else {
            return [:]
        }

        return contents
            .split(whereSeparator: \.isNewline)
            .reduce(into: [:]) { environment, line in
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)

                guard
                    !trimmedLine.isEmpty,
                    !trimmedLine.hasPrefix("#"),
                    let separator = trimmedLine.firstIndex(of: "=")
                else {
                    return
                }

                let key = trimmedLine[..<separator]
                    .trimmingCharacters(in: .whitespaces)
                let value = trimmedLine[trimmedLine.index(after: separator)...]
                    .trimmingCharacters(in: .whitespaces)

                guard !key.isEmpty, !value.isEmpty else {
                    return
                }

                environment[key] = value
            }
    }
}
