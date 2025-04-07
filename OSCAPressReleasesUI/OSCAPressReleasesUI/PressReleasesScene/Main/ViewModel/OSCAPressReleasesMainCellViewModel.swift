//
//  OSCAPressReleasesMainCellViewModel.swift
//  OSCAPressReleasesUI
//
//  Created by Mammut Nithammer on 19.01.22.
//  Reviewed by Stephan Breidenbach on 21.06.22
//

import Combine
import Foundation
import OSCAPressReleases

public final class OSCAPressReleasesMainCellViewModel {
  var category: String = ""
  var title: String = ""
  var contentInfo: String = ""
  
  var pressRelease: OSCAPressRelease
  private let dataModule: OSCAPressReleases
  private var bindings = Set<AnyCancellable>()
  
  // MARK: Initializer
  
  public init(dataModule: OSCAPressReleases,
              pressRelease: OSCAPressRelease) {
    self.pressRelease = pressRelease
    self.dataModule = dataModule
    
    self.setup()
  }
  
  // MARK: - OUTPUT
  
  @Published private(set) var imageData: Data? = nil
  
  /**
   Use this to get access to the __Bundle__ delivered from this module's configuration parameter __externalBundle__.
   - Returns: The __Bundle__ given to this module's configuration parameter __externalBundle__. If __externalBundle__ is __nil__, The module's own __Bundle__ is returned instead.
   */
  var bundle: Bundle = {
    if let bundle = OSCAPressReleasesUI.configuration.externalBundle {
      return bundle
    }
    else { return OSCAPressReleasesUI.bundle }
  }()
  
  var imageDataFromCache: Data? {
    guard let objectId = pressRelease.objectId else { return nil }
    let imageData = self.dataModule.dataCache
      .object(forKey: NSString(string: objectId))
    return imageData as Data?
  }
  
  // MARK: - Private
  
  private func setup() {
    category = pressRelease.category ?? ""
    title = pressRelease.title ?? ""
    contentInfo = "\(pressRelease.date?.toString ?? "")"
    
    if OSCAPressReleasesUI.configuration.showReadingTime {
      let readingTime = NSLocalizedString(
        "press_releases_press_release_reading_time",
        bundle: self.bundle,
        comment: "The reading time needed to finish a press release")
      contentInfo = "\(contentInfo) - \(pressRelease.readingTime ?? 0) \(readingTime)"
    }
  }
  
  private func fetchImage(from url: String) {
    var modifiedURL = url
    
    guard let objectId = pressRelease.objectId,
          let fileName = url.components(separatedBy: "/").last,
          var mimeType = fileName.components(separatedBy: ".").last
    else { return }
    
    mimeType = "." + mimeType
    modifiedURL.removeLast(fileName.count)
    guard let baseURL = URL(string: modifiedURL) else { return }
    let publisher: OSCAPressReleases.ImageDataPublisher = dataModule
      .getPressReleasesImage(objectId: objectId,
                             baseURL: baseURL,
                             fileName: fileName.replacingOccurrences(of: mimeType, with: ""),
                             mimeType: mimeType)
    publisher.sink { completion in
      switch completion {
      case let .failure(error):
        print(error)
      default: return
      }
    } receiveValue: { pressReleaseImageData in
      guard let imageData = pressReleaseImageData.imageData,
            let objectId = self.pressRelease.objectId
      else { return }
      
      self.dataModule.dataCache.setObject(
        NSData(data: imageData),
        forKey: NSString(string: objectId))
      self.imageData = imageData
      
    }
    .store(in: &self.bindings)
  }
}

// MARK: - INPUT. View event methods

extension OSCAPressReleasesMainCellViewModel {
  func fill() {
    if self.imageDataFromCache == nil {
      guard let url = self.pressRelease.imageUrl,
            let _ = URL(string: url)
      else { return }
      
      self.fetchImage(from: url)
      
    } else {
      self.imageData = self.imageDataFromCache
    }
  }
}
