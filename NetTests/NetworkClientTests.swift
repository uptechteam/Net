//
//  NetworkClientTests.swift
//  NetTests
//
//  Created by Arthur Myronenko on 5/8/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Net
import XCTest
import RxSwift
import RxTest

private struct Response: Codable, Equatable {
  let message: String
}

class NetworkClientTests: XCTestCase {

  private let sampleData = try! JSONEncoder().encode(Response(message: "Hello World!"))
  private let sampleTarget = TargetBuilder().makeGetTarget(responseType: Response.self, path: "/hello")
  private let sampleResponse = HTTPURLResponse(url: URL(string: "https://apple.com/hello")!, statusCode: 200, httpVersion: nil, headerFields: nil)!

  private var sut: NetworkClient!
  private var mockSession: NetSessionMock!
  private var scheduler: TestScheduler!

  override func setUp() {
    super.setUp()
    scheduler = TestScheduler(initialClock: 0)
    mockSession = NetSessionMock()
    mockSession.fireRequest_ReturnValue = Observable.just((sampleResponse, sampleData))
  }

  func initSUT(
    baseURL: URL? = nil,
    plugins: [NetworkPlugin]? = nil,
    session: NetSessionProtocol? = nil,
    jsonDecoder: JSONDecoder? = nil,
    errorParser: NetworkClient.ErrorParser? = nil,
    errorLogger: NetworkClient.ErrorLogger? = nil
    ) {
    let baseURL = baseURL ?? URL(string: "https://apple.com")!
    let plugins = plugins ?? [NetworkPlugin]()
    let session = session ?? mockSession!
    let jsonDecoder = jsonDecoder ?? JSONDecoder()
    let errorParser = errorParser ?? NetworkClient.defaultErrorParser
    let errorLogger = errorLogger ?? NetworkClient.defaultErrorLogger

    sut = NetworkClient(
      baseURL: baseURL,
      plugins: plugins,
      session: session,
      jsonDecoder: jsonDecoder,
      errorParser: errorParser,
      logger: errorLogger
    )
  }

  func test_BuildsValidRequest() {
    let target = Target<Response>(
      path: "/hello", method: .get, body: sampleData, contentType: ContentType.json, additionalHeaders: ["Hello": "Header"]
    )

    initSUT(session: mockSession)

    _ = scheduler.start { self.sut.request(target) }

    guard let builtRequest = mockSession.fireRequest_PassedArgument else {
      return XCTFail("The build request wasn't passed to the plugin")
    }

    var expectedRequest = URLRequest(url: URL(string: "https://apple.com/hello")!)
    expectedRequest.addValue("Content-Type", forHTTPHeaderField: ContentType.json.rawValue)
    expectedRequest.addValue("Header", forHTTPHeaderField: "Hello")
    XCTAssertEqual(builtRequest.debugDescription, expectedRequest.debugDescription)
  }

  func test_WithTargetWithQueryItems_BuildsValidRequest() {
    let target = Target<Response>(
      path: "/hello",
      method: .get,
      queryItems: [URLQueryItem(name: "parameter", value: "10")],
      body: sampleData,
      contentType: ContentType.json,
      additionalHeaders: ["Hello": "Header"]
    )

    initSUT(session: mockSession)

    _ = scheduler.start { self.sut.request(target) }

    guard let builtRequest = mockSession.fireRequest_PassedArgument else {
      return XCTFail("The build request wasn't passed to the plugin")
    }

    let expectedURL = URL(string: "https://apple.com/hello?parameter=10")!
    var expectedRequest = URLRequest(url: expectedURL)
    expectedRequest.addValue("Content-Type", forHTTPHeaderField: ContentType.json.rawValue)
    expectedRequest.addValue("Header", forHTTPHeaderField: "Hello")
    XCTAssertEqual(builtRequest.debugDescription, expectedRequest.debugDescription)
  }

  func test_ExecutesRequest() {
    initSUT()

    _ = scheduler.start { self.sut.request(self.sampleTarget) }

    XCTAssertTrue(mockSession.fireRequest_WasCalled)
  }

  func test_CorrectlyParsesResponse() {
    initSUT()

    let result = scheduler.start { self.sut.request(self.sampleTarget) }

    let expectedResponse = Response(message: "Hello World!")
    XCTAssertEqual(result.events, [next(200, expectedResponse), completed(200)])
  }

  func test_OnError_UsesErrorParser() {
    var errorParserWasUsed = false
    let errorParser: NetworkClient.ErrorParser = { _, _ throws -> NetworkError in
      errorParserWasUsed = true
      return NetworkError.unknown(message: "Hello There")
    }

    let mockSession = NetSessionMock()
    mockSession.fireRequest_ReturnValue = Observable.just((sampleResponse, Data()))

    initSUT(session: mockSession, errorParser: errorParser)

    let result = scheduler.start { self.sut.request(self.sampleTarget) }
    XCTAssertEqual(result.events, [error(200, NetworkError.unknown(message: "Hello There"))])
    XCTAssertTrue(errorParserWasUsed)
  }

  func test_OnErrorIfErrorParserFails_DecodesJSON() {
    let errorJSON = ["error": "hello world"]
    let data = try! JSONSerialization.data(withJSONObject: errorJSON, options: [])

    let mockSession = NetSessionMock()
    mockSession.fireRequest_ReturnValue = Observable.just((sampleResponse, data))

    initSUT(session: mockSession)

    let result = scheduler.start { self.sut.request(self.sampleTarget) }

    let expectedMessage = "\(try! JSONSerialization.jsonObject(with: data, options: []))"
    let expectedError = NetworkError.apiError(code: sampleResponse.statusCode, message: expectedMessage)
    XCTAssertEqual(result.events, [error(200, expectedError)])
  }

  func test_OnErrorIfResponseCannotBeParsed_ThrowsSerializationError() {
    let mockSession = NetSessionMock()
    mockSession.fireRequest_ReturnValue = Observable.just((sampleResponse, Data()))

    initSUT(session: mockSession)

    let result = scheduler.start { self.sut.request(self.sampleTarget) }

    let expectedErrorMessage = "Couldn't parse response: Error Domain=NSCocoaErrorDomain Code=3840 \"No value.\" UserInfo={NSDebugDescription=No value.}"
    XCTAssertEqual(result.events, [error(200, NetworkError.serializationError(message: expectedErrorMessage))])
  }

  func test_CallsPluginsMethods() {
    let mockPlugin1 = MockPlugin()
    let mockPlugin2 = MockPlugin()

    initSUT(plugins: [mockPlugin1, mockPlugin2])

    _ = scheduler.start { self.sut.request(self.sampleTarget) }

    XCTAssertTrue(mockPlugin1.modifyRequest_Called)
    XCTAssertTrue(mockPlugin2.modifyRequest_Called)

    XCTAssertFalse(mockPlugin1.tryCatchError_Called)
    XCTAssertFalse(mockPlugin2.tryCatchError_Called)

    XCTAssertTrue(mockPlugin1.handleResponse_Called)
    XCTAssertTrue(mockPlugin2.handleResponse_Called)
  }

  func test_OnError_RetiriesErrorViaPlugins() {
    let plugin = MockPlugin()
    plugin.tryCatchError_ReturnValue = Observable.error(RxError.noElements)

    let mockSession = NetSessionMock()
    mockSession.fireRequest_ReturnValue = Observable.error(RxError.unknown)

    initSUT(plugins: [plugin], session: mockSession)

    _ = scheduler.start { self.sut.request(self.sampleTarget) }

    XCTAssertTrue(plugin.tryCatchError_Called)
  }
}
