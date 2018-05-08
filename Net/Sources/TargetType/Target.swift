//
//  Target.swift
//  Net
//
//  Created by Arthur Myronenko on 5/8/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation

public struct Target<Response: Decodable>: TargetType {

  public typealias BodyProvider = () throws -> Data?

  public let path: String
  public let method: HTTPMethod
  public let bodyProvider: BodyProvider
  public let contentType: ContentType?
  public let additionalHeaders: [String: String]

  public init(
    path: String,
    method: HTTPMethod,
    bodyProvider: @escaping BodyProvider = { nil },
    contentType: ContentType? = nil,
    additionalHeaders: [String: String] = [:]
    ) {
    self.path = path
    self.method = method
    self.bodyProvider = bodyProvider
    self.contentType = contentType
    self.additionalHeaders = additionalHeaders
  }

  public init(
    path: String,
    method: Net.HTTPMethod,
    body: Data? = nil,
    contentType: Net.ContentType? = .urlEncoded,
    additionalHeaders: [String: String] = [:]
    ) {
    self.init(path: path, method: method, bodyProvider: { body }, contentType: contentType, additionalHeaders: additionalHeaders)
  }

  public func getBodyData() throws -> Data? {
    return try bodyProvider()
  }
}
