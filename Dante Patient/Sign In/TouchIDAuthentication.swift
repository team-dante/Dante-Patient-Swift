//
//  TouchIDAuthentication.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/13/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import Foundation
import LocalAuthentication

//enum BiometricType {
//    case none
//    case touchID
//    case faceID
//}

class BiometricIDAuth {
    
    let context = LAContext()
    var loginReason = "Logging in with Touch ID"
    
    func canEvaluatePolicy() -> Bool {
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

//    func biometricType() -> BiometricType {
//        let _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
//        switch context.biometryType {
//        case .none:
//            return .none
//        case .touchID:
//            return .touchID
//        case .faceID:
//            return .faceID
//        }
//    }
    
    func authenticateUser(completion: @escaping (String?) -> Void) {
        guard canEvaluatePolicy() else {
            // cannot use biometrics
            completion("Touch ID not available")
            return
        }
        
        // check if FaceID/TouchID is successful
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: loginReason) { (success, evaluateError) in
            if success {
                DispatchQueue.main.async {
                    completion(nil)
                }
            } else {
                let message: String
                
                switch evaluateError {
                case LAError.authenticationFailed?:
                    message = "There was a problem verifying your identity."
                case LAError.userCancel?:
                    message = "FaceID is not detected."
                case LAError.userFallback?:
                    message = "Please enter your credentials manually."
                case LAError.biometryNotAvailable?:
                    message = "Face ID/Touch ID is not available."
                case LAError.biometryNotEnrolled?:
                    message = "Face ID/Touch ID is not set up."
                case LAError.biometryLockout?:
                    message = "Face ID/Touch ID is locked."
                default:
                    message = "Face ID/Touch ID may not be configured"
                }
                completion(message)
            }
        }
    }
    
}
