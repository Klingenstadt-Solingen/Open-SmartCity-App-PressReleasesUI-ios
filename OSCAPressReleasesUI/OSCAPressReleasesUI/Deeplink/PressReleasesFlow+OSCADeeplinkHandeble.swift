//
//  PressReleasesFlow+OSCADeeplinkHandeble.swift
//  OSCAPressReleasesUI
//
//  Created by Stephan Breidenbach on 07.09.22.
//

import Foundation
import OSCAEssentials

extension OSCAPressReleasesFlowCoordinator: OSCADeeplinkHandeble {
  ///```console
  ///xcrun simctl openurl booted \
  /// "solingen://pressreleases/detail?object=fbzwMYb6la"
  /// ```
  public func canOpenURL(_ url: URL) -> Bool {
    let deeplinkScheme: String = dependencies
      .deeplinkScheme
    return url.absoluteString.hasPrefix("\(deeplinkScheme)://pressreleases")
  }// end public func canOpenURL
  
  public func openURL(_ url: URL,
                      onDismissed:(() -> Void)?) throws -> Void {
    guard canOpenURL(url)
    else { return }
    let deeplinkParser = DeeplinkParser()
    if let payload = deeplinkParser.parse(content: url) {
      switch payload.target {
      case "detail":
        let objectId = payload.parameters["object"]
        showPressReleasesMain(with: objectId,
                              onDismissed: onDismissed)
      default:
        showPressReleasesMain(animated: true,
                              onDismissed: onDismissed)
      }
    } else {
      showPressReleasesMain(animated: true,
                            onDismissed: onDismissed)
    }// end if
  }// end public func openURL
  
  public func showPressReleasesMain(with objectId: String? = nil,
                                    onDismissed:(() -> Void)?) -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function): objectId: \(objectId ?? "NIL")")
#endif
    /// is there an object id?
    if let objectId = objectId {
      /// is there a press releases main view controller
      if let pressReleasesMainVC = self.pressReleasesMainVC,
         pressReleasesMainVC.isBeingPresented {
        pressReleasesMainVC.didReceiveDeeplinkDetail(with: objectId)
        
      } else {
        self.showPressReleasesMain(animated: true,
                                   onDismissed: onDismissed)
        guard let pressReleasesMainVC = self.pressReleasesMainVC
        else { return }
        pressReleasesMainVC.didReceiveDeeplinkDetail(with: objectId)
      }// end if
    }// end
  }// end public func showPressReleasesMain wit object id
}// end extension public final class DeeplinkNavigationFlowCoordinator
