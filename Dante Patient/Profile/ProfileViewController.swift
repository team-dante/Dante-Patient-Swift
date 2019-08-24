//
//  ProfileViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/13/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class ProfileViewController: UIViewController {

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var phoneNumLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    
    @IBOutlet weak var surveyCard: UIView!
    var ref: DatabaseReference!
    
    // when the user pressed the feedback card component, they go to the DeveloperFeedbackViewController
    @objc func handleFeedbackPressed(_ sender: UITapGestureRecognizer) {
        self.performSegue(withIdentifier: "goToDeveloperFeedback", sender: self)
    }
    
    // hide navigation bar when ProfileViewController is about to appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // unhide navigation bar when ProfileViewController is about to disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cardComponentGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleFeedbackPressed(_:)))
        self.surveyCard.addGestureRecognizer(cardComponentGesture)
        
        // init Firebase
        ref = Database.database().reference()

        // customize logout button
        logoutButton.layer.cornerRadius = logoutButton.frame.height/2.4
        logoutButton.layer.masksToBounds = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let user = Auth.auth().currentUser;
        if let email = user?.email {
            // get current user's phone number
            let phoneNum = email.split(separator: "@")[0]
            self.phoneNumLabel.text = "phone: \(phoneNum)"
            
            // if phoneNum == phone number stored in database, pull out the user's full name
            ref.child("Patients").queryOrdered(byChild: "patientPhoneNumber").queryEqual(toValue: phoneNum).observeSingleEvent(of: .value, with: { (snapshot) in
                if let patients = snapshot.value as? [String: Any] {
                    for patient in patients {
                        if let patient = patient.value as? [String: String] {
                            let firstName = patient["firstName"]!
                            let lastName = patient["lastName"]!
                            self.usernameLabel.text = "\(firstName) \(lastName)"
                        }
                    }
                }
            })
        }
    }
    
    // display alert when the user attempts to log out
    @IBAction func onLogout(_ sender: Any) {
        let message = "Signing out will disable Face/Touch ID for future login. \n\nYou will have to type credentials manually to sign in."
        let alertController = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
        let signOutAction = UIAlertAction(title: "Sign me out", style: .default, handler: { action in
            self.logout()
        })
        let cancelAction = UIAlertAction(title: "Don't sign me out!", style: .default, handler: nil)
        alertController.addAction(signOutAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    // 1. sign user out; 2. set hasLoggedIn to false (Don't trigger FaceID next time the user goes back to the app); 3. navigate user back to the initial ViewController screen (aka. Sign In screen)
    func logout() {
        do {
            try Auth.auth().signOut()
        }
        catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        DispatchQueue.main.async {
            UserDefaults.standard.set(false, forKey: "hasLoggedIn")
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let initial = storyboard.instantiateInitialViewController()
        UIApplication.shared.keyWindow?.rootViewController = initial
    }
    
}
