# Clean Architecture

This package follows Clean Architecture with three layers. Dependencies flow **Presentation → Domain → Data**. The **Network Layer** lives inside the package and is used by the Data layer.

## Layers

### 1. Presentation Layer

- **View**: `TweetComposerView`, `CharacterCounterView`, `TweetComposerColors`
- **ViewModel**: `TweetComposerViewModel` (state holder, holds an instance of the Use Case)
- **Flow**: View binds to ViewModel; ViewModel calls Use Case for business actions (e.g. post tweet).

### 2. Domain Layer

- **Use Case**: `PostTweetUseCase` — depends on repository protocol, runs business logic (post tweet).
- **Repositories (protocols)**: `TwitterPosting` — abstract contract for posting a tweet.
- **Entities**: `Tweet` — domain model (id, text).

### 3. Data Layer

- **Service (Network Layer)**: `NetworkClient` uses `APIConfiguration` and performs HTTP requests.
- **Repo Implementation**: `TwitterAPIRepository` conforms to `TwitterPosting`, uses `NetworkClient` and `TwitterAuthenticating`.
- **DTOs**: `PostTweetRequestDTO`, `PostTweetResponseDTO` — API request/response shapes.
- **Mappers**: `TweetMapper` — maps DTOs to domain `Tweet` entity.

### Network Layer (used by Data)

- **APIConfiguration** / **DefaultAPIConfiguration** — base URL, default headers, timeout.
- **APIEndPoint** — path, HTTP method, parameters, headers.
- **HTTPMethod** — GET, POST, PUT, DELETE.
- **NetworkError** — URL, decoding, HTTP status, timeout, etc.
- **APIResponse** — generic wrapper `{ data, message, success }` (optional).
- **NetworkClient** / **NetworkClientProtocol** — executes requests and decodes responses.

## Dependency Flow

```
Presentation (ViewModel) → Domain (Use Case) → Domain (Repo protocol)
                                                ↑
Data (Repo implementation) → Network Layer (NetworkClient)
```

## Wiring (example)

Using the **Network Layer** and **Clean Architecture**:

```swift
// 1. Network Layer
let config = TwitterAPIConfiguration.default()
let networkClient = NetworkClient(configuration: config)

// 2. Data: Repository (implements Domain protocol)
let authManager = TwitterAuthManager(credentials: credentials)
let twitterRepo = TwitterAPIRepository(networkClient: networkClient, authManager: authManager)

// 3. Domain: Use Case (depends on repo protocol)
let postTweetUseCase = PostTweetUseCase(twitterPosting: twitterRepo)

// 4. Presentation: ViewModel (holds Use Case)
let calculator = TweetLengthCalculator()
let validator = TweetValidator(calculator: calculator)
let viewModel = TweetComposerViewModel(
    calculator: calculator,
    validator: validator,
    postTweetUseCase: postTweetUseCase
)

// 5. View
TweetComposerView(viewModel: viewModel)
```

Backward compatibility: you can still inject any `TwitterPosting` (e.g. legacy `TwitterAPIClient`); the ViewModel builds `PostTweetUseCase` internally.
