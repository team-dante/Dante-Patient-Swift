//
//  ActivateAcctViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/13/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class ActivateAcctViewController: UIViewController {

    @IBOutlet weak var phoneNum: Inputs!
    var ref: DatabaseReference!
    var spinner: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()

        // connecting to Firebase initially
        ref = Database.database().reference()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    // click cancel to dismiss the sign up page
    @IBAction func onCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // click Activate
    @IBAction func onActivate(_ sender: Any) {
        // unwrap phoneNum
        if let phone = phoneNum.text {
            self.showSpinner(onView: self.view)

            // search for Patient objects that has the unique phone number (return [{...}])
            ref.child("Patients").queryOrdered(byChild: "patientPhoneNumber").queryEqual(toValue: phone).observeSingleEvent(of: .value, with: { (snapshot) in
                
                // if patient exists
                if let patients = snapshot.value as? [String: Any] {
                    let email = "\(phone)@email.com"
                    var patientPin = ""
                    
                    // get the pin
                    for patient in patients {
                        if let patient = patient.value as? [String: String] {
                            let pin = patient["patientPin"]!
                            patientPin = "\(pin)ABCDEFG"
                        }
                    }
                    
                    // then create user
                    Auth.auth().createUser(withEmail: email, password: patientPin){ (user, error) in
                        if error == nil {
                            
                            // if no error, sign in directly; otherwise, display alerts
                            Auth.auth().signIn(withEmail: email, password: patientPin) {
                                (user, error) in
                                self.removeSpinner()

                                if error == nil {
                                    self.performSegue(withIdentifier: "signUpAndLoginSucess", sender: self)
                                }
                                else {
                                    self.showAlert(message: error!.localizedDescription)
                                }
                            }
                        } else {
                            self.removeSpinner()
                            self.showAlert(message: error!.localizedDescription)
                        }
                    }
                } // if thepatient does not exist
                else {
                    self.removeSpinner()
                    self.showAlert(message: "Sorry, our system cannot locate your records. Please confirm with our staff to activate your account")
                }
            })
        } else {
            print("Please Enter Phone Number")
        }
    }
    
    // tap outside to dismiss keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // utility function to display alerts
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: { action in
            self.phoneNum.text = ""
        })
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    // utility fxn for loading spinner
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
    
    func removeSpinner() {
        DispatchQueue.main.async {
            self.spinner?.removeFromSuperview()
            self.spinner = nil
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
