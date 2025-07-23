//
//  TagViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import SwiftUI
import Photos

@MainActor
/// 한 번에(Batch) 혹은 한 장씩(Single) 모드에서 태그 편집을 담당하는 ViewModel
final class TagViewModel: ObservableObject {
    enum Mode: Int {
        case batch = 0    // 한 번에
        case single = 1   // 한 장씩
    }
    
    // MARK: - Published Properties
    @Published var hasChanges: Bool = false
    @Published var mode: Mode = .batch
    @Published var isShowingAddTagSheet: Bool = false
    let segments = ["한번에", "한장씩"]
    
    @Published var tags: [String] = []
    @Published var selectedTags: Set<String> = []
    var batchSelectedTags: Set<String> = []
    
    @Published var currentIndex: Int = 0
    
    // MARK: - Dependencies
    private let repository = ScreenshotRepository.shared
    @Published var itemVMs: [ScreenshotItemViewModel] = []
    private var networkManager: NetworkManager
    
    init(itemsIds: [String], networkManager: NetworkManager) {
        self.networkManager = networkManager
        createViewModel(from: itemsIds)
        
        loadTags()
        updateSelectedTags()
    }
    
    // 배열을 받아서 대응하는 ScreenshotItemViewModel들을 생성
    func createViewModel(from ids: [String]) {
        let results =  PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        results.enumerateObjects { asset, _, _ in
            let newItem = ScreenshotItem(
                id: asset.localIdentifier,
                imageData: Data(),
                fileName: asset.localIdentifier + ".jpg",
                createDate: asset.creationDate ?? Date(),
                tags: [],
                isFavorite: false
            )
            self.itemVMs.append( (ScreenshotItemViewModel(model: newItem)))
        }
    }
    
    // MARK: - Computed for UI
    /// 현재 화면에 표시할 ViewModel (batch: 첫 번째, single: currentIndex)
    var displayVM: ScreenshotItemViewModel? {
        switch mode {
        case .batch:
            return itemVMs.first
        case .single:
            guard currentIndex < itemVMs.count else { return nil }
            return itemVMs[currentIndex]
        }
    }
    
    /// 진행률 텍스트 ("1/5" 등)
    var progressText: String {
        guard !itemVMs.isEmpty else { return "0/0" }
        let idx = min(currentIndex, itemVMs.count - 1)
        return "\(idx + 1)/\(itemVMs.count)"
    }
    
    // MARK: - Tag Loading
    /// 전체 태그 목록을 로컬/서버에서 가져와 tags에 세팅
    func loadTags() {
        tags = UserDefaults.standard.stringArray(forKey: LocalUserKeys.selectedTopics.rawValue) ?? []
    }
    
    // mode 변경이나 asset 변경 시 호출해서 selectedTags 초기화
    func updateSelectedTags() {
        switch mode {
        case .batch:
            selectedTags = batchSelectedTags
        case .single:
            selectedTags = Set(itemVMs[currentIndex].tags)
        }
        hasChanges = true
    }
    
    // MARK: - Mode & Navigation
    /// 세그먼트 모드 변경 시 호출
    func onModeChanged() {
        if mode == .batch {
            mode = .single
        } else {
            mode = .batch
        }
        //        currentIndex = 0
        updateSelectedTags()
    }
    
    // Carousel 등에서 index 변경 시 호출
    func onAssetChanged(to index: Int) {
        currentIndex = index
        updateSelectedTags()
    }
    
    // MARK: - User Actions
    func addTagButtonTapped() {
        withAnimation {
            self.isShowingAddTagSheet = true
        }
    }
    // 태그 선택/해제
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            switch mode {
            case .batch:
                batchSelectedTags.remove(tag)
                itemVMs.forEach { $0.removeTag(tag) }
            case .single:
                itemVMs[currentIndex].removeTag(tag)
            }
            selectedTags.remove(tag)
        } else if selectedTags.count < 4 {
            switch mode {
            case .batch:
                itemVMs.forEach { $0.addTag(tag) }
                batchSelectedTags.insert(tag)
            case .single:
                itemVMs[currentIndex].addTag(tag)
            }
            selectedTags.insert(tag)
        }
        hasChanges = true
        updateSelectedTags()
    }
    
    // 새 태그 추가
    func addNewTag(name: String) {
        guard !tags.contains(name) else { return }
        tags.append(name)
        itemVMs[currentIndex].addTag(name)
        updateSelectedTags()
    }
    
    // 저장 (batch: all items, single: current)
    func save() async {
        if AccountStorage.shared.isGuest ?? true {
            // 게스트 모드: 로컬 전용 저장
            await saveToLocal()
        } else {
            // 로그인 모드: 서버 전용 저장
            await saveToServer()
        }
    }
    
    /// 로컬 전용 저장 (게스트 모드)
    private func saveToLocal() async {
        switch mode {
        case .batch:
            for viewModel in itemVMs {
                await viewModel.saveToLocal()
            }
            debugPrint("✅ 배치 모드 로컬 저장 완료: \(itemVMs.count)개")
            
        case .single:
            if let viewModel = displayVM {
                await viewModel.saveToLocal()
                debugPrint("✅ 단일 모드 로컬 저장 완료")
            }
        }
    }
    
    /// 서버 전용 저장 (로그인 모드) - ImageService 직접 사용
    private func saveToServer() async {
        switch mode {
        case .batch:
            // 배치 모드: 모든 아이템을 한번에 업로드
            await uploadToServerWithImageService(viewModels: itemVMs)
            
        case .single:
            // 단일 모드: 현재 아이템만 업로드
            if let viewModel = displayVM {
                await uploadToServerWithImageService(viewModels: [viewModel])
            }
        }
    }
    
    /// ImageService를 사용한 실제 서버 업로드
    private func uploadToServerWithImageService(viewModels: [ScreenshotItemViewModel]) async {
        var imageDatas: [Data] = []
        var imageMetas: [PhotoDTO] = []
        
        debugPrint("🔄 서버 업로드 시작: \(viewModels.count)개 아이템")
        
        // 1. 각 viewModel에서 이미지 데이터와 메타데이터 수집
        for viewModel in viewModels {
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
                 debugPrint("🔧 PhotoDTO 생성 중:")
                 debugPrint("🔧 - ID: \(viewModel.id)")
                 debugPrint("🔧 - 파일명: \(viewModel.fileName)")
                 debugPrint("🔧 - 태그: \(viewModel.tags) (개수: \(viewModel.tags.count))")
                 
                 let photoDTO = PhotoDTO(
                     id: viewModel.id,
                     fileName: viewModel.fileName,
                     createDate: viewModel.createDate,
                     tags: viewModel.tags,  // ✅ ViewModel의 태그 전달
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
        
        // 2. 수집된 데이터가 있으면 서버에 업로드
        guard !imageDatas.isEmpty && !imageMetas.isEmpty else {
            debugPrint("⚠️ 업로드할 이미지 데이터가 없습니다.")
            return
        }
        
        // 3. ImageService를 통해 실제 업로드
        debugPrint("🚀 ImageService 업로드 시작:")
        debugPrint("🚀 - 이미지 개수: \(imageDatas.count)")
        debugPrint("🚀 - 메타데이터 개수: \(imageMetas.count)")
        for (index, meta) in imageMetas.enumerated() {
            debugPrint("🚀 - Meta[\(index)]: 태그=\(meta.tags)")
        }
        
        let result = await ImageService.shared.uploadImages(imageDatas: imageDatas, imageMetas: imageMetas)
        
                 switch result {
         case .success:
             debugPrint("✅ ImageService 서버 업로드 성공: \(imageDatas.count)개 이미지")
             
             // 4. 성공시 메모리 캐시에 저장 (InMemoryScreenshotCache 없이 처리)
             for viewModel in viewModels {
                 // 로컬 저장은 하지 않고 업로드만 성공했다고 로그
                 debugPrint("✅ 업로드 완료: \(viewModel.fileName)")
             }
             
         case .failure(let error):
             debugPrint("❌ ImageService 서버 업로드 실패: \(error.localizedDescription)")
         }
    }
}
