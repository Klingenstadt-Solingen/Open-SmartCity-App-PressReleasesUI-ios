//
//  OSCAPressReleasesMainViewModel.swift
//  OSCAPressReleasesUI
//
//  Created by Mammut Nithammer on 19.01.22.
//  Reviewed by Stephan Breidenbach on 21.06.22
//  Reviewed by Stephan Breidenbach on 09.09.2022.
//  Reviewed by Stephan Breidenbach on 16.02.23
//


import OSCAPressReleases
import Foundation
import Combine

public struct OSCAPressReleasesMainViewModelActions {
  public let showPressReleasesDetail: (OSCAPressReleases, OSCAPressRelease) -> Void
  public init( showPressReleasesDetail: @escaping (OSCAPressReleases, OSCAPressRelease) -> Void ) {
    self.showPressReleasesDetail = showPressReleasesDetail
  }
}// end public struct OSCAPressReleasesMainViewModelActions

public enum OSCAPressReleaseMainViewModelError: Error, Equatable {
  case pressReleaseFetch
}// end public enum OSCAPressReleaseMainViewModelError

public enum OSCAPressReleaseMainViewModelState: Equatable {
  case loading
  case finishedLoading
  case error(OSCAPressReleaseMainViewModelError)
}// end public enum OSCAPressReleaseMainViewModelState

public final class OSCAPressReleasesMainViewModel {
  
  let dataModule: OSCAPressReleases
  private let actions: OSCAPressReleasesMainViewModelActions?
  private var bindings = Set<AnyCancellable>()
  private var selectedItemId: String?
  
  // MARK: Initializer
  public init(dataModule: OSCAPressReleases,
              actions: OSCAPressReleasesMainViewModelActions) {
    self.dataModule = dataModule
    self.actions = actions
  }// end public init
  
  // MARK: - OUTPUT
  
  enum Section { case pressReleases }
  
  @Published private(set) var state: OSCAPressReleaseMainViewModelState = .loading
  @Published private(set) var pressReleases: [OSCAPressRelease] = [] {
    didSet {
      guard !self.pressReleases.isEmpty else { return }
      self.selectItem(with: self.selectedItemId)
    }// end didSet
  }// end pressReleases
  @Published private(set) var searchedPressReleases: [OSCAPressRelease] = []
  @Published private(set) var selectedItem: Int? {
    didSet {
      /// selected item id consumed!!
      self.selectedItemId = nil
    }// end didSet
  }// end selectedItem
  
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
  
  var isSearching: Bool = false
  let imageDataCache = NSCache<NSString, NSData>()
  
  public func fetchAll() {
    fetchAllPressReleases()
  }// end public func fetchAll
}// end public final class OSCAPressReleasesMainViewModel

// MARK: - Private Data Access
extension OSCAPressReleasesMainViewModel {
  /// fetch `OSCAPressRelease`s up to limit of 50 from network in background
  private func fetchAllPressReleases() {
    state = .loading
    
    self.dataModule
      .getPressReleases(limit: 50)
      .sink { completion in
        switch completion {
        case .finished:
          self.state = .finishedLoading
        case .failure:
          self.state = .error(.pressReleaseFetch)
        }// end switch case
      } receiveValue: { result in
        switch result {
        case let .success(fetchedPressReleases):
          self.pressReleases = fetchedPressReleases
        case .failure:
          self.state = .error(.pressReleaseFetch)
        }// end switch case
      }// end receiveValue closure
      .store(in: &bindings)
  }// end private func fetchAllPressReleases
  
  /// fetch `OSCAPressReleases` search results from network
  /// - Parameter searchText: search string
  private func fetchPressReleases(for searchText: String) {
    self.dataModule
      .elasticSearch(for: searchText, isRaw: false)
      .sink { completion in
        switch completion {
        case .finished:
          self.state = .finishedLoading
          
        case .failure:
          self.state = .finishedLoading
        }// end switch case
      } receiveValue: { fetchedPressReleases in
        self.searchedPressReleases = fetchedPressReleases
      }// end receiveValue closure
      .store(in: &bindings)
  }// end private func fetchPressReleases for search text
    
    // Update press releases to check if objectId of notification exists
    public func fetchAllPressReleases(objectId: String) {
        self.dataModule
          .getPressReleases(limit: 50)
          .sink { completion in
          } receiveValue: { result in
              if case .success(let fetchedPressReleases) = result {
                  // check if press release from notification exists after update
                  if !(fetchedPressReleases.contains(where: { $0.objectId == objectId})) {
                      self.selectedItemId = nil
                      self.selectItem(with: nil)
                  }
                  self.pressReleases = fetchedPressReleases
            }// end switch case
          }// end receiveValue closure
          .store(in: &bindings)
    }
}// end extension public final class OSCAPressReleasesMainViewModel

// MARK: - INPUT. View event methods
extension OSCAPressReleasesMainViewModel {
  /// view controller life cycle event
  func viewDidLoad() {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    fetchAll()
  }// end func viewDidLoad
  
  /// item selection event in `UICollectionView`
  func didSelectItem(at index: Int) {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    if self.isSearching {
      guard (searchedPressReleases.count + 1) >= index else { return }
      guard let objectId = searchedPressReleases[index].objectId else { return }
      let imageData = imageDataCache.object(forKey: NSString(string: objectId)) as Data?
      
      self.actions?.showPressReleasesDetail(
        self.dataModule,
        searchedPressReleases[index])
    }
    else {
      guard pressReleases.count > index,
            let objectId = pressReleases[index].objectId else { return }
      let imageData = imageDataCache.object(forKey: NSString(string: objectId)) as Data?
      
      self.actions?.showPressReleasesDetail(
        self.dataModule,
        pressReleases[index])
    }
  }
  
  /// search results update
  func updateSearchResults(for searchText: String) {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    if !searchText.isEmpty {
      self.isSearching = true
      fetchPressReleases(for: searchText)
    }
    else {
      self.isSearching = false
      searchedPressReleases = pressReleases
    }// end if
  }// end func updateSearchResults for search text
  
  /// pull to refresh event
  func callPullToRefresh() {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    fetchAll()
  }// end func callPullToRefresh
}// end extension public final class OSCAPressReleasesMainViewModel

// MARK: - Deeplinking
extension OSCAPressReleasesMainViewModel {
  func didReceiveDeeplinkDetail(with objectId: String) -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    guard !objectId.isEmpty else { return }
    self.selectedItemId = objectId
    selectItem(with: objectId)
  }// end func didReceiveDeeplinkDetail
  
  private func selectItem(with objectId: String?) -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
      if let objectId = objectId {
          if (!self.pressReleases.contains(where: { $0.objectId == objectId}) && objectId != "") {
              fetchAllPressReleases(objectId: objectId)
          }
      }
    guard let objectId = objectId,
          let index = self.pressReleases.firstIndex(where: { $0.objectId == objectId})
      else {
        return
    }
    self.selectedItem = index
  }// end private func selectItem with object id
}// end extension final class OSCAPressReleasesMainViewModel

// MARK: - OUTPUT Localized Strings
extension OSCAPressReleasesMainViewModel {
  var screenTitle: String {
    OSCAPressReleasesUI.configuration.screenTitle ?? NSLocalizedString(
    "press_releases_title",
    bundle: self.bundle,
    comment: "The screen title for press releases")
  }
  var alertTitleError: String { NSLocalizedString(
    "press_releases_alert_title_error",
    bundle: self.bundle,
    comment: "The alert title for an error") }
  var alertActionConfirm: String { NSLocalizedString(
    "press_releases_alert_title_confirm",
    bundle: self.bundle,
    comment: "The alert action title to confirm") }
  var searchPlaceholder: String { NSLocalizedString(
    "press_releases_search_placeholder",
    bundle: self.bundle,
    comment: "Placeholder for searchbar") }
}// end extension end extension final class OSCAPressReleasesMainViewModel
