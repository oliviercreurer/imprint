import Foundation

/// Handles all communication with the Hardcover GraphQL API.
///
/// Provides async methods for searching books and fetching book details
/// including editions for cover selection. Rate-limited to 60 req/min.
final class HardcoverService: Sendable {

    static let shared = HardcoverService()

    private let endpoint = URL(string: "https://api.hardcover.app/v1/graphql")!

    // MARK: - API Token

    /// Bearer token from https://hardcover.app/account/api
    private let apiToken = "eyJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJIYXJkY292ZXIiLCJ2ZXJzaW9uIjoiOCIsImp0aSI6IjRmNWM1NWNjLTBhZjAtNGUxOS1iOTZkLTQ2OTU3NDJmMThkNiIsImFwcGxpY2F0aW9uSWQiOjIsInN1YiI6IjgwMjcyIiwiYXVkIjoiMSIsImlkIjoiODAyNzIiLCJsb2dnZWRJbiI6dHJ1ZSwiaWF0IjoxNzcyMzkzOTI2LCJleHAiOjE4MDM5Mjk5MjYsImh0dHBzOi8vaGFzdXJhLmlvL2p3dC9jbGFpbXMiOnsieC1oYXN1cmEtYWxsb3dlZC1yb2xlcyI6WyJ1c2VyIl0sIngtaGFzdXJhLWRlZmF1bHQtcm9sZSI6InVzZXIiLCJ4LWhhc3VyYS1yb2xlIjoidXNlciIsIlgtaGFzdXJhLXVzZXItaWQiOiI4MDI3MiJ9LCJ1c2VyIjp7ImlkIjo4MDI3Mn19.tnitjSMC7O8TZl_Rkx8C5rsDJ7NPA2tFeqP1_F96oJg"

    private init() {}

    // MARK: - Search

    /// Search for books matching the given query string.
    ///
    /// Returns up to 20 results from the Typesense search index.
    /// Note: `search.results` is a raw Typesense JSON blob, not typed GraphQL.
    func searchBooks(query: String) async throws -> [HCSearchDocument] {
        let graphQL = """
        {
          search(
            query: "\(query.graphQLEscaped)",
            query_type: "books",
            per_page: 20,
            page: 1
          ) {
            results
          }
        }
        """

        let response: HCGraphQLResponse<HCSearchData> = try await execute(query: graphQL)
        return response.data.search.results.hits?.map(\.document) ?? []
    }

    // MARK: - Book Details

    /// Fetch full details for a book by its Hardcover ID, including editions.
    func getBookDetails(id: Int) async throws -> HCBook? {
        let graphQL = """
        {
          books_by_pk(id: \(id)) {
            id
            title
            slug
            description
            pages
            release_date
            cached_image
            cached_contributors
            cached_tags
            image {
              url
            }
            editions {
              id
              cached_image
              title
              image {
                url
              }
            }
          }
        }
        """

        let response: HCGraphQLResponse<HCBookDetailData> = try await execute(query: graphQL)
        return response.data.booksByPk
    }

    // MARK: - GraphQL Execution

    /// Sends a GraphQL query to the Hardcover API and decodes the response.
    private func execute<T: Decodable>(query: String) async throws -> T {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = ["query": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            if !(200...299).contains(httpResponse.statusCode) {
                if let body = String(data: data, encoding: .utf8) {
                    print("❌ Hardcover HTTP \(httpResponse.statusCode): \(body.prefix(500))")
                }
                throw HardcoverError.httpError(statusCode: httpResponse.statusCode)
            }
        }

        #if DEBUG
        if let raw = String(data: data, encoding: .utf8) {
            print("📡 Hardcover response (\(data.count) bytes): \(raw.prefix(1000))")
        }
        #endif

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ Hardcover decode error: \(error)")
            throw error
        }
    }
}

// MARK: - Errors

enum HardcoverError: LocalizedError {
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .httpError(let code):
            "Hardcover API error (HTTP \(code))"
        }
    }
}

// MARK: - String Helpers

private extension String {
    /// Escapes characters that are special in a GraphQL string literal.
    var graphQLEscaped: String {
        self.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
