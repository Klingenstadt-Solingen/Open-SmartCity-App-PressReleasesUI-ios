//
//  OSCAPressReleasesFlowCoordinator.swift
//
//
//  Created by Stephan Breidenbach on 21.01.22.
//  Reviewed by Stephan Breidenbach on 09.09.22.
//

import Foundation
import OSCAEssentials
import OSCAPressReleases

public protocol OSCAPressReleasesFlowCoordinatorDependencies {
  var deeplinkScheme: String { get }
  func makeOSCAPressReleasesMainViewController(actions: OSCAPressReleasesMainViewModelActions) -> OSCAPressReleasesMainViewController
  func makeOSCAPressReleasesDetailViewController(dataModule: OSCAPressReleases,
                                                 pressRelease: OSCAPressRelease) -> OSCAPressReleasesDetailViewController
} // end protocol OSCAPressReleasesFlowCoordinatorDependencies

public final class OSCAPressReleasesFlowCoordinator: Coordinator {
  /**
   `children`property for conforming to `Coordinator` protocol is a list of `Coordinator`s
   */
  public var children: [Coordinator] = []
  
  /**
   router injected via initializer: `router` will be used to push and pop view controllers
   */
  public let router: Router
  
  /**
   dependencies injected via initializer DI conforming to the `OSCAPressReleasesFlowCoordinatorDependencies` protocol
   */
  let dependencies: OSCAPressReleasesFlowCoordinatorDependencies
  
  /**
   press release main view controller `OSCAPressReleasesMainViewController`
   */
  weak var pressReleasesMainVC: OSCAPressReleasesMainViewController?
  
  weak var pressReleasesDetailVC: OSCAPressReleasesDetailViewController?
  
  
  public init(router: Router,
              dependencies: OSCAPressReleasesFlowCoordinatorDependencies
  ) {
    self.router = router
    self.dependencies = dependencies
  } // end init router, dependencies
  
  // MARK: - PressReleases Detail
  private func showPressReleasesDetail(dataModule: OSCAPressReleases,
                                       pressRelease: OSCAPressRelease) -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    if let pressReleasesDetailVC = self.pressReleasesDetailVC,
       pressReleasesDetailVC.isModalInPresentation {
      self.router.navigateBack(animated: true)
      self.pressReleasesDetailVC = nil
    }// end if
    // instantiate view controller from dependencies
    let vc = dependencies.makeOSCAPressReleasesDetailViewController(
      dataModule: dataModule,
      pressRelease: pressRelease)
    // present view controller animated
    router.presentModalViewController(vc,
                                      animated: true,
                                      onDismissed: nil)
    self.pressReleasesDetailVC = vc
  } // end private func showPressReleasesDetail
  
  public func showPressReleasesDetailFromChild(child: Coordinator,
                                               dataModule: OSCAPressReleases,
                                               pressRelease: OSCAPressRelease) -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    showPressReleasesDetail(dataModule: dataModule,
                            pressRelease: pressRelease)
    removeChild(child)
  }// end public func showPressReleasesDetailFromChild
  
  // MARK: - PressReleases Main
  public func showPressReleasesMain(animated: Bool,
                                    onDismissed: (() -> Void)?) -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    if let pressReleasesMainVC = pressReleasesMainVC {
      self.router.present(pressReleasesMainVC,
                          animated: animated,
                          onDismissed: onDismissed)
    } else {
      // Note: here we keep strong reference with actions, this way this flow do not need to be strong referenced
      let actions: OSCAPressReleasesMainViewModelActions = OSCAPressReleasesMainViewModelActions(
        showPressReleasesDetail: self.showPressReleasesDetail
      ) // end let actions
      // instantiate view controller
      let vc = dependencies.makeOSCAPressReleasesMainViewController(actions: actions)
      self.router.present(vc,
                          animated: animated,
                          onDismissed: onDismissed)
      pressReleasesMainVC = vc
    }// end if
  }// end public func showPressReleasesMain
  
  public func present(animated: Bool, onDismissed: (() -> Void)?) {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    showPressReleasesMain(animated: animated, onDismissed: onDismissed)
    
  } // end func present
} // end final class OSCAPressReleasesFlowCoordinator


extension OSCAPressReleasesFlowCoordinator {
  /**
   add `child` `Coordinator`to `children` list of `Coordinator`s and present `child` `Coordinator`
   */
  public func presentChild(_ child: Coordinator,
                           animated: Bool,
                           onDismissed: (() -> Void)? = nil) {
    children.append(child)
    child.present(animated: animated) { [weak self, weak child] in
      guard let self = self, let child = child else { return }
      self.removeChild(child)
      onDismissed?()
    } // end on dismissed closure
  } // end public func presentChild
  
  private func removeChild(_ child: Coordinator) {
    /// `children` includes `child`!!
    guard let index = children.firstIndex(where: { $0 === child }) else { return } // end guard
    children.remove(at: index)
  } // end private func removeChild
} // end extension public final class OSCAPressReleasesFlowCoordinator
