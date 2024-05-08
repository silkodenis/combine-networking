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

/// A protocol that defines the interface for HTTP sessions.
/// This abstraction is useful for testing, as it allows the real network session
/// to be replaced with a mock in tests.
///```swift
/// struct MockSession: HTTPSession {
///     func dataTask(for request: URLRequest) -> AnyPublisher<HTTPResponse, URLError> {
///         return Fail(error: URLError(.notConnectedToInternet)).eraseToAnyPublisher()
///     }
/// }
///
/// let mock = HTTPClient(jsonDecoder: JSONDecoder(), session: MockSession())
/// let real = HTTPClient(jsonDecoder: JSONDecoder(), session: URLSession.shared)
///```
public protocol HTTPSession {
    typealias HTTPResponse = URLSession.DataTaskPublisher.Output

    func dataTask(for request: URLRequest) -> AnyPublisher<HTTPResponse, URLError>
}

/// Extension of URLSession that conforms to the `HTTPSession` protocol.
/// This allows the standard URLSession to be used as part of our abstracted HTTP client.
extension URLSession: HTTPSession {
    /// Implements `dataTask` using `dataTaskPublisher` from `URLSession` to create a publisher.
    /// The publisher is then erased to `AnyPublisher` to hide implementation details and
    /// ensure conformance to the `HTTPSession` protocol. This simplification allows
    /// the replacement of the implementation in tests, where a mock version of `HTTPSession`
    /// can be used to control the behavior of network requests and responses.
    public func dataTask(for request: URLRequest) -> AnyPublisher<HTTPResponse, URLError> {
        return dataTaskPublisher(for: request).eraseToAnyPublisher()
    }
}

