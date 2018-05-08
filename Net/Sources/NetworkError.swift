//
//  NetworkError.swift
//  Net
//
//  Created by Arthur Myronenko on 1/29/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation

public enum NetworkError: Error, Equatable {
  case serializationError(message: String)
  case apiError(code: Int, message: String)
  case unathorized
  case unknown(message: String)
}

extension NetworkError: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .serializationError(message):
      return "Serialization: \(message)"
    case let .apiError(_, message):
      return "\(message)"
    case .unathorized:
      return "Unathorized"
    case let .unknown(message):
      return "Unknown: \(message)"
    }
  }
}
