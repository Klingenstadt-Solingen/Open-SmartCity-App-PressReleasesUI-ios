//
//  OSCAPressReleasesWidgetFlowCoordinator.swift
//  OSCAPressReleasesUI
//
//  Created by Ömer Kurutay on 25.04.23.
//

import OSCAEssentials
import Foundation

public protocol OSCAPressReleasesWidgetFlowCoordinatorDependencies {
  func makeOSCAPressReleasesMainWidgetViewController(actions: OSCAPressReleasesMainWidgetViewModel.Actions) -> OSCAPressReleasesMainWidgetViewController
}

public final class OSCAPressReleasesWidgetFlowCoordinator: Coordinator {
  /**
   `children`property for conforming to `Coordinator` protocol is a list of `Coordinator`s
   */
  public var children: [Coordinator] = []
  /**
   router injected via initializer: `router` will be used to push and pop view controllers
   */
  public let router: Router
  /**
   dependencies injected via initializer DI conforming to the `OSCAPressReleasesWidgetFlowCoordinatorDependencies` protocol
   */
  let dependencies: OSCAPressReleasesWidgetFlowCoordinatorDependencies
  /**
   waste view controller `OSCAPressReleasesMainWidgetViewController`
   */
  public weak var pressReleasesMainWidgetVC: OSCAPressReleasesMainWidgetViewController?
  
  public init(router: Router, dependencies: OSCAPressReleasesWidgetFlowCoordinatorDependencies) {
    self.router = router
    self.dependencies = dependencies
  }
  
  func showPressReleasesMainWidget(animated: Bool, onDismissed: (() -> Void)?) -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    let actions = OSCAPressReleasesMainWidgetViewModel.Actions()
    let vc = self.dependencies
      .makeOSCAPressReleasesMainWidgetViewController(actions: actions)
    self.pressReleasesMainWidgetVC = vc
  }
  
  public func present(animated: Bool, onDismissed: (() -> Void)?) {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    self.showPressReleasesMainWidget(
      animated: animated,
      onDismissed: onDismissed)
  }
}

extension OSCAPressReleasesWidgetFlowCoordinator {
  /**
   add `child` `Coordinator`to `children` list of `Coordinator`s and present `child` `Coordinator`
   */
  public func presentChild(_ child: Coordinator, animated: Bool, onDismissed: (() -> Void)? = nil) {
    self.children.append(child)
    child.present(animated: animated) { [weak self, weak child] in
      guard let self = self, let child = child else { return }
      self.removeChild(child)
      onDismissed?()
    }
  }
  
  private func removeChild(_ child: Coordinator) {
    /// `children` includes `child`!!
    guard let index = self.children.firstIndex(where: { $0 === child })
    else { return }
    self.children.remove(at: index)
  }
}
