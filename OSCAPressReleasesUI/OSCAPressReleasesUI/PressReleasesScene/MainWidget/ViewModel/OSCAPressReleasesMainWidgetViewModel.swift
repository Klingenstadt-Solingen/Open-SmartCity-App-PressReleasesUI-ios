//
//  OSCAPressReleasesMainWidgetViewModel.swift
//  OSCAPressReleasesUI
//
//  Created by Ömer Kurutay on 25.04.23.
//

import OSCAEssentials
import OSCAPressReleases
import Foundation
import Combine

public final class OSCAPressReleasesMainWidgetViewModel {
  
  let dataModule  : OSCAPressReleases
  let moduleConfig: OSCAPressReleasesUIConfig
  let fontConfig  : OSCAFontConfig
  let colorConfig : OSCAColorConfig
  
  private let actions: Actions
  private var bindings = Set<AnyCancellable>()
  
  // MARK: Initializer
  public init(dependencies: Dependencies) {
    self.actions      = dependencies.actions
    self.dataModule   = dependencies.dataModule
    self.moduleConfig = dependencies.moduleConfig
    self.fontConfig   = dependencies.moduleConfig.fontConfig
    self.colorConfig  = dependencies.moduleConfig.colorConfig
  }
  
  // MARK: - OUTPUT
  
  @Published private(set) var state: State = .loading
  @Published private(set) var pressReleases: [OSCAPressRelease] = []
  
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
}

// MARK: - View Model dependencies
extension OSCAPressReleasesMainWidgetViewModel {
  public struct Dependencies {
    var actions     : Actions
    var dataModule  : OSCAPressReleases
    var moduleConfig: OSCAPressReleasesUIConfig
  }
}

// MARK: - Actions
extension OSCAPressReleasesMainWidgetViewModel {
  public struct Actions {}
}

// MARK: - Error
extension OSCAPressReleasesMainWidgetViewModel {
  public enum Error: Swift.Error, Equatable {
    case pressReleaseFetch
  }
}

// MARK: - Sections
extension OSCAPressReleasesMainWidgetViewModel {
  public enum Section { case pressReleases }
}

// MARK: - States
extension OSCAPressReleasesMainWidgetViewModel {
  public enum State: Equatable {
    case loading
    case finishedLoading
    case error(OSCAPressReleasesMainWidgetViewModel.Error)
  }
}

// MARK: - Private Data Access
extension OSCAPressReleasesMainWidgetViewModel {
  private func fetchAllPressReleases() {
    self.state = .loading
    
    let limit = self.moduleConfig.mainWidget.maxItems
    self.dataModule.getPressReleases(limit: limit)
      .sink { completion in
        switch completion {
        case .finished:
          self.state = .finishedLoading
        case let .failure(error):
#if DEBUG
          print("\(String(describing: self)): \(#function) with Error: \(error)")
#endif
          self.state = .error(.pressReleaseFetch)
        }
        
      } receiveValue: { result in
        switch result {
        case let .success(fetchedPressReleases):
          self.pressReleases = fetchedPressReleases
          
        case .failure:
          self.state = .error(.pressReleaseFetch)
        }
      }
      .store(in: &self.bindings)
  }
}

// MARK: - INPUT. View event methods
extension OSCAPressReleasesMainWidgetViewModel {
  func viewDidLoad() {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    self.fetchAllPressReleases()
  }
  
  func refreshContent() {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    self.fetchAllPressReleases()
  }
}

// MARK: - OUTPUT Localized Strings
extension OSCAPressReleasesMainWidgetViewModel {
  var screenTitle: String {
    self.moduleConfig.screenTitle ?? NSLocalizedString(
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
}
