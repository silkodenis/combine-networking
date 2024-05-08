[![License](https://img.shields.io/github/license/silkodenis/combine-http-client.svg)](https://github.com/silkodenis/combine-http-client/blob/main/LICENSE)
![swift](https://github.com/silkodenis/combine-http-client/actions/workflows/swift.yml/badge.svg?branch=main)

# CombineNetworking

CombineNetworking is a robust and flexible HTTP networking library for Swift, designed to leverage the Combine framework for handling network requests in a declarative way. This package simplifies the process of making HTTP requests, decoding responses, and handling errors.

## Core Features

- **Flexible HTTP Request Configuration**: Use enums to define various network operations, simplifying the configuration of different HTTP requests.
- **Declarative Networking**: Clearly and concisely configure network operations using Swift enums and protocols.
- **Combine Integration**: Take full advantage of Swift's Combine framework for managing asynchronous network requests and handling responses.
- **Mockable HTTP Sessions**: Provides the ability to mock HTTP sessions, which is crucial for unit testing and ensuring that your application behaves as expected under various network conditions without relying on live network calls.

## Components

- **[HTTPSession](https://github.com/silkodenis/combine-http-client/blob/main/Sources/CombineNetworking/HTTPSession.swift) Protocol**: Allows for mocking of session behavior in unit tests, making it easier to test network interactions.
- **[HTTPEndpoint](https://github.com/silkodenis/combine-http-client/blob/main/Sources/CombineNetworking/HTTPEndpoint.swift) Protocol**: Facilitates the construction of different HTTP requests using a clear and concise interface.
- **[HTTPRequestBuilder](https://github.com/silkodenis/combine-http-client/blob/main/Sources/CombineNetworking/HTTPRequestBuilder.swift)**: Provides a declarative API for building URL requests from HTTPEndpoint instances.
- **[HTTPClient](https://github.com/silkodenis/combine-http-client/blob/main/Sources/CombineNetworking/HTTPClient.swift)**: Executes network requests and processes the responses, supporting generic decoding.
- **[HTTPClientError](https://github.com/silkodenis/combine-http-client/blob/main/Sources/CombineNetworking/HTTPClient.swift)**: Manages error states that can occur during the execution of HTTP requests. This enumeration helps in categorizing and handling different types of errors, such as:
  - **invalidResponse**: Indicates that the HTTP response was not valid or did not meet expected criteria, containing details about the response.
  - **decodingError**: Occurs when there is a failure in decoding the response data, providing the underlying error for more context.
  - **networkError**: Represents errors related to network connectivity issues or problems with the network request itself.

## Installation

To integrate CombineNetworking into your Xcode project using Swift Package Manager, add the following as a dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/silkodenis/combine-networking.git", from: "1.0.0")
```

And then add "CombineNetworking" to your target's dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["CombineNetworking"]
)
```
  
## Usage
Here’s how to use CombineNetworking in your project:

<details>
<summary>Define an Endpoint</summary>
    
First, define your endpoints using the HTTPEndpoint protocol:

```swift
enum Endpoint {
    case createUser
    case fetchUser(id: Int)
    case updateUser(id: Int)
    case deleteUser(id: Int)
}

extension Endpoint: HTTPEndpoint {
    var baseURL: URL {
        return URL(string: "https://api.example.com")!
    }
    
    var path: String {
        switch self {
        case .createUser:
            return "/users"
        case .fetchUser(let id), .updateUser(let id), .deleteUser(let id):
            return "/users/\(id)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .createUser:
            return .post
        case .fetchUser:
            return .get
        case .updateUser:
            return .put
        case .deleteUser:
            return .delete
        }
    }
    
    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .createUser, .updateUser:
            return ["param": "value"]  // Example parameters.
        default:
            return nil
        }
    }
}
```
</details>

<details>
<summary>Create and Execute a Request</summary>
Then, create an HTTPClient instance to execute the request:

```swift
let builder = HTTPRequestBuilder<Endpoint>(jsonEncoder: JSONEncoder())
let client = HTTPClient(jsonDecoder: JSONDecoder(), session: URLSession.shared)

func fetchUser(id: Int) -> AnyPublisher<UserDataDTO, Error> {
        builder.request(.fetchUser(id: id))
            .flatMap(client.execute)
            .eraseToAnyPublisher()
}
```

Replace `UserDataDTO` with the appropriate data model expected from the API. Ensure that this model conforms to the `Codable` protocol, which enables it to be easily decoded from JSON or encoded to JSON, depending on your needs.
</details>


<details>
<summary>Error Handling</summary>
Here's how you might call fetchUser and handle various potential errors:
  
```swift
fetchUser(id: 123)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Fetch completed successfully.")
        case .failure(let error):
            switch error {
            case let HTTPClientError.invalidResponse(details):
                print("Invalid response: Status code \(details.statusCode). Description: \(details.description ?? "No description")")
            case let HTTPClientError.decodingError(decodingError):
                print("Decoding error: \(decodingError.localizedDescription)")
            case let HTTPClientError.networkError(networkError):
                print("Network error: \(networkError.localizedDescription)")
            default:
                print("An unexpected error occurred: \(error.localizedDescription)")
            }
        }
    }, receiveValue: { userData in
        print("Received user data: \(userData)")
    })
    .store(in: &cancellables)
```

### Understanding the Errors
- **Invalid Response**: Occurs when the server's response doesn't meet the expected criteria, such as an incorrect status code or malformed headers.
- **Decoding Error**: Happens if the JSONDecoder cannot decode the response data into the expected UserDataDTO format.
- **Network Error**: Includes all errors related to connectivity issues, such as timeouts or lack of internet connection.
This approach ensures that your application can gracefully handle different error scenarios, providing a better user experience by dealing with errors appropriately.

</details>
  
<details>
<summary>Mocking HTTPSession for Testing</summary>
You can create a mock session that simulates network responses for testing. This approach is beneficial for unit tests where you want to control the inputs and outputs strictly:

```swift
struct MockSession: HTTPSession {
    func dataTask(for request: URLRequest) -> AnyPublisher<HTTPResponse, URLError> {
        return Fail(error: URLError(.notConnectedToInternet)).eraseToAnyPublisher()
    }
}

// Example of using a mock session:
let mock = HTTPClient(jsonDecoder: JSONDecoder(), session: MockSession())
let real = HTTPClient(jsonDecoder: JSONDecoder(), session: URLSession.shared)
```

</details>

## Examples
[MoviesAPI Service](https://github.com/silkodenis/combine-http-client/tree/main/Examples/MoviesAPI)

## License
This project is licensed under the [Apache License, Version 2.0](LICENSE).
