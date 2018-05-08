//
//  NetSessionProtocol.swift
//  Net
//
//  Created by Arthur Myronenko on 5/8/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public protocol NetSessionProtocol {
  func fire(request: URLRequest) -> Observable<(response: HTTPURLResponse, data: Data)>
}

extension URLSession: NetSessionProtocol {
  public func fire(request: URLRequest) -> Observable<(response: HTTPURLResponse, data: Data)> {
    return rx.response(request: request)
  }
}
