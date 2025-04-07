//
//  PressReleasesDI+DeeplinkHandler.swift
//  OSCAPressReleasesUI
//
//  Created by Stephan Breidenbach on 07.09.22.
//

import Foundation

extension OSCAPressReleasesUIDIContainer {
  var deeplinkScheme: String {
    return self
      .dependencies
      .moduleConfig
      .deeplinkScheme
  }// end var deeplinkScheme
}// end extension  final class OSCAPressReleasesUIDIContainer
