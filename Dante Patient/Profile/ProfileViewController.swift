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
import FirebaseStorage
import PassKit

class ProfileViewController: UIViewController, PKAddPassesViewControllerDelegate {
    
    
    @IBOutlet weak var walletBtnView: UIView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var phoneNumLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var surveyCard: UIView!
    @IBOutlet weak var qrCodeImageView: UIImageView!
    var ref: DatabaseReference!
    var userPhoneNumber : String!
    var qrCodeLink : String!
    var pass : PKPass!
    
    func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
        print("enter DidFinish")
        let passLib = PKPassLibrary()

        // Get your pass
        guard let pass = self.pass else { return }

        if passLib.containsPass(pass) {
            print("if start")

            // Show alert message for example
            let alertController = UIAlertController(title: "", message: "Successfully added to Wallet", preferredStyle: .alert)

            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                controller.dismiss(animated: true, completion: nil)
            }))

            controller.show(alertController, sender: nil)
            print("if end")

        } else {
            // Cancel button pressed
            print("else start");
            controller.dismiss(animated: true, completion: nil)
            print("else end");
        }
    }
    
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
        let pkButton = PKAddPassButton()
        // !important: ADD TARGET TO BUTTON BEFORE ADDING TO SUBVIEW
        pkButton.addTarget(self, action: #selector(walletPressed(sender:)), for: UIControl.Event.touchUpInside)
        walletBtnView.addSubview(pkButton)
        
        let cardComponentGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleFeedbackPressed(_:)))
        self.surveyCard.addGestureRecognizer(cardComponentGesture)
        
        // init Firebase
        ref = Database.database().reference()

        // customize logout button
        logoutButton.layer.cornerRadius = logoutButton.frame.height/2.4
        logoutButton.layer.masksToBounds = true
        
    }
    
    @objc func walletPressed(sender: UIButton) {
        self.wallet(phoneNum: userPhoneNumber)
    }
    
    
    func wallet(phoneNum: String) {
        let pathReference = Storage.storage().reference(withPath: "userPkpass/\(phoneNum).pkpass")
        pathReference.getData(maxSize: 10 * 1024 * 1024) { (downloadedData, error) in
            if error != nil {
                let alert = UIAlertController(title: "Information", message: "Your personal wallet is not ready yet. Please contact the developers.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                
                self.present(alert, animated: true)
            } else {
                // data for userPkpass/...pkpass is returned
                do {
                    self.pass = try PKPass(data: downloadedData! as Data)
                    let vc = PKAddPassesViewController(pass: self.pass)
                    self.present(vc!, animated: true)
                } catch {
                    print("ERROR WITH PASSKIT")
                }
                
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let user = Auth.auth().currentUser;
        if let email = user?.email {
            // get current user's phone number
            self.userPhoneNumber = String(email.split(separator: "@")[0])
            self.phoneNumLabel.text = "phone: \(userPhoneNumber!)"
        
            
            // if userPhoneNumber == phone number stored in database, pull out the user's full name
            ref.child("Patients").queryOrdered(byChild: "patientPhoneNumber").queryEqual(toValue: userPhoneNumber).observeSingleEvent(of: .value, with: { (snapshot) in
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
        
        
        // extract qrCodeLink from Firebase Database
        ref.child("Patients").queryOrdered(byChild: "patientPhoneNumber").queryEqual(toValue: self.userPhoneNumber).observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                let postDict = snapshot.value as? [String: AnyObject]
                for (_, value) in postDict! {
                    self.qrCodeLink = value["qrCodeLink"] as? String
                    // get reference to the qrCode.jpg file
                    let httpsReference = Storage.storage().reference(forURL: self.qrCodeLink!)
                    // allows to download up to 10 MB file (10 * 1024 * 1024 = 10 MB)
                    // download qrCode.jpg file
                    httpsReference.getData(maxSize: 10 * 1024 * 1024, completion: { (downloadedData, error) in
                        if error != nil {
                            print("ERROR DOWNLOADING IMAGE")
                        } else {
                            // convert downloadedData from jpeg to CIImage
                            let imageCII = CIImage(data: downloadedData!)
                            // scale the width and height for the qr code
                            let scaleX = self.qrCodeImageView.frame.width / (imageCII?.extent.size.width)!
                            let scaleY = self.qrCodeImageView.frame.height / (imageCII?.extent.size.height)!
                            let transformedImage = imageCII?.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
                            
                            self.qrCodeImageView.image = UIImage(ciImage: transformedImage!)
                        }
                    })
                }

            } else {
                print("This patient's information does not exist in Patient table.")
            }
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
