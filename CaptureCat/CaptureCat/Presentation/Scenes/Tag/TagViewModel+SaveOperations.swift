//
//  TagViewModel+SaveOperations.swift
//  CaptureCat
//
//  Created by AI Assistant on 1/15/25.
//

import SwiftUI
import Photos

// MARK: - Save Operations
extension TagViewModel {
    func save(isGuest: Bool) async {
        // 업로드 시작 시 초기화
        isUploading = true
        uploadProgress = 0.0
        uploadedCount = 0
        
        defer {
            // 업로드 완료 시 상태 초기화
            isUploading = false
            uploadProgress = 0.0
            uploadedCount = 0
        }
        
        if isGuest {
            // 게스트 모드: 로컬 전용 저장
            await saveToLocal()
        } else {
            // 로그인 모드: 서버 전용 저장
            await saveToServer()
        }
    }
    
    /// 로컬 전용 저장 (게스트 모드)
    private func saveToLocal() async {
            let totalItems = itemVMs.count
            for (index, viewModel) in itemVMs.enumerated() {
                // 진행률 업데이트
                let progress = Double(index + 1) / Double(totalItems)
                await MainActor.run {
                    uploadProgress = progress
                    uploadedCount = index + 1
                    debugPrint("📊 로컬 저장 진행률: \(Int(progress * 100))% (\(uploadedCount)/\(totalItems))")
                }
                
                await viewModel.saveToLocal()
            }
            debugPrint("✅ 로컬 저장 완료: \(itemVMs.count)개")
    }
    
    /// 서버 전용 저장 (로그인 모드) - ImageService 직접 사용
    private func saveToServer() async {
        await uploadToServerWithImageService(viewModels: itemVMs)
    }
    
    /// ImageService를 사용한 실제 서버 업로드
    private func uploadToServerWithImageService(viewModels: [ScreenshotItemViewModel]) async {
        var imageDatas: [Data] = []
        var imageMetas: [PhotoDTO] = []
        
        let totalItems = viewModels.count
        debugPrint("🔄 서버 업로드 시작: \(totalItems)개 아이템")
        
        // 1. 각 viewModel에서 이미지 데이터와 메타데이터 수집
        for (index, viewModel) in viewModels.enumerated() {
            // 진행률 업데이트 (데이터 수집 단계)
            let progress = Double(index) / Double(totalItems) * 0.5  // 전체의 50%까지가 데이터 수집
            await MainActor.run {
                uploadProgress = progress
                debugPrint("📊 데이터 수집 진행률: \(Int(progress * 100))%")
            }
            
            // PHAsset에서 실제 이미지 데이터 가져오기
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [viewModel.id], options: nil)
            guard let asset = assets.firstObject else {
                debugPrint("⚠️ PHAsset을 찾을 수 없음: \(viewModel.id)")
                continue
            }
            
            // 원본 이미지 데이터 가져오기
             if let imageData = await asset.requestFullImageData(compressionQuality: 0.8) {
                 imageDatas.append(imageData)
                 
                 // PhotoDTO 메타데이터 생성
                 let photoDTO = PhotoDTO(
                     id: viewModel.id,
                     fileName: viewModel.fileName,
                     createDate: viewModel.createDate,
                     tags: viewModel.tags.map { $0.name },  // ✅ ViewModel의 태그 전달
                     isFavorite: viewModel.isFavorite,
                     imageData: imageData
                 )
                 imageMetas.append(photoDTO)
                 
                 debugPrint("✅ PhotoDTO 생성 완료 - 태그: \(photoDTO.tags)")
                 debugPrint("✅ 이미지 데이터 준비 완료: \(viewModel.fileName)")
             } else {
                 debugPrint("❌ 이미지 데이터 가져오기 실패: \(viewModel.fileName)")
             }
        }
        
        // 데이터 수집 완료 (50% 진행률)
        await MainActor.run {
            uploadProgress = 0.5
            debugPrint("📊 데이터 수집 완료: 50%")
        }
        
        // 2. 수집된 데이터가 있으면 서버에 업로드
        guard !imageDatas.isEmpty && !imageMetas.isEmpty else {
            debugPrint("⚠️ 업로드할 이미지 데이터가 없습니다.")
            return
        }
        
        // 3. ImageService를 통해 실제 업로드
        for (index, meta) in imageMetas.enumerated() {
            debugPrint("🚀 - Meta[\(index)]: 태그=\(meta.tags)")
        }
        
        // 서버 업로드 시작 (50% -> 100%)
        await MainActor.run {
            uploadProgress = 0.5
            debugPrint("📊 서버 업로드 시작: 50%")
        }
        
        let result = await ImageService.shared.uploadImages(imageDatas: imageDatas, imageMetas: imageMetas)
        
                 switch result {
         case .success:
             debugPrint("✅ ImageService 서버 업로드 성공: \(imageDatas.count)개 이미지")
             
             // 업로드 성공 시 진행률 100%로 설정
             await MainActor.run {
                 uploadProgress = 1.0
                 uploadedCount = imageDatas.count
                 debugPrint("📊 서버 업로드 완료: 100% (\(uploadedCount)/\(totalItems))")
             }
             
         case .failure(let error):
             debugPrint("❌ ImageService 서버 업로드 실패: \(error.localizedDescription)")
             // 실패 시에도 진행률 초기화는 defer에서 처리됨
         }
    }
} 
