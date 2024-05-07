//
//  AppHTTPClient.swift
//
//  Created by Denis Silko on 30.04.2024.
//

import XCTest
import Combine

final class AppHTTPClientTests: XCTestCase {
    
    func testInvalidHTTPResponseStatus() throws {
        struct MockURLSession: HTTPSession {
            func dataTask(for request: URLRequest) -> AnyPublisher<HTTPResponse, URLError> {
                let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
                return Result.Publisher((data: Data(), response: response)).eraseToAnyPublisher()
            }
        }

        let sut = AppHTTPClient(jsonDecoder: JSONDecoder(), session: MockURLSession())
        let requestURL = URL(string: "https://example.com")!
        let request = URLRequest(url: requestURL)
        let expectation = XCTestExpectation(description: "Invalid response status test")

        let cancellable = sut.execute(request)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    if let httpClientError = error as? HTTPClientError,
                       case .invalidResponse(let details) = httpClientError {
                        XCTAssertEqual(details.statusCode, 404, "Expected status code 404")
                        XCTAssertEqual(details.url, requestURL, "Expected URL to match request URL")
                        XCTAssertNotNil(details.description, "Expected description to be non-nil")
                        XCTAssertEqual(details.headers?["Content-Type"], "application/json", "Expected correct content type header")
                        
                        expectation.fulfill()
                    } else {
                        XCTFail("Expected HTTPClientError.invalidResponse with status code 404")
                    }
                } else {
                    XCTFail("Expected failure due to invalid response status, but got success")
                }
            }, receiveValue: { (_: Data) in
                XCTFail("Expected failure due to invalid response status, but received data")
            })

        wait(for: [expectation], timeout: 5.0)
        cancellable.cancel()
    }

    func testSuccessfulDataFetch() throws {
        struct MockData: Codable, Equatable {
            let id: Int
            let name: String
        }

        struct MockSession: HTTPSession {
            let responseData: Data

            func dataTask(for request: URLRequest) -> AnyPublisher<HTTPResponse, URLError> {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return Result.Publisher((data: responseData, response: response)).eraseToAnyPublisher()
            }
        }

        let mockData = MockData(id: 1, name: "Test")
        let mockSession = MockSession(responseData: try! JSONEncoder().encode(mockData))
        let sut = AppHTTPClient(jsonDecoder: JSONDecoder(), session: mockSession)
        let request = URLRequest(url: URL(string: "https://example.com")!)
        let expectation = XCTestExpectation(description: "Successful data fetch")

        let cancellable = sut.execute(request)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("Request failed when success was expected")
                }
            }, receiveValue: { (decodedData: MockData) in
                XCTAssertEqual(decodedData, mockData)
                expectation.fulfill()
            })

        wait(for: [expectation], timeout: 5.0)
        cancellable.cancel()
    }

    func testNetworkErrorHandling() throws {
        struct MockSession: HTTPSession {
            func dataTask(for request: URLRequest) -> AnyPublisher<HTTPResponse, URLError> {
                return Fail(error: URLError(.notConnectedToInternet)).eraseToAnyPublisher()
            }
        }

        let sut = AppHTTPClient(jsonDecoder: JSONDecoder(), session: MockSession())
        let request = URLRequest(url: URL(string: "https://example.com")!)
        let expectation = XCTestExpectation(description: "Network error handling test")

        let cancellable = sut.execute(request)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion, let httpClientError = error as? HTTPClientError, 
                    case .networkError(let error) = httpClientError {
                    let urlError = error as? URLError
                    XCTAssertEqual(urlError?.code, .notConnectedToInternet)
                    expectation.fulfill()
                } else {
                    XCTFail("Expected HTTPClientError.networkError with URLError.notConnectedToInternet")
                }
            }, receiveValue: { (_: String) in
                XCTFail("Expected failure due to network error, but received data")
            })

        wait(for: [expectation], timeout: 5.0)
        cancellable.cancel()
    }
    
    func testInvalidJSONDecoding() throws {
        struct MockSession: HTTPSession {
            func dataTask(for request: URLRequest) -> AnyPublisher<HTTPResponse, URLError> {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let invalidJSONData = "invalid-json".data(using: .utf8)!
                return Result.Publisher((data: invalidJSONData, response: response)).eraseToAnyPublisher()
            }
        }

        let sut = AppHTTPClient(jsonDecoder: JSONDecoder(), session: MockSession())
        let request = URLRequest(url: URL(string: "https://example.com")!)
        let expectation = XCTestExpectation(description: "Invalid JSON decoding test")

        let cancellable = sut.execute(request)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected failure due to invalid JSON, but got success")
                }
            }, receiveValue: { (_: String) in
                XCTFail("Expected decoding failure, but received data")
            })

        wait(for: [expectation], timeout: 5.0)
        cancellable.cancel()
    }
    
    func testEmptyResponseBody() throws {
        struct MockSession: HTTPSession {
            func dataTask(for request: URLRequest) -> AnyPublisher<HTTPResponse, URLError> {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return Result.Publisher((data: Data(), response: response)).eraseToAnyPublisher()
            }
        }

        let sut = AppHTTPClient(jsonDecoder: JSONDecoder(), session: MockSession())
        let request = URLRequest(url: URL(string: "https://example.com")!)
        let expectation = XCTestExpectation(description: "Empty response body test")

        let cancellable = sut.execute(request)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected failure due to empty response body, but got success")
                }
            }, receiveValue: { (_: String) in
                XCTFail("Expected decoding failure due to empty body, but received data")
            })

        wait(for: [expectation], timeout: 5.0)
        cancellable.cancel()
    }
}
