/*
 * Copyright (c) [2024] [Denis Silko]
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import Combine

public enum HTTPClientError: Error {
    case invalidResponse(Details)
    case decodingError(Error)
    case networkError(Error)
    
    public struct Details {
        public let statusCode: Int
        public let url: URL?
        public let description: String?
        public let headers: [String: String]?
    }
}

public final class AppHTTPClient: HTTPClient {
    let decoder: JSONDecoder
    let session: HTTPSession
    
    public init(jsonDecoder: JSONDecoder, session: HTTPSession) {
        self.decoder = jsonDecoder
        self.session = session
    }
    
    public func execute<T: Decodable>(_ request: URLRequest) -> AnyPublisher<T, Error> {
        return session
            .dataTask(for: request)
            .tryMap { data, response in
                try Self.validateHTTPResponse(response, for: request)
                return data
            }
            .decode(type: T.self, decoder: decoder)
            .mapError(Self.mapHTTPError)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Error handling

fileprivate extension AppHTTPClient {
    private static func validateHTTPResponse(_ response: URLResponse, for request: URLRequest) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPClientError.invalidResponse(HTTPClientError.Details(
                statusCode: -1,
                url: request.url,
                description: "Invalid response type",
                headers: nil
            ))
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw HTTPClientError.invalidResponse(HTTPClientError.Details(
                statusCode: httpResponse.statusCode,
                url: request.url,
                description: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode),
                headers: httpResponse.allHeaderFields as? [String: String]
            ))
        }
    }

    private static func mapHTTPError(_ error: Error) -> HTTPClientError {
        switch error {
        case let httpClientError as HTTPClientError:
            return httpClientError
        case let decodingError as DecodingError:
            return HTTPClientError.decodingError(decodingError)
        default:
            return HTTPClientError.networkError(error)
        }
    }
}
