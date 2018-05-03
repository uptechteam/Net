//
//  TargetType.swift
//  Strimmerz
//
//  Created by Arthur Myronenko on 1/29/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation

public protocol TargetType {
  associatedtype Response: Decodable

  var path: String { get }
  var method: HTTPMethod { get }
  var contentType: ContentType? { get }
  func getBodyData() throws -> Data?
}
