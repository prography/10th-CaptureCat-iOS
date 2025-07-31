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
            // 로그인 모드: 낙관적 업데이트 적용
            await optimisticSaveToServer()
        }
    }
    
    /// 낙관적 업데이트로 서버 저장 (즉시 로컬 업데이트 + 백그라운드 서버 동기화)
    private func optimisticSaveToServer() async {
        // 1️⃣ 즉시 로컬 상태 업데이트 (낙관적 업데이트)
        await updateLocalStateOptimistically()
        
        // 2️⃣ 백그라운드에서 서버 업로드 시작
        Task.detached { [weak self] in
            await self?.performServerUploadInBackground()
        }
        
        // 즉시 완료로 처리 (사용자는 즉시 결과를 봄)
        await MainActor.run {
            uploadProgress = 1.0
            uploadedCount = itemVMs.count
            debugPrint("✅ 낙관적 업데이트 완료 - 백그라운드에서 서버 동기화 진행 중")
        }
    }
    
    /// 로컬 상태를 즉시 업데이트 (낙관적 업데이트)
    private func updateLocalStateOptimistically() async {
        let totalItems = itemVMs.count
        
        for (index, viewModel) in itemVMs.enumerated() {
            // 진행률 업데이트
            let progress = Double(index + 1) / Double(totalItems)
            await MainActor.run {
                uploadProgress = progress * 0.5  // 로컬 업데이트는 50%까지
                uploadedCount = index + 1
                debugPrint("📊 낙관적 로컬 업데이트 진행률: \(Int(progress * 50))% (\(uploadedCount)/\(totalItems))")
            }
            
            // 즉시 로컬에 저장 (사용자가 즉시 볼 수 있도록)
            await viewModel.saveToLocal()
            
            // 홈뷰에서 사용할 수 있도록 NotificationCenter로 즉시 알림
            NotificationCenter.default.post(name: .optimisticUpdateCompleted, object: nil)
        }
        
        debugPrint("✅ 낙관적 로컬 업데이트 완료: \(itemVMs.count)개")
    }
    
    /// 백그라운드에서 실제 서버 업로드 수행
    private func performServerUploadInBackground() async {
        debugPrint("🚀 백그라운드 서버 업로드 시작")
        
        // 롤백을 위한 원본 상태 백업
        let originalStates = await backupOriginalStates()
        
        do {
            // 실제 서버 업로드
            await uploadToServerWithImageService(viewModels: itemVMs)
            debugPrint("✅ 백그라운드 서버 업로드 성공")
            
            // 성공 시 로컬 임시 데이터 정리 (필요한 경우)
            await cleanupTemporaryData()
            
        } catch {
            debugPrint("❌ 백그라운드 서버 업로드 실패: \(error.localizedDescription)")
            
            // 실패 시 롤백
            await rollbackOptimisticUpdate(originalStates: originalStates)
            
            // 사용자에게 실패 알림
            await MainActor.run {
                // Toast나 알림을 통해 사용자에게 알림
                NotificationCenter.default.post(
                    name: .serverSyncFailed, 
                    object: nil, 
                    userInfo: ["error": error.localizedDescription]
                )
            }
        }
    }
    
    /// 원본 상태 백업 (롤백용)
    private func backupOriginalStates() async -> [String: (tags: [Tag], isFavorite: Bool)] {
        var backup: [String: (tags: [Tag], isFavorite: Bool)] = [:]
        
        for viewModel in itemVMs {
            // SwiftData에서 원본 상태 가져오기
            if let originalItem = SwiftDataManager.shared.fetchEntity(id: viewModel.id) {
                backup[viewModel.id] = (
                    tags: originalItem.tags.enumerated().map { index, name in Tag(id: index, name: name) },
                    isFavorite: originalItem.isFavorite
                )
            }
        }
        
        return backup
    }
    
    /// 낙관적 업데이트 롤백
    private func rollbackOptimisticUpdate(originalStates: [String: (tags: [Tag], isFavorite: Bool)]) async {
        debugPrint("🔄 낙관적 업데이트 롤백 시작")
        
        for viewModel in itemVMs {
            if let originalState = originalStates[viewModel.id] {
                await MainActor.run {
                    viewModel.tags = originalState.tags
                    viewModel.isFavorite = originalState.isFavorite
                }
                
                // 로컬 데이터도 원복
                await viewModel.saveToLocal()
            }
        }
        
        debugPrint("✅ 낙관적 업데이트 롤백 완료")
    }
    
    /// 임시 데이터 정리
    private func cleanupTemporaryData() async {
        // 필요한 경우 임시 파일이나 중복 데이터 정리
        debugPrint("🧹 임시 데이터 정리 완료")
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
