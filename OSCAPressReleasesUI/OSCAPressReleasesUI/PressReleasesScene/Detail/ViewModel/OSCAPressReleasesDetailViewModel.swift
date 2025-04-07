//
//  OSCAPressReleasesDetailViewModel.swift
//  OSCAPressReleasesUI
//
//  Created by Mammut Nithammer on 19.01.22.
//

import OSCAEssentials
import OSCAPressReleases
import Foundation
import Combine

public class OSCAPressReleasesDetailViewModel {
  
  private let dataModule: OSCAPressReleases
  public var pressRelease: OSCAPressRelease
  public var objectId: String? = nil
  public var category: String = ""
  public var title: String = ""
  public var url: String = ""
  public var contentInfo: String = ""
  public var content: String = ""
  
  private var bindings = Set<AnyCancellable>()
  
  // MARK: Initializer
  public init(dataModule: OSCAPressReleases, pressRelease: OSCAPressRelease) {
    self.dataModule = dataModule
    self.pressRelease = pressRelease
    self.objectId = pressRelease.objectId
    self.category = pressRelease.category ?? ""
    self.title = pressRelease.title ?? ""
    self.url = pressRelease.url ?? ""
    
    self.contentInfo = "\(pressRelease.date?.toString ?? "")"
    if OSCAPressReleasesUI.configuration.showReadingTime {
      let readingTime = NSLocalizedString("press_releases_press_release_reading_time",
                                          bundle: self.bundle,
                                          comment: "The reading time needed to finish a press release")
      contentInfo = "\(contentInfo) - \(pressRelease.readingTime ?? 0) \(readingTime)"
    }
    
    self.content = pressRelease.content ?? ""
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
  
  public var imageDataFromCache: Data? {
    guard let objectId = self.objectId else { return nil }
    let imageData = self.dataModule.dataCache
      .object(forKey: NSString(string: objectId))
    return imageData as Data?
  }
  
  var appStoreURL: URL? { self.dataModule.appStoreURL }
  
  // MARK: Localized Strings
  
  var appStoreForwardingTitle: String { NSLocalizedString(
    "press_releases_app_store_forwarding_title",
    bundle: self.bundle,
    comment: "The title to forward to the app store") }
  
  // MARK: Private
  
  private func fetchImage(from url: String) {
    var modifiedURL = url
    
    guard let objectId = self.objectId,
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
      guard let imageData = pressReleaseImageData.imageData
      else { return }
      
      self.dataModule.dataCache.setObject(
        NSData(data: imageData),
        forKey: NSString(string: objectId))
      self.imageData = imageData
      
    }
    .store(in: &self.bindings)
  }
}

// MARK: - View Model Input
extension OSCAPressReleasesDetailViewModel {
  func viewDidLoad() {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    if let url = self.pressRelease.imageUrl,
       self.imageDataFromCache == nil {
      self.fetchImage(from: url)
      
    } else {
      self.imageData = self.imageDataFromCache
    }
  }
}

extension OSCAPressReleasesDetailViewModel {
  var shareContent: [Any] {
    var items: [Any] = [Any]()
    
    if !self.title.isEmpty {
      items.append(self.title + "\n")
    }
    if let summary = self.pressRelease.summary,
       !summary.isEmpty {
      items.append(summary + "\n\n")
    }
    if let url = URL(string: self.url) {
      items.append(url)
      items.append("\n\n")
    }
    if let appStoreURL = self.appStoreURL {
      let forwarding = self.appStoreForwardingTitle
      items.append(forwarding + "\n\n")
      items.append(appStoreURL)
    }
    return items
  }// end var shareContent
}// end extension SOCAPressReleasesDetailViewModel
