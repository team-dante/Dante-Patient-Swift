//
//  SignInViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/10/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class SignInViewController: UIViewController {

    @IBOutlet weak var signInCard: CardComponent!
    @IBOutlet weak var phoneNumInput: Inputs!
    @IBOutlet weak var pinInput: Inputs!
    
    var spinner: UIView?
    let autoSignIn = BiometricIDAuth()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        // if user has signed in and the device has FaceID/TouchID enabled, log user in using FaceID/TouchID
        if UserDefaults.standard.bool(forKey: "hasLoggedIn") == true && autoSignIn.canEvaluatePolicy() && Auth.auth().currentUser != nil {
            autoLoginAction()
        }
    }
    
    @IBAction func onSignIn(_ sender: Any) {
        
        // if either field is empty, show alert
        if (phoneNumInput.text! == "" || pinInput.text! == "") {
            let alertMessage = "Please enter your phone number and PIN."
            self.showAlert(message: alertMessage)
        } else {
            self.showSpinner(onView: self.view)
            
            let email = "\(phoneNumInput.text!)@email.com"
            let password = "\(pinInput.text!)ABCDEFG"
            
            // sign in user to Firebase
            Auth.auth().signIn(withEmail: email, password: password) {
                (user, error) in
                self.removeSpinner()
                
                // if username & password are correct, perform segue to the map page, else display alerts
                if error == nil {
                    self.performSegue(withIdentifier: "loginSuccess", sender: self)
                    UserDefaults.standard.set(true, forKey: "hasLoggedIn")
                } else {
                    let alertMessage = "There is no user record associated with this identifier. The user may have been deleted."
                    self.showAlert(message: alertMessage)
                }
            }
        }
    }

    // show an alert message
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    // show loading status
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        spinner = spinnerView
    }
    
    // clear spinner
    func removeSpinner() {
        DispatchQueue.main.async {
            self.spinner?.removeFromSuperview()
            self.spinner = nil
        }
    }
    
    // Use FaceID/TouchID
    func autoLoginAction() {
        autoSignIn.authenticateUser() {
            [weak self] message in
            if let message = message {
                // if the completion is not nil (aka. getting an error), show an alert
                let alertView = UIAlertController(title: "Error",
                                                  message: message,
                                                  preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Okay", style: .default)
                alertView.addAction(okAction)
                self?.present(alertView, animated: true)
            } else {
                // otherwise, go to the map page
                self?.performSegue(withIdentifier: "loginSuccess", sender: self)
            }
        }
    }
    
    // tap outside to dismiss keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}
