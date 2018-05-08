//
//  MockPlugin.swift
//  NetTests
//
//  Created by Arthur Myronenko on 5/8/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Net
import RxSwift

final class MockPlugin: NetworkPlugin {

  var modifyRequest_Called = false
  var modifyRequest_PassedArgument: URLRequest?
  var modifyRequest_ReturnValue: URLRequest?
  func modifyRequest(_ urlRequest: URLRequest) -> URLRequest {
    modifyRequest_Called = true
    modifyRequest_PassedArgument = urlRequest
    return modifyRequest_ReturnValue ?? urlRequest
  }

  var tryCatchError_Called = false
  var tryCatchError_PassedArgument: Error?
  var tryCatchError_ReturnValue: Observable<Void>?
  func tryCatchError(_ error: Error) -> Observable<Void> {
    tryCatchError_Called = true
    tryCatchError_PassedArgument = error
    return tryCatchError_ReturnValue ?? Observable.just(Void())
  }

  var handleResponse_Called = false
  var handleResponse_PassedArgument: NetworkResponse?
  func handleResponse(_ response: NetworkResponse) {
    handleResponse_Called = true
    handleResponse_PassedArgument = response
  }
}
