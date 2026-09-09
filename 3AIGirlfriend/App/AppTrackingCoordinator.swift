//
//  AppTrackingCoordinator.swift
//  1AIMoodBoardPhotoApp
//

import AppTrackingTransparency
import Foundation

/// Presents the ATT system dialog when status is `.notDetermined`.
/// Call when the app UI is on screen (not under another modal if possible).
enum AppTrackingCoordinator {
    private static var isRequestInFlight = false

    static func requestAuthorizationIfNeeded(
        delay: TimeInterval = 0.5,
        completion: ((ATTrackingManager.AuthorizationStatus) -> Void)? = nil
    ) {
        guard #available(iOS 14, *) else {
            completion?(.authorized)
            return
        }

        let status = ATTrackingManager.trackingAuthorizationStatus
        logStatus(status, context: "check")

        guard status == .notDetermined else {
            completion?(status)
            return
        }

        guard !isRequestInFlight else { return }
        isRequestInFlight = true

        let presentRequest = {
            ATTrackingManager.requestTrackingAuthorization { newStatus in
                isRequestInFlight = false
                logStatus(newStatus, context: "finished")
                DispatchQueue.main.async {
                    completion?(newStatus)
                }
            }
        }

        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: presentRequest)
        } else {
            DispatchQueue.main.async(execute: presentRequest)
        }
    }

    private static func logStatus(_ status: ATTrackingManager.AuthorizationStatus, context: String) {
        #if DEBUG
        print("[ATT] \(context): raw=\(status.rawValue) (0=notDetermined, 1=restricted, 2=denied, 3=authorized)")
        #endif
    }
}
