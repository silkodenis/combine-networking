[![License](https://img.shields.io/github/license/silkodenis/combine-http-client.svg)](https://github.com/silkodenis/combine-http-client/blob/main/LICENSE)
![swift](https://github.com/silkodenis/combine-http-client/actions/workflows/swift.yml/badge.svg?branch=main)

# CombineNetworking

CombineNetworking is a robust and flexible HTTP networking library for Swift, designed to leverage the Combine framework for handling network requests in a declarative way. This package simplifies the process of making HTTP requests, decoding responses, and handling errors.

## Features

### Core Features
- **Flexible HTTP Request Configuration**: Use enums to define various network operations, simplifying the configuration of different HTTP requests.
- **Declarative Networking**: Clearly and concisely configure network operations using Swift enums and protocols.
- **Combine Integration**: Take full advantage of Swift's Combine framework for managing asynchronous network requests and handling responses.

### Specific Components
- **HTTPSession Protocol**: Allows for mocking of session behavior in unit tests, making it easier to test network interactions.
- **HTTPEndpoint Protocol**: Facilitates the construction of different HTTP requests using a clear and concise interface.
- **HTTPRequestBuilder**: Provides a declarative API for building URL requests from HTTPEndpoint instances.
- **HTTPClient**: Executes network requests and processes the responses, supporting generic decoding.

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

### Define an Endpoint
First, define your endpoints using the HTTPEndpoint protocol:

```swift
public enum Endpoint {
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

### Create and Execute a Request
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




