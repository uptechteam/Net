//
//  NetworkPlugin.swift
//  Strimmerz
//
//  Created by Arthur Myronenko on 1/29/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation

public protocol NetworkPlugin {
  func modifyRequest(_ urlRequest: URLRequest) -> URLRequest
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

  public func modifyResponse(_ response: NetworkResponse) -> NetworkResponse {
    return plugins.reduce(response) { response, plugin in plugin.modifyResponse(response) }
  }
}
