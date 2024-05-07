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

public final class HTTPRequestBuilder<T: HTTPEndpoint> {
    private let jsonEncoder: JSONEncoder
    
    internal init(jsonEncoder: JSONEncoder) {
        self.jsonEncoder = jsonEncoder
    }

    public func request(_ endpoint: T, with data: Codable? = nil) -> AnyPublisher<URLRequest, Error> {
        do {
            let request = try buildRequest(for: endpoint, with: data)
            return Just(request)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
    
    private func buildRequest(for endpoint: T, with data: Codable? = nil) throws -> URLRequest {
        let url = endpoint.baseURL.appendingPathComponent(endpoint.path)
        
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)?
                .addingQueryItems(endpoint.parameters), let finalURL = urlComponents.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers

        if let data = data {
            request.httpBody = try jsonEncoder.encode(data)
        }

        return request
    }
}

// MARK: - URLComponents

fileprivate extension URLComponents {
    func addingQueryItems(_ queryItems: [String: Any]?) -> URLComponents {
        var copy = self
        copy.queryItems = queryItems?.compactMap { key, value in
            if let value = value as? CustomStringConvertible {
                return URLQueryItem(name: key, value: value.description)
            }
            
            return nil
        }
        
        return copy
    }
}
