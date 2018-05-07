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
  func modifyResponse(_ response: NetworkResponse) -> NetworkResponse
}

public final class CompositePlugin: NetworkPlugin {
  private let plugins: [NetworkPlugin]

  public init(plugins: [NetworkPlugin]) {
    self.plugins = plugins
  }

  public func modifyRequest(_ urlRequest: URLRequest) -> URLRequest {
    return plugins.reduce(urlRequest) { request, plugin in plugin.modifyRequest(request) }
  }

  public func tryCatchError(_ error: Error) -> Observable<Void> {
    return plugins
      .reduce(Observable.just(error)) { (result: Observable<Error>, plugin: NetworkPlugin) -> Observable<Error> in
        return result.flatMapLatest(plugin.tryCatchError).map { error }
      }
      .map { _ in Void() }
  }

  public func modifyResponse(_ response: NetworkResponse) -> NetworkResponse {
    return plugins.reduce(response) { response, plugin in plugin.modifyResponse(response) }
  }
}
