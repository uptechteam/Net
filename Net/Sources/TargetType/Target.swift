//
//  Target.swift
//  Net
//
//  Created by Arthur Myronenko on 5/8/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation

public struct Target<Response: Decodable, ErrorResponse: DecodableError>: TargetType, Equatable {

  public typealias BodyProvider = () throws -> Data?

  public let path: String
  public let queryItems: [URLQueryItem]
  public let method: HTTPMethod
  public let bodyProvider: BodyProvider
  public let contentType: ContentType?
  public let additionalHeaders: [String: String]

  public init(
    path: String,
    method: HTTPMethod,
    queryItems: [URLQueryItem],
    bodyProvider: @escaping BodyProvider = { nil },
    contentType: ContentType? = nil,
    additionalHeaders: [String: String] = [:]
    ) {
    self.path = path
    self.method = method
    self.queryItems = queryItems
    self.bodyProvider = bodyProvider
    self.contentType = contentType
    self.additionalHeaders = additionalHeaders
  }

  public init(
    path: String,
    method: Net.HTTPMethod,
    queryItems: [URLQueryItem] = [],
    body: Data? = nil,
    contentType: Net.ContentType? = .urlEncoded,
    additionalHeaders: [String: String] = [:]
    ) {
    self.init(
      path: path,
      method: method,
      queryItems: queryItems,
      bodyProvider: { body },
      contentType: contentType,
      additionalHeaders: additionalHeaders
    )
  }

  public func getBodyData() throws -> Data? {
    return try bodyProvider()
  }
}

extension Target {
  public static func == <Response>(lhs: Target<Response, ErrorResponse>, rhs: Target<Response, ErrorResponse>) -> Bool {
    let lhsBody = try? lhs.bodyProvider()
    let rhsBody = try? rhs.bodyProvider()

    return lhs.path == rhs.path
      && lhs.method == rhs.method
      && lhs.contentType == rhs.contentType
      && lhs.additionalHeaders == rhs.additionalHeaders
      && lhsBody == rhsBody
  }
}
