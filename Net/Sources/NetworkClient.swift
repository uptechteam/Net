//
//  NetworkClient.swift
//  Net
//
//  Created by Arthur Myronenko on 1/29/18.
//  Copyright © 2018 UPTech Team. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public protocol NetworkClientProtocol {
  func request<T: TargetType>(_ target: T) -> Observable<T.Response>
}

public class NetworkClient: NetworkClientProtocol {

  public typealias ErrorParser = (JSONDecoder, NetworkResponse) throws -> NetworkError
  public typealias ErrorLogger = (String) -> Void

  public static let defaultErrorParser: ErrorParser = { decoder, response -> NetworkError in
    let errorResponse = try decoder.decode(DefaultErrorResponse.self, from: response.data)
    return NetworkError.apiError(code: response.statusCode, message: errorResponse.errorDescription)
  }

  public static let defaultErrorLogger: ErrorLogger = { print($0) }

  private let baseURL: URL
  private let plugin: CompositePlugin
  private let session: URLSession
  private let errorParser: ErrorParser
  private let log: ErrorLogger

  public init(
    baseURL: URL,
    plugins: [NetworkPlugin] = [],
    session: URLSession = URLSession(configuration: URLSessionConfiguration.default),
    errorParser: @escaping ErrorParser = defaultErrorParser,
    logger: @escaping ErrorLogger = defaultErrorLogger
    ) {
    self.baseURL = baseURL
    self.plugin = CompositePlugin(plugins: plugins)
    self.session = session
    self.errorParser = errorParser
    self.log = logger
  }

  public func request<T: TargetType>(_ target: T) -> Observable<T.Response> {
    return buildRequest(from: target)
      .flatMapLatest { [weak self] request -> Observable<NetworkResponse> in
        guard let `self` = self else { return Observable.empty() }
        return self.executeRequest(request)
      }
      .do(onNext: { [weak self] in self?.plugin.handleResponse($0) })
      .flatMapLatest { [weak self] response -> Observable<T.Response> in
        guard let `self` = self else { return Observable.empty() }
        return self.parseObject(T.Response.self, from: response)
      }
      .retryWhen { [weak self] errors -> Observable<Void> in
        guard let `self` = self else { return Observable.empty() }
        return errors.flatMapLatest(self.plugin.tryCatchError)
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
      target.additionalHeaders.forEach { key, value in request.setValue(value, forHTTPHeaderField: key) }
      request.httpBody = try target.getBodyData()
      let modifiedRequest = self.plugin.modifyRequest(request)
      return Observable.just(modifiedRequest)
      }.catchError { error in Observable.error(NetworkError.serializationError(message: "\(error)")) }
  }

  /// Executes request
  ///
  /// - Parameter request: `URLRequest` to execute.
  /// - Returns: `SignalProducer` with a received `Response`. All errors are mapped into `NetworkError.unknown`.
  private func executeRequest(_ request: URLRequest) -> Observable<NetworkResponse> {
    return session.rx.response(request: request)
      .catchError { error in Observable.error(NetworkError.unknown(message: "\(error)")) }
      .map { (response, data) throws -> (HTTPURLResponse, Data) in
        if response.statusCode == 401 {
          throw NetworkError.unathorized
        }

        return (response, data)
      }
      .map { response, data in NetworkResponse(statusCode: response.statusCode, data: data) }
  }

  private func parseObject<Object: Decodable>(_ objectType: Object.Type, from response: NetworkResponse) -> Observable<Object> {
    let decoder = JSONDecoder()
    do {
      let parsedObject = try decoder.decode(Object.self, from: response.data)
      return Observable.just(parsedObject)
    } catch {
      self.log("Couldn't parse model: \(error)")
      let parsedError = self.tryParseError(from: response)
      return Observable.error(parsedError)
    }
  }

  /// Tries to parse response as `ErrorResponse`.
  ///
  /// - Parameter response: `Response` object to parse.
  /// - Returns: `apiError` if could parse error from `response` or status code is unsuccessfull,
  /// `serializationError` if status code is successfull,
  private func tryParseError(from response: NetworkResponse) -> NetworkError {
      let decoder = JSONDecoder()
      do {
        return try errorParser(decoder, response)
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
