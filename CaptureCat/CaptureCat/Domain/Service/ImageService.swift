//
//  ImageService.swift
//  CaptureCat
//
//  Created by minsong kim on 7/17/25.
//

import Foundation

final class ImageService {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func uploadImages(imageDatas: [Data], imageMetas: [ImageMetaDTO]) async -> Result<ResponseDTO, NetworkError> {
        let builder = UploadImageBuilder(imageDatas: imageDatas, imageMetas: imageMetas)
        
        do {
            let response = try await networkManager.fetchData(builder)
            debugPrint("✅ Success: 이미지 파일들 업로드 성공!")
            return Result<ResponseDTO, NetworkError>.success(response)
        } catch(let error) {
            debugPrint("🔥 Error:\(error)")
            return .failure(NetworkError.unauthorized)
        }
    }
}

// Service/ScreenshotService.swift

import Foundation

struct PhotoDTO: Codable, Identifiable {
  let id: String
  var fileName: String
  var createDate: Date
  var tags: [String]
  var isFavorite: Bool
  var imageData: Data?
}

final class ScreenshotService {
  static let shared = ScreenshotService()
  private let base = URL(string: "https://api.capture-cat.com/v1")!
  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  private init() {
    decoder.dateDecodingStrategy = .iso8601
    encoder.dateEncodingStrategy = .iso8601
  }

  // MARK: Screenshot CRUD

  func fetchAll() async throws -> [PhotoDTO] {
    let url = base.appendingPathComponent("images")
    var req = URLRequest(url: url)
    req.httpMethod = "GET"
    let (data, _) = try await URLSession.shared.data(for: req)
    return try decoder.decode([PhotoDTO].self, from: data)
  }

  func upload(_ dto: PhotoDTO) async throws -> PhotoDTO {
    let url = base.appendingPathComponent("images")
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try encoder.encode(dto)
    let (data, _) = try await URLSession.shared.data(for: req)
    return try decoder.decode(PhotoDTO.self, from: data)
  }

  func delete(id: String) async throws {
    let url = base.appendingPathComponent("images/\(id)")
    var req = URLRequest(url: url)
    req.httpMethod = "DELETE"
    _ = try await URLSession.shared.data(for: req)
  }

  // MARK: Tag Endpoints

  /// 전체 태그 조회
  func fetchAllTags() async throws -> [String] {
    let url = base.appendingPathComponent("tags")
    var req = URLRequest(url: url)
    req.httpMethod = "GET"
    let (data, _) = try await URLSession.shared.data(for: req)
    return try decoder.decode([String].self, from: data)
  }

  /// 일괄 태그 추가
  func addTag(_ tag: String, toIDs ids: [String]) async throws {
    let url = base.appendingPathComponent("tags/add")
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body = ["tag": tag, "ids": ids] as [String: Any]
    req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    _ = try await URLSession.shared.data(for: req)
  }

  /// 일괄 태그 삭제
  func removeTag(_ tag: String, fromIDs ids: [String]) async throws {
    let url = base.appendingPathComponent("tags/remove")
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body = ["tag": tag, "ids": ids] as [String: Any]
    req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    _ = try await URLSession.shared.data(for: req)
  }

  /// 태그 이름 변경
  func renameTag(from oldName: String, to newName: String) async throws {
    let url = base.appendingPathComponent("tags/rename")
    var req = URLRequest(url: url)
    req.httpMethod = "PUT"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body = ["oldName": oldName, "newName": newName]
    req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    _ = try await URLSession.shared.data(for: req)
  }
}
