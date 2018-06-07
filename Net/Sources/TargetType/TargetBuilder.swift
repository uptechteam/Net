//
//  TargetBuilder.swift
//  Net
//
//  Created by Arthur Myronenko on 5/8/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation

public final class TargetBuilder {

  private let jsonEncoder: JSONEncoder
  private let urlEncoder: URLEncoder

  public init(jsonEncoder: JSONEncoder = .init(), urlEncoder: URLEncoder = URLEncoder()) {
    self.jsonEncoder = jsonEncoder
    self.urlEncoder = urlEncoder
  }

  public func makeGetTarget<Response>(
    responseType: Response.Type = Response.self,
    path: String,
    parameters: [String: String] = [:],
    additionalHeaders: [String: String] = [:]
    ) -> Target<Response> {
    return Target(
      path: path,
      method: .get,
      queryItems: parameters.map { URLQueryItem(name: $0.key, value: $0.value) },
      bodyProvider: { self.urlEncoder.encode(parameters) },
      contentType: Net.ContentType.urlEncoded,
      additionalHeaders: additionalHeaders
    )
  }

  public func makePostJSONTarget<Value: Encodable, Response>(
    responseType: Response.Type = Response.self,
    path: String,
    value: Value,
    additionalHeaders: [String: String] = [:]
    ) -> Target<Response> {
    return Target(
      path: path,
      method: .post,
      queryItems: [],
      bodyProvider: { try self.jsonEncoder.encode(value) },
      contentType: Net.ContentType.json,
      additionalHeaders: additionalHeaders
    )
  }
}
