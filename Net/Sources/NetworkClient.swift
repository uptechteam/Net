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

open class NetworkClient: NetworkClientProtocol {

  public typealias ErrorLogger = (String) -> Void
  public static let defaultErrorLogger: ErrorLogger = { print($0) }

  private let baseURL: URL
  private let plugin: CompositePlugin
  private let session: NetSessionProtocol
  private let jsonDecoder: JSONDecoder
  private let log: ErrorLogger

  public init(
    baseURL: URL,
    plugins: [NetworkPlugin] = [],
    session: NetSessionProtocol = URLSession.shared,
    jsonDecoder: JSONDecoder = JSONDecoder(),
    logger: @escaping ErrorLogger = defaultErrorLogger
    ) {
    self.baseURL = baseURL
    self.plugin = CompositePlugin(plugins: plugins)
    self.session = session
    self.jsonDecoder = jsonDecoder
    self.log = logger
  }

  public func request<T: TargetType>(_ target: T) -> Observable<T.Response> {
    return buildRequest(from: target)
      .flatMapLatest { [weak self] request -> Observable<NetworkResponse> in
        guard let `self` = self else { return Observable.empty() }
        return self.executeRequest(targetType: T.self, request)
      }
      .do(onNext: { [weak self] in self?.plugin.handleResponse($0) })
      .flatMapLatest { [weak self] response -> Observable<T.Response> in
        guard let `self` = self else { return Observable.empty() }
        return self.parseObject(T.self, from: response)
      }
      .retryWhen { [weak self] errors -> Observable<Void> in
        guard let `self` = self else { return Observable.empty() }
        return errors.flatMapLatest(self.plugin.tryCatchError)
      }
  }

  /// Builds a `URLRequest` by provided `TargetType`.
  ///
  /// - Parameter target: `TargetType` that is used to build the request.
  /// - Returns: `Observable` that emits a request or `serializationError`.
  private func buildRequest<T: TargetType>(from target: T) -> Observable<URLRequest> {
    return Observable.deferred { [weak self] () -> Observable<URLRequest> in
      guard let `self` = self else { return .empty() }

      guard var urlComponents = URLComponents(url: self.baseURL.appendingPathComponent(target.path), resolvingAgainstBaseURL: false) else {
        throw NetworkError<T.ErrorResponse>.url(
          message: "Couldn't create the URLComponents from a base URL '\(self.baseURL)' and a path component '\(target.path)'"
        )
      }

      if !target.queryItems.isEmpty {
        urlComponents.queryItems = target.queryItems
      }

      guard let fullURL = urlComponents.url else {
        throw NetworkError<T.ErrorResponse>.url(message: "Couldn't create an url from: \(urlComponents)")
      }

      var request = URLRequest(url: fullURL)
      request.httpMethod = target.method.rawValue
      request.setValue(target.contentType?.rawValue, forHTTPHeaderField: "Content-Type")
      target.additionalHeaders.forEach { key, value in request.setValue(value, forHTTPHeaderField: key) }
      request.httpBody = try target.getBodyData()
      let modifiedRequest = self.plugin.modifyRequest(request)
      return Observable.just(modifiedRequest)
      }.catchError { error in Observable.error(NetworkError<T.ErrorResponse>.serializationError(message: "\(error)")) }
  }

  /// Executes the request
  ///
  /// - Parameter request: `URLRequest` to execute.
  /// - Returns: `Observable` with a fetched `Response`. All errors are mapped into `NetworkError.unknown`.
  private func executeRequest<T: TargetType>(targetType: T.Type = T.self, _ request: URLRequest) -> Observable<NetworkResponse> {
    return session.fire(request: request)
      .catchError { error in Observable.error(NetworkError<T.ErrorResponse>.sessionError(message: error.localizedDescription)) }
      .map { (response, data) in NetworkResponse(statusCode: response.statusCode, data: data) }
  }

  /// Parses object into the `Object.Type`.
  ///
  /// - Parameters:
  ///   - objectType: `Decodable` type of the object to parse the response.
  ///   - response: `NetworkResponse` to parse the object.
  /// - Returns: `Observable` of the `Object`. If `Object` couldn't be created tries to parse the error.
  private func parseObject<T: TargetType>(_ targetType: T.Type, from response: NetworkResponse) -> Observable<T.Response> {
    do {
      let parsedObject = try self.jsonDecoder.decode(T.Response.self, from: response.data)
      return Observable.just(parsedObject)
    } catch {
      self.log("Couldn't parse model: \(error)")
      let parsedError = self.tryParseError(errorType: T.ErrorResponse.self, from: response)
      return Observable.error(parsedError)
    }
  }

  /// Tries to parse response using provided error parser.
  ///
  /// - Parameter response: `Response` object to parse.
  /// - Returns: `apiError` if could parse error from `response` or status code is unsuccessfull,
  /// `serializationError` if status code is successfull,
  private func tryParseError<E: DecodableError>(errorType: E.Type = E.self, from response: NetworkResponse) -> NetworkError<E> {
      do {
        let apiErroResponse = try jsonDecoder.decode(E.self, from: response.data)
        return NetworkError.apiError(apiErroResponse)
      } catch {
        log("Couldn't init ErrorResponse from response. Will try to parse generic JSON from response")
      }

      do {
        let responseJSON = try JSONSerialization.jsonObject(with: response.data, options: [])
        return NetworkError.serializationError(message: "\(responseJSON)")
      } catch {
        log("Couldn't init any JSON object from response.")
        switch response.statusCode {
        case 200, 201:
          return NetworkError.serializationError(message: "Couldn't parse response: \(error)")
        default:
          return NetworkError.unknown(response)
        }
      }
  }
}
