//
//  NetSessionMock.swift
//  NetTests
//
//  Created by Arthur Myronenko on 5/8/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Net
import RxSwift

final class NetSessionMock: NetSessionProtocol {

  var fireRequest_WasCalled = false
  var fireRequest_PassedArgument: (URLRequest)?
  var fireRequest_ReturnValue: Observable<(response: HTTPURLResponse, data: Data)> = .empty()

  func fire(request: URLRequest) -> Observable<(response: HTTPURLResponse, data: Data)> {
    fireRequest_WasCalled = true
    fireRequest_PassedArgument = request
    return fireRequest_ReturnValue
  }
}
