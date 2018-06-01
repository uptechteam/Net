//
//  TargetType.swift
//  Net
//
//  Created by Arthur Myronenko on 1/29/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation

public typealias DecodableError = Decodable & Error

public protocol TargetType {
  associatedtype Response: Decodable
  associatedtype ErrorResponse: DecodableError

  var path: String { get }
  var method: HTTPMethod { get }
  var contentType: ContentType? { get }
  var additionalHeaders: [String: String] { get }
  func getBodyData() throws -> Data?
}
