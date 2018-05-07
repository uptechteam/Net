//
//  NetworkPlugin.swift
//  Net
//
//  Created by Arthur Myronenko on 1/29/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation
import RxSwift

public protocol NetworkPlugin {
  func modifyRequest(_ urlRequest: URLRequest) -> URLRequest
  func tryCatchError(_ error: Error) -> Observable<Void>
  func handleResponse(_ response: NetworkResponse)
}

public extension NetworkPlugin {
  func modifyRequest(_ urlRequest: URLRequest) -> URLRequest {
    return urlRequest
  }

  func tryCatchError(_ error: Error) -> Observable<Void> {
    return Observable.just(Void())
  }

  func handleResponse(_ response: NetworkResponse) { }
}
