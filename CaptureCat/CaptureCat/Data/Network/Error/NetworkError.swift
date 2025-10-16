//
//  NetworkError.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import Foundation

enum NetworkError: Error {
    case urlNotFound
    case badRequest
    case unauthorized
    case forBidden
    case responseNotFound
    case tooManyRequests
    case internalServerError
    case unknown(Int)
    case serverError(String) // 서버에서 제공하는 구체적인 에러 메시지
    
    var localizedDescription: String {
        switch self {
        case .urlNotFound:
            return "요청 주소를 찾을 수 없습니다"
        case .badRequest:
            return "잘못된 요청입니다"
        case .unauthorized:
            return "인증이 필요합니다"
        case .forBidden:
            return "접근 권한이 없습니다"
        case .responseNotFound:
            return "서버 응답을 받을 수 없습니다"
        case .tooManyRequests:
            return "요청이 너무 많습니다. 잠시 후 다시 시도해주세요"
        case .internalServerError:
            return "서버 내부 오류가 발생했습니다"
        case .unknown(let code):
            return "알 수 없는 오류가 발생했습니다 (코드: \(code))"
        case .serverError(let message):
            return message
        }
    }
    
    // 태그 관련 특화 에러 메시지
    var tagErrorMessage: String {
        switch self {
        case .badRequest:
            return "이미 존재하는 태그입니다."
        case .unauthorized:
            return "로그인이 필요합니다"
        case .forBidden:
            return "태그 생성 권한이 없습니다"
        case .tooManyRequests:
            return "태그 생성 요청이 너무 많습니다. 잠시 후 다시 시도해주세요"
        case .internalServerError:
            return "태그 저장 중 오류가 발생했습니다"
        case .responseNotFound:
            return "태그를 불러올 수 없습니다"
        case .serverError(let message):
            return message
        default:
            return "태그 처리 중 오류가 발생했습니다"
        }
    }
}
