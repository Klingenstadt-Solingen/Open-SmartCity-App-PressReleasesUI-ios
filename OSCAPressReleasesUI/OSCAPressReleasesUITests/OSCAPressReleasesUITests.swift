// Reviewed by Stephan Breidenbach on 21.06.22
#if canImport(XCTest) && canImport(OSCATestCaseExtension) && canImport(OSCAEssentials)
import XCTest
@testable import OSCAPressReleasesUI
@testable import OSCAPressReleases
import OSCAEssentials
import OSCATestCaseExtension
import SwiftSoup

final class OSCAPressReleasesUITests: XCTestCase {
  static let moduleVersion = "1.0.4"
  override func setUpWithError() throws {
    try super.setUpWithError()
  }// end override fun setUp
  
  func testModuleInit() throws -> Void {
    let uiModule = try makeDevUIModule()
    XCTAssertNotNil(uiModule)
    XCTAssertEqual(uiModule.version, OSCAPressReleasesUITests.moduleVersion)
    XCTAssertEqual(uiModule.bundlePrefix, "de.osca.pressreleases.ui")
    let bundle = OSCAPressReleases.bundle
    XCTAssertNotNil(bundle)
    let uiBundle = OSCAPressReleasesUI.bundle
    XCTAssertNotNil(uiBundle)
    let configuration = OSCAPressReleasesUI.configuration
    XCTAssertNotNil(configuration)
    XCTAssertNotNil(self.devPlistDict)
    XCTAssertNotNil(self.productionPlistDict)
  }// end func testModuleInit
  
  func testContactUIConfiguration() throws -> Void {
    let _ = try makeDevUIModule()
    let uiModuleConfig = try makeUIModuleConfig()
    XCTAssertEqual(OSCAPressReleasesUI.configuration.title, uiModuleConfig.title)
    XCTAssertEqual(OSCAPressReleasesUI.configuration.colorConfig.accentColor, uiModuleConfig.colorConfig.accentColor)
    XCTAssertEqual(OSCAPressReleasesUI.configuration.fontConfig.bodyHeavy, uiModuleConfig.fontConfig.bodyHeavy)
  }// end func testEventsUIConfiguration
}// end final class OSCAPressReleasesUITests

// MARK: - factory methods
extension OSCAPressReleasesUITests {
  public func makeDevModuleDependencies() throws -> OSCAPressReleasesDependencies {
    let networkService = try makeDevNetworkService()
    let userDefaults   = try makeUserDefaults(domainString: "de.osca.pressreleases.ui")
    let dependencies = OSCAPressReleasesDependencies(
      networkService: networkService,
      userDefaults: userDefaults)
    return dependencies
  }// end public func makeDevModuleDependencies
  
  public func makeDevModule() throws -> OSCAPressReleases {
    let devDependencies = try makeDevModuleDependencies()
    // initialize module
    let module = OSCAPressReleases.create(with: devDependencies)
    return module
  }// end public func makeDevModule
  
  public func makeProductionModuleDependencies() throws -> OSCAPressReleasesDependencies {
    let networkService = try makeProductionNetworkService()
    let userDefaults   = try makeUserDefaults(domainString: "de.osca.pressreleases.ui")
    let dependencies = OSCAPressReleasesDependencies(
      networkService: networkService,
      userDefaults: userDefaults)
    return dependencies
  }// end public func makeProductionModuleDependencies
  
  public func makeProductionModule() throws -> OSCAPressReleases {
    let productionDependencies = try makeProductionModuleDependencies()
    // initialize module
    let module = OSCAPressReleases.create(with: productionDependencies)
    return module
  }// end public func makeProductionModule
  
  public func makeUIModuleConfig() throws -> OSCAPressReleasesUIConfig {
    let imageColor = UIColor.blue
    guard let placeholderImage = UIImage.placeholder else { throw OSCAPressReleasesUITests.Error.wrongPlaceHolderImage }
    let htmlModifier: ((String) -> String) = { content in
      var htmlContent = content
      do {
        let doc = try SwiftSoup.parseBodyFragment(htmlContent)
        try doc.select("h5").remove()
        try doc.select("p").first()?.remove()
        htmlContent = try doc.outerHtml()
      } catch let Exception.Error(_, message) {
        print(message)
        htmlContent = content
      } catch {
        print("error")
        htmlContent = content
      }
      return htmlContent
    }// end let htmlModifier
    return OSCAPressReleasesUIConfig(title: "OSCAPressReleasesUI",
                                     shadowSettings: OSCAShadowSettings(opacity: 0.2,
                                                                        radius: 10,
                                                                        offset: CGSize(width: 0, height: 2)),
                                     showImage: true,
                                     showReadingTime: true,
                                     cornerRadius: 10.0,
                                     placeholderImage: (image: placeholderImage,
                                                        color: imageColor),
                                     htmlContentModifier: htmlModifier,
                                     fontConfig: OSCAFontSettings(),
                                     colorConfig: OSCAColorSettings())
  }// end public func makeUIModuleConfig
  
  public func makeDevUIModuleDependencies() throws -> OSCAPressReleasesUIDependencies {
    let module      = try makeDevModule()
    let uiConfig    = try makeUIModuleConfig()
    return OSCAPressReleasesUIDependencies( dataModule: module,
                                            moduleConfig: uiConfig)
  }// end public func makeDevUIModuleDependencies
  
  public func makeDevUIModule() throws -> OSCAPressReleasesUI {
    let devDependencies = try makeDevUIModuleDependencies()
    // init ui module
    let uiModule = OSCAPressReleasesUI.create(with: devDependencies)
    return uiModule
  }// end public func makeUIModule
  
  public func makeProductionUIModuleDependencies() throws -> OSCAPressReleasesUIDependencies {
    let module      = try makeProductionModule()
    let uiConfig    = try makeUIModuleConfig()
    return OSCAPressReleasesUIDependencies( dataModule: module,
                                            moduleConfig: uiConfig)
  }// end public func makeProductionUIModuleDependencies
  
  public func makeProductionUIModule() throws -> OSCAPressReleasesUI {
    let productionDependencies = try makeProductionUIModuleDependencies()
    // init ui module
    let uiModule = OSCAPressReleasesUI.create(with: productionDependencies)
    return uiModule
  }// end public func makeProductionUIModule
}// end extension OSCAPressReleasesUITests

extension OSCAPressReleasesUITests {
  enum Error: Swift.Error {
    case wrongPlaceHolderImage
  }
}
#endif
