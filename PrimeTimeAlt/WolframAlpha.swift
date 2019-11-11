import Foundation
import Combine

private let wolframAlphaApiKey = "6H69Q3-828TKQJ4EP"

struct WolframAlphaResult: Decodable {
    let queryresult: QueryResult

    struct QueryResult: Decodable {
        let pods: [Pod]

        struct Pod: Decodable {
            let primary: Bool?
            let subpods: [SubPod]

            struct SubPod: Decodable {
                let plaintext: String
            }
        }
    }
}

func nthPrime(_ count: Int) -> AnyPublisher<Int?, Never> {
    wolframAlpha(query: "prime \(count)")
        .map { $0.flatMap(getNumber) }
        .eraseToAnyPublisher()
}

func wolframAlpha(query: String) -> AnyPublisher<WolframAlphaResult?, Never> {
    var components = URLComponents(string: "https://api.wolframalpha.com/v2/query")!
    components.queryItems = [
        URLQueryItem(name: "input", value: query),
        URLQueryItem(name: "format", value: "plaintext"),
        URLQueryItem(name: "output", value: "JSON"),
        URLQueryItem(name: "appid", value: wolframAlphaApiKey),
    ]

    let url = components.url(relativeTo: nil)!

    return URLSession.shared.dataTaskPublisher(for: url)
        .map(\.data)
        .decode(type: WolframAlphaResult?.self, decoder: JSONDecoder())
        .replaceError(with: nil)
        .eraseToAnyPublisher()
}

func getNumber(_ result: WolframAlphaResult) -> Int? {
    let plainText = result
        .queryresult
        .pods
        .first(where: { $0.primary == .some(true) })?
        .subpods
        .first?
        .plaintext
    return plainText.flatMap(Int.init)
}
