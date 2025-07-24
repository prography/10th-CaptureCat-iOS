//
//  AppleLoginManager.swift
//  CaptureCat
//
//  Created by minsong kim on 7/14/25.
//

import AuthenticationServices

final class AppleLoginManager: NSObject {
    var completion: ((String, String) -> Void)?

    func login() async throws -> (String, String) {
        return try await withCheckedThrowingContinuation { continuation in
            self.completion = { token, code in
                continuation.resume(returning: (token, code))
            }
            
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
}

extension AppleLoginManager: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let credential as ASAuthorizationAppleIDCredential:
            // 🍏 Apple 로그인 정보 출력
            debugPrint("🍏 ===== Apple Login Info =====")
            
            // idToken 출력
            if let token = credential.identityToken,
               let tokenString = String(data: token, encoding: .utf8) {
                debugPrint("🍏 idToken: \(token)")
                debugPrint("🍏 idTokenString: \(tokenString)")
            }
            
            if let fullName = credential.fullName,
               let token = credential.identityToken,
               let tokenString = String(data: token, encoding: .utf8) {
                let firstName = fullName.givenName ?? ""
                let lastName = fullName.familyName ?? ""
                let fullNameString = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                completion?(tokenString, fullNameString)
            }
        default:
            break
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        debugPrint("🍏❌ Apple Login Error: \(error.localizedDescription)")
        completion?("", "")
    }
}

extension AppleLoginManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = UIApplication.shared.windows.first else {
            fatalError()
        }
        return window
    }
}
