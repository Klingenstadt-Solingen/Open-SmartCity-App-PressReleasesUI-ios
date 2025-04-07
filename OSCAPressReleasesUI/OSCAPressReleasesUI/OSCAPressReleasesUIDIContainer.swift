//
//  OSCAPressReleasesUIDIContainer.swift
//  OSCAPressReleaseUI
//
//  Created by Stephan Breidenbach on 28.04.21.
//  Reviewed by Stephan Breidenbach on 27.01.22
//

import Foundation
import OSCAEssentials
import OSCANetworkService
import OSCAPressReleases

/**
 Every isolated module feature will have its own Dependency Injection Container,
 to have one entry point where we can see all dependencies and injections of the module
 */
final class OSCAPressReleasesUIDIContainer {
  let dependencies: OSCAPressReleasesUIDependencies
  
  public init(dependencies: OSCAPressReleasesUIDependencies) {
#if DEBUG
    print("\(String(describing: Self.self)): \(#function)")
#endif
    self.dependencies = dependencies
  } // end init
} // end final class OSCAPressReleasesUIDIContainer

extension OSCAPressReleasesUIDIContainer: OSCAPressReleasesFlowCoordinatorDependencies {
  // MARK: - PressReleases Main
  func makeOSCAPressReleasesMainViewController(actions: OSCAPressReleasesMainViewModelActions) -> OSCAPressReleasesMainViewController {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    let viewModel = makeOSCAPressReleasesMainViewModel(actions: actions)
    return OSCAPressReleasesMainViewController.create(with: viewModel)
  } // end makePressReleasesViewController
  
  func makeOSCAPressReleasesMainViewModel(actions: OSCAPressReleasesMainViewModelActions) -> OSCAPressReleasesMainViewModel {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    
    return OSCAPressReleasesMainViewModel(dataModule: dependencies.dataModule, actions: actions)
  } // end func makePressReleasesViewModel
  
  // MARK: - PressReleases Detail
  func makeOSCAPressReleasesDetailViewController(dataModule: OSCAPressReleases, pressRelease: OSCAPressRelease) -> OSCAPressReleasesDetailViewController {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    let viewModel = self.makeOSCAPressReleasesDetailViewModel(
      dataModule: dataModule,
      pressRelease: pressRelease)
    return OSCAPressReleasesDetailViewController.create(with: viewModel)
  } // end func makePreassReleasesContentViewController
  
  func makeOSCAPressReleasesDetailViewModel(dataModule: OSCAPressReleases, pressRelease: OSCAPressRelease) -> OSCAPressReleasesDetailViewModel {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    return OSCAPressReleasesDetailViewModel(dataModule: dataModule,
                                            pressRelease: pressRelease)
  } // end func makePressReleaseContentViewModel
  
  // MARK: - Flow Coordinators
  func makePressReleasesFlowCoordinator(router: Router) -> OSCAPressReleasesFlowCoordinator {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    return OSCAPressReleasesFlowCoordinator(router: router, dependencies: self)
  } // end func makePressReleasesFlowCoordinator
  
  func makePressReleasesWidgetFlowCoordinator(router: Router) -> OSCAPressReleasesWidgetFlowCoordinator {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    return OSCAPressReleasesWidgetFlowCoordinator(
      router: router,
      dependencies: self)
  }
} // end extension class OSCAPressReleasesUIDIContainer

extension OSCAPressReleasesUIDIContainer: OSCAPressReleasesWidgetFlowCoordinatorDependencies {
  func makeOSCAPressReleasesMainWidgetViewModel(actions: OSCAPressReleasesMainWidgetViewModel.Actions) -> OSCAPressReleasesMainWidgetViewModel {
    let dependencies = OSCAPressReleasesMainWidgetViewModel.Dependencies(
      actions: actions,
      dataModule: self.dependencies.dataModule,
      moduleConfig: self.dependencies.moduleConfig)
    return OSCAPressReleasesMainWidgetViewModel(dependencies: dependencies)
  }
  
  func makeOSCAPressReleasesMainWidgetViewController(actions: OSCAPressReleasesMainWidgetViewModel.Actions) -> OSCAPressReleasesMainWidgetViewController {
    let viewModel = self
      .makeOSCAPressReleasesMainWidgetViewModel(actions: actions)
    return OSCAPressReleasesMainWidgetViewController
      .create(with: viewModel)
  }
}
