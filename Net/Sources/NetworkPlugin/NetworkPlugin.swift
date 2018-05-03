//
//  NetworkPlugin.swift
//  Strimmerz
//
//  Created by Arthur Myronenko on 1/29/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation

protocol NetworkPlugin {
  func modifyRequest(_ urlRequest: URLRequest) -> URLRequest
  func modifyResponse(_ response: NetworkResponse) -> NetworkResponse
}

final class CompositePlugin {
  private let plugins: [NetworkPlugin]

  init(plugins: [NetworkPlugin]) {
    self.plugins = plugins
  }

  func modifyRequest(_ urlRequest: URLRequest) -> URLRequest {
    return plugins.reduce(urlRequest) { request, plugin in plugin.modifyRequest(request) }
  }

  func modifyResponse(_ response: NetworkResponse) -> NetworkResponse {
    return plugins.reduce(response) { response, plugin in plugin.modifyResponse(response) }
  }
}
