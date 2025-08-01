//
//  PermissionViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 8/1/25.
//

import SwiftUI
import Photos

final class PermissionViewModel: ObservableObject {
    @Published var showPermissionAlert = false
    @Published var permissionGranted = false
    
    func checkPhotoPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async {
                    self?.handle(status: newStatus)
                }
            }
        default:
            handle(status: status)
        }
    }
    
    private func handle(status: PHAuthorizationStatus) {
        switch status {
        case .authorized, .limited:
            MixpanelManager.shared.trackStartStorage()
            permissionGranted = true
        case .denied, .restricted:
            showPermissionAlert = true
        default:
            break
        }
    }
    
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
