//
//  CompositePluginTests.swift
//  NetTests
//
//  Created by Arthur Myronenko on 5/8/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import XCTest
@testable import Net
import RxSwift
import RxTest

class CompositePluginTests: XCTestCase {

  func test_ModifyRequest() {
    let plugin1 = MockPlugin()
    let plugin2 = MockPlugin()
    let composite = CompositePlugin(plugins: [plugin1, plugin2])
    let request = URLRequest(url: URL(string: "https://apple.com")!)

    _ = composite.modifyRequest(request)

    XCTAssertTrue(plugin1.modifyRequest_Called)
    XCTAssertTrue(plugin2.modifyRequest_Called)
  }

  func test_HandleResponse() {
    let plugin1 = MockPlugin()
    let plugin2 = MockPlugin()
    let composite = CompositePlugin(plugins: [plugin1, plugin2])
    let response = NetworkResponse(statusCode: 200, data: Data())

    _ = composite.handleResponse(response)

    XCTAssertTrue(plugin1.handleResponse_Called)
    XCTAssertTrue(plugin2.handleResponse_Called)
  }

  func test_TryCatchError_CallsEveryPlugin() {
    let plugin1 = MockPlugin()
    let plugin2 = MockPlugin()
    let composite = CompositePlugin(plugins: [plugin1, plugin2])
    let networkError = NetworkError.unknown(message: "Test Error Message")
    let scheduler = TestScheduler(initialClock: 0)

    let result = scheduler.start { composite.tryCatchError(networkError).map { _ in true } }

    XCTAssertEqual(result.events, [error(200, networkError)])
    XCTAssertTrue(plugin1.tryCatchError_Called)
    XCTAssertTrue(plugin2.tryCatchError_Called)
  }

  func test_TryCatchError_StopsIfErrorIsCaught() {
    let plugin1 = MockPlugin()
    plugin1.tryCatchError_ReturnValue = Observable.just(Void())
    let plugin2 = MockPlugin()
    let composite = CompositePlugin(plugins: [plugin1, plugin2])
    let networkError = NetworkError.unknown(message: "Test Error Message")
    let scheduler = TestScheduler(initialClock: 0)

    let result = scheduler.start { composite.tryCatchError(networkError).map { _ in true } }

    XCTAssertEqual(result.events, [next(200, true), completed(200)])
    XCTAssertTrue(plugin1.tryCatchError_Called)
    XCTAssertFalse(plugin2.tryCatchError_Called)
  }
}
