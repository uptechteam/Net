//
//  CompositePlugin.swift
//  Net
//
//  Created by Arthur Myronenko on 5/7/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation
import RxSwift

internal final class CompositePlugin: NetworkPlugin {
  private let plugins: [NetworkPlugin]

  public init(plugins: [NetworkPlugin]) {
    self.plugins = plugins
  }

  public func modifyRequest(_ urlRequest: URLRequest) -> URLRequest {
    return plugins.reduce(urlRequest) { request, plugin in plugin.modifyRequest(request) }
  }

  public func tryCatchError(_ error: Error) -> Observable<Void> {
    return plugins
      .reduce(Observable.error(error)) { (result: Observable<Void>, plugin: NetworkPlugin) -> Observable<Void> in
        return result.catchError(plugin.tryCatchError)
      }
  }

  public func handleResponse(_ response: NetworkResponse) {
    plugins.forEach { $0.handleResponse(response) }
  }
}
