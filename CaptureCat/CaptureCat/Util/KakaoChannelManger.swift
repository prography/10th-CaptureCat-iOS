//
//  KakaoChannelManger.swift
//  CaptureCat
//
//  Created by minsong kim on 8/14/25.
//

import KakaoSDKCommon
import SwiftUI
import KakaoSDKTalk

final class KakaoChannelManger {
    static let channelPublicId: String = "_AKjvn"
    static var safariURL: URL? = TalkApi.shared.makeUrlForChatChannel(channelPublicId: channelPublicId)
    
    static func goToChannel() {
        TalkApi.shared.chatChannel(channelPublicId: "${_AKjvn}") { /*error,*/ _ in
//          if let error = error {
//            print(error)
//          } else {
//             print("chatChannel() success.")
//            // 성공 시 동작 구현
//          }
        }
    }
    
//    static func chatChannel() {
//        TalkApi.shared.chatChannel(channelPublicId: channelPublicId) { error in
//            if let error = error {
//                print("chatChannel error:", error)
//                if let url = TalkApi.shared.makeUrlForChatChannel(channelPublicId: channelPublicId) {
//                    safariURL = url   // SFSafariViewController로 표시
//                }
//                return
//            }
//            else { print("chatChannel success") }
//        }
//    }
}
