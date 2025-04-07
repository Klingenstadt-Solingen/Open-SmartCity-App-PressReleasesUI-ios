//
//  OSCAPressReleasesUI.swift
//  OSCAPressReleasesUI
//
//  Created by Mammut Nithammer on 10.01.22.
//  Reviewed by Stephan Breidenbach on 27.01.2022
//  Reviewed by Stephan Breidenbach on 21.06.22
//

import OSCAEssentials
import OSCAPressReleases
import UIKit

public protocol OSCAPressReleasesUIModuleConfig: OSCAUIModuleConfig {
  var shadowSettings: OSCAShadowSettings { get set }
  var showImage: Bool { get set }
  var showReadingTime: Bool { get set }
  var placeholderImage: (image: UIImage, color: UIColor?)? { get set }
  var cornerRadius: Double { get set }
  var deeplinkScheme: String { get set }
  var detailTextColor: UIColor { get set }
} // end public protocol OSCAPressReleasesUIModuleConfig

public struct OSCAPressReleasesUIDependencies {
  let dataModule: OSCAPressReleases
  let moduleConfig: OSCAPressReleasesUIConfig
  let analyticsModule: OSCAAnalyticsModule?
  
  
  public init(dataModule: OSCAPressReleases,
              moduleConfig: OSCAPressReleasesUIConfig,
              analyticsModule: OSCAAnalyticsModule? = nil
  ) {
    self.dataModule = dataModule
    self.moduleConfig = moduleConfig
    self.analyticsModule = analyticsModule
  } // end public init
} // end public Struct OSCAPressReleasesUIDependencies

/**
 The configuration of the `OSCAPressReleasesUI`-module
 */
public struct OSCAPressReleasesUIConfig: OSCAPressReleasesUIModuleConfig {
  /// module title
  public var title: String?
  public var externalBundle: Bundle?
  public var maxItems: Int?
  public var itemHeight: CGFloat
  public var shadowSettings: OSCAShadowSettings
  public var showImage: Bool
  public var showReadingTime: Bool
  public var placeholderImage: (image: UIImage, color: UIColor?)?
  public var htmlContentModifier: ((String) -> String)?
  public var cornerRadius: Double
  public var fontConfig: OSCAFontConfig
  public var colorConfig: OSCAColorConfig
  public var detailTextColor: UIColor
  /// app deeplink scheme URL part before `://`
  public var deeplinkScheme      : String = "solingen"
  public var mainWidget: MainWidget
  
  public var screenTitle: String?
  
  /// Initializer for `OSCAPressReleasesUIConfig`
  /// - Parameters:
  ///  - title:
  ///  - maxItems
  ///  - shadowSettings:
  ///  - showImage: .
  ///  - showReadingTime: .
  ///  - placeholderImage: .
  ///  - cornerRadius: .
  ///  - htmlContentModifier:
  ///  - fontConfig
  ///  - colorConfig: .
  ///  - deeplinkScheme:
  public init(title: String?,
              externalBundle: Bundle? = nil,
              mainWidget: MainWidget = MainWidget(),
              maxItems: Int? = nil,
              itemHeight: CGFloat = 112,
              shadowSettings: OSCAShadowSettings,
              showImage: Bool,
              showReadingTime: Bool,
              cornerRadius: Double,
              placeholderImage: (image: UIImage, color: UIColor?)? = nil,
              htmlContentModifier: ((String) -> String)? = nil,
              fontConfig: OSCAFontConfig,
              colorConfig: OSCAColorConfig,
              detailTextColor: UIColor? = nil,
              deeplinkScheme: String = "solingen",
              screenTitle: String? = nil
  ) {
    self.title = title
    self.externalBundle = externalBundle
    self.maxItems = maxItems
    self.itemHeight = itemHeight
    self.shadowSettings = shadowSettings
    self.showImage = showImage
    self.showReadingTime = showReadingTime
    self.cornerRadius = cornerRadius
    self.htmlContentModifier = htmlContentModifier
    self.placeholderImage = placeholderImage
    self.fontConfig = fontConfig
    self.colorConfig = colorConfig
    self.deeplinkScheme = deeplinkScheme
    self.mainWidget = mainWidget
    self.detailTextColor = detailTextColor ?? self.colorConfig.textColor.withAlphaComponent(0.7)
    self.screenTitle = screenTitle
  } // end public memberwise init
  
  
} // end public struct OSCAPressReleasesUIConfig

// MARK: Main Widget Config
extension OSCAPressReleasesUIConfig {
  public struct MainWidget {
    public var title: String?
    public var maxItems: Int
    
    public init(title: String? = nil, maxItems: Int = 5) {
      self.title = title
      self.maxItems = maxItems
    }
  }
}

// MARK: - Keys
extension OSCAPressReleasesUI {
  /// Widget keys
  public enum Keys: String {
    case pressReleasesMainWidgetVisibility = "PressReleases_Main_Widget_Visibility"
    case pressReleasesMainWidgetPosition   = "PressReleases_Main_Widget_Position"
  }
}

public struct OSCAPressReleasesUI: OSCAUIModule {
  /// module DI container
  private var moduleDIContainer: OSCAPressReleasesUIDIContainer!
  public var version: String = "1.0.4"
  public var bundlePrefix: String = "de.osca.pressreleases.ui"
  
  public internal(set) static var configuration: OSCAPressReleasesUIConfig!
  /// module `Bundle`
  ///
  /// **available after module initialization only!!!**
  public internal(set) static var bundle: Bundle!
  
  /**
   create module and inject module dependencies
   - Parameter mduleDependencies: module dependencies
   */
  public static func create(with moduleDependencies: OSCAPressReleasesUIDependencies) -> OSCAPressReleasesUI {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    var module: Self = Self.init(config: moduleDependencies.moduleConfig)
    module.moduleDIContainer = OSCAPressReleasesUIDIContainer(dependencies: moduleDependencies)
    return module
  }// end public static func create with module dependencies
  
  /// public initializer with module configuration
  /// - Parameter config: module configuration
  public init(config: OSCAUIModuleConfig) {
#if SWIFT_PACKAGE
    Self.bundle = Bundle.module
#else
    guard let bundle: Bundle = Bundle(identifier: self.bundlePrefix) else { fatalError("Module bundle not initialized!") }
    Self.bundle = bundle
#endif
    guard let extendedConfig = config as? OSCAPressReleasesUIConfig else { fatalError("Config couldn't be initialized!")}
    OSCAPressReleasesUI.configuration = extendedConfig
  }// end public init
}// end public struct OSCAPressReleasesUI

// MARK: - public ui module interface
extension OSCAPressReleasesUI {
  /// public module interface `getter` for `OSCAPressReleasesMainViewModel`
  public func getPressReleasesMainViewModel(actions: OSCAPressReleasesMainViewModelActions) -> OSCAPressReleasesMainViewModel {
    let viewModel = self.moduleDIContainer.makeOSCAPressReleasesMainViewModel(actions: actions)
    return viewModel
  }// end public func getPressReleasesMainViewModel
}// end extension OSCAPressReleasesUI

// MARK: Flow Coordinators
extension OSCAPressReleasesUI {
  /**
   public module interface `getter`for `OSCAPressReleasesFlowCoordinator`
   - Parameter router: router needed or the navigation graph
   */
  public func getPressReleasesFlowCoordinator(router: Router) -> OSCAPressReleasesFlowCoordinator {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    let flow = self.moduleDIContainer.makePressReleasesFlowCoordinator(router: router)
    return flow
  }// end public func getPressReleasesFlowCoordinator
  
  /**
   public module interface `getter`for `OSCAPressReleasesWidgetFlowCoordinator`
   - Parameter router: router needed or the navigation graph
   */
  public func getPressReleasesWidgetFlowCoordinator(router: Router) -> OSCAPressReleasesWidgetFlowCoordinator {
    self.moduleDIContainer
      .makePressReleasesWidgetFlowCoordinator(router: router)
  }
}
