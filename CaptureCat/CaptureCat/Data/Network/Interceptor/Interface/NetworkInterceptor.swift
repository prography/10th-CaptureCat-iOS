//
//  NetworkInterceptor.swift
//  CaptureCat
//
//  Created by minsong kim on 11/17/25.
//

import UIKit

protocol NetworkInterceptor {
    func willSend<Builder: BuilderProtocol>(_ request: URLRequest, builder: Builder) async throws -> URLRequest
    
    func didReceive<Builder: BuilderProtocol>(response: HTTPURLResponse, data: Data, builder: Builder) async throws
}

extension NetworkInterceptor {
    func willSend<Builder: BuilderProtocol>(_ request: URLRequest, builder: Builder) async throws -> URLRequest {
        request
    }
    
    func didReceive<Builder: BuilderProtocol>(response: HTTPURLResponse, data: Data, builder: Builder) async throws {}
}
