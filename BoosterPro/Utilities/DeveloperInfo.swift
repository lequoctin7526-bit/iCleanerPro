import Foundation
import SwiftUI
import UIKit

/// Centralized developer attribution and social link constants.
enum DeveloperInfo {
    static let creatorName = "Quốc Tín"
    static let appCreatedBy = "App được tạo bởi Quốc Tín"
    static let facebookURL = "https://www.facebook.com"
    static let facebookAppScheme = "fb://facewebmodal/f?href=https://www.facebook.com"

    @MainActor
    static func openFacebook() {
        if let appUrl = URL(string: facebookAppScheme), UIApplication.shared.canOpenURL(appUrl) {
            UIApplication.shared.open(appUrl, options: [:], completionHandler: nil)
        } else if let webUrl = URL(string: facebookURL), UIApplication.shared.canOpenURL(webUrl) {
            UIApplication.shared.open(webUrl, options: [:], completionHandler: nil)
        }
    }
}
