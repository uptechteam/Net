//
//  NetworkClient.swift
//  Strimmerz
//
//  Created by Arthur Myronenko on 1/29/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol NetworkClientProtocol {
  func request<T: TargetType>(_ target: T) -> Observable<T.Response>
}

class NetworkClient<ErrorResponse>: NetworkClientProtocol where ErrorResponse: Decodable & CustomStringConvertible {

  typealias ErrorLogger = (String) -> Void

  private let baseURL: URL
  private let plugin: CompositePlugin
  private let session: URLSession
  private let errorResponseType: ErrorResponse.Type
  private let log: ErrorLogger

  private struct Response {
    let data: Data
    let statusCode: Int
  }

  init(
    baseURL: URL,
    plugins: [NetworkPlugin] = [],
    session: URLSession = URLSession(configuration: URLSessionConfiguration.default),
    errorResponseType: ErrorResponse.Type,
    logger: @escaping ErrorLogger = { print($0) }
    ) {
    self.baseURL = baseURL
    self.plugin = CompositePlugin(plugins: plugins)
    self.session = session
    self.errorResponseType = errorResponseType
    self.log = logger
  }

  func request<T: TargetType>(_ target: T) -> Observable<T.Response> {
    return buildRequest(from: target)
      .flatMapLatest { [weak self] request -> Observable<Response> in
        guard let `self` = self else { return Observable.empty() }
        return self.executeRequest(request)
      }
      .flatMapLatest { [weak self] response -> Observable<T.Response> in
        guard let `self` = self else { return Observable.empty() }
        let decoder = JSONDecoder()
        do {
          let parsedObject = try decoder.decode(T.Response.self, from: response.data)
          return Observable.just(parsedObject)
        } catch {
          self.log("Couldn't parse model: \(error)")
          let parsedError = self.tryParseError(from: response)
          return Observable.error(parsedError)
        }
      }
  }

  /// Builds a `URLRequest` by provided `TargetType`.
  ///
  /// - Parameter target: `TargetType` that is used to build the request.
  /// - Returns: `SignalProducer` that emits a request or `serializationError`.
  private func buildRequest<T: TargetType>(from target: T) -> Observable<URLRequest> {
    return Observable.deferred { [weak self] () -> Observable<URLRequest> in
      guard let `self` = self else { return .empty() }
      let fullURL = self.baseURL.appendingPathComponent(target.path)
      var request = URLRequest(url: fullURL)
      request.httpMethod = target.method.rawValue
      request.setValue(target.contentType?.rawValue, forHTTPHeaderField: "Content-Type")
      request.httpBody = try target.getBodyData()
      let modifiedRequest = self.plugin.modifyRequest(request)
      return Observable.just(modifiedRequest)
      }.catchError { error in Observable.error(NetworkError.serializationError(message: "\(error)")) }
  }

  /// Executes request
  ///
  /// - Parameter request: `URLRequest` to execute.
  /// - Returns: `SignalProducer` with a received `Response`. All errors are mapped into `NetworkError.unknown`.
  private func executeRequest(_ request: URLRequest) -> Observable<Response> {
    return session.rx.response(request: request)
      .map { response, data in Response(data: data, statusCode: response.statusCode) }
      .catchError { error in Observable.error(NetworkError.unknown(message: "\(error)")) }
  }


  /// Tries to parse response as `ErrorResponse`.
  ///
  /// - Parameter response: `Response` object to parse.
  /// - Returns: `apiError` if could parse error from `response` or status code is unsuccessfull,
  /// `serializationError` if status code is successfull,
  private func tryParseError(from response: Response) -> NetworkError {
      let decoder = JSONDecoder()
      do {
        let errorResponse = try decoder.decode(errorResponseType, from: response.data)
        return NetworkError.apiError(code: response.statusCode, message: errorResponse.description)
      } catch {
        log("Couldn't init ErrorResponse from response. Will try to parse generic JSON from response")
      }

      do {
        let responseJSON = try JSONSerialization.jsonObject(with: response.data, options: [])
        return NetworkError.apiError(code: response.statusCode, message: "\(responseJSON)")
      } catch {
        log("Couldn't init any JSON object from response.")
        switch response.statusCode {
        case 200, 201:
          return NetworkError.serializationError(message: "Couldn't parse response: \(error)")
        default:
          return NetworkError.apiError(code: response.statusCode, message: "\(error)")
        }
      }
  }
}
