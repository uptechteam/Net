//
//  TargetBuilderTests.swift
//  NetTests
//
//  Created by Arthur Myronenko on 5/8/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import XCTest
import Net

class TargetBuilderTests: XCTestCase {

  struct TestError: DecodableError {
    let code: Int
  }

  func test_MakeGetTarget_BuildsValidTarget() {
    let encoder = URLEncoder()

    let parameters = ["a": "1", "b": "2"]
    let headers = ["Hello": "Header"]

    let builder = TargetBuilder(urlEncoder: encoder)
    let result: Target<String, TestError> = builder.makeGetTarget(
      responseType: String.self,
      path: "/hello",
      parameters: parameters,
      additionalHeaders: headers
    )

    let expectedBody = encoder.encode(parameters)
    let expectedTarget = Target<String, TestError>(
      path: "/hello",
      method: HTTPMethod.get,
      body: expectedBody,
      contentType: ContentType.urlEncoded,
      additionalHeaders: headers
    )

    XCTAssertEqual(result, expectedTarget)
  }

  func test_MakePostJSONTarget_BuildsValidTarget() {
    struct Response: Codable {
      let message: String
    }

    struct ErrorResponse: DecodableError {
      let code: Int
    }

    let encoder = JSONEncoder()
    let value = Response(message: "Hello World!")
    let headers = ["Hello": "Header"]

    let builder = TargetBuilder(jsonEncoder: encoder)
    let result: Target<Response, ErrorResponse> = builder.makePostJSONTarget(
      responseType: Response.self,
      path: "/hello",
      value: value,
      additionalHeaders: headers
    )

    let expectedBody = try? encoder.encode(value)
    let expectedTarget = Target<Response, ErrorResponse>(
      path: "/hello",
      method: HTTPMethod.post,
      body: expectedBody,
      contentType: ContentType.json,
      additionalHeaders: headers
    )

    XCTAssertEqual(result, expectedTarget)
  }
}
