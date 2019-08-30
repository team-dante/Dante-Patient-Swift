//
//  PinRefViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/12/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Firebase

class PinRefViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var titleView: UIView!
    
    var ref: DatabaseReference!
    
    let trackedStaff: Set<String> = ["111", "222", "333", "444", "555"]
    var doctors = [[String: String]]()
    var docName = ["111":"Roa", "222":"Kuo", "333":"Gan", "444":"Shen", "555":"Moore"]
    
    // Assume we have a set number of doctors for now (would make the pin coloring scheme dynamic in future)
    var docDict: [String: UIImage] = [:]
    
    // For iOS 10 only
    private lazy var shadowLayer: CAShapeLayer = CAShapeLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        
        self.view.backgroundColor = UIColor(white: 1, alpha: 0.5)
        
        for i in 1...5 {
            let pin = i * 111;
            docDict[String(pin)] = UIImage(named: String(pin))
        }
        ref = Database.database().reference()
        
        let bottomBorder = CALayer()
        bottomBorder.frame = CGRect(x: 20.0, y: titleView.frame.height - 3, width: 70, height: 3.0)
        bottomBorder.backgroundColor = UIColor("#31c1ff").cgColor
        titleView.layer.addSublayer(bottomBorder)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // call observe to always listen for doctor location changes
        ref.child("StaffLocation").observe(.value, with: {(snapshot) in
            
            // clear doctors list data at refreshing
            self.doctors = []
            if let doctors = snapshot.value as? [String: Any] {
                for doctor in doctors {
                    let docPhoneNum = doctor.key
                    if self.trackedStaff.contains(docPhoneNum) {
                        if let doc = doctor.value as? [String: String] {
                            let room = doc["room"]! // e.g. "CTRoom"
                            if room != "Private" {
                                let name = "Dr. \(self.docName[docPhoneNum]!)"
                                
                                let formattedRoomStr = self.prettifyRoom(room: room)
                                let doctorDict = ["docPhoneNum": docPhoneNum, "room": formattedRoomStr, "docName": name]
                                self.doctors.append(doctorDict)
                            }
                        }
                    }
                }
                // reload the tableView immediately
                self.tableView.reloadData()
            }
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 11, *) {
        } else {
            // Exmaple: Add rounding corners on iOS 10
            visualEffectView.layer.cornerRadius = 9.0
            visualEffectView.clipsToBounds = true
            
            // Exmaple: Add shadow manually on iOS 10
            view.layer.insertSublayer(shadowLayer, at: 0)
            let rect = visualEffectView.frame
            let path = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: [.topLeft, .topRight],
                                    cornerRadii: CGSize(width: 9.0, height: 9.0))
            shadowLayer.frame = visualEffectView.frame
            shadowLayer.shadowPath = path.cgPath
            shadowLayer.shadowColor = UIColor.black.cgColor
            shadowLayer.shadowOffset = CGSize(width: 0.0, height: 1.0)
            shadowLayer.shadowOpacity = 0.2
            shadowLayer.shadowRadius = 3.0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.doctors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PinRefTableViewCell", for: indexPath)
        
        let doctor = self.doctors[indexPath.row]
        if let cell = cell as? PinRefTableViewCell {
            cell.pinImage.image = self.docDict[doctor["docPhoneNum"]!]
            cell.docLabel.text = doctor["docName"]
            cell.roomLabel.text = doctor["room"]
        }
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSections = 0
        if self.doctors.count != 0 {
            tableView.separatorStyle = .singleLine
            numOfSections = 1
            tableView.backgroundView = nil
        } else {
            let defaultLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            defaultLabel.text = "Doctors may choose to remain private in the meantime"
            defaultLabel.textColor = UIColor("#9e9e9e")
            defaultLabel.textAlignment = .center
            defaultLabel.numberOfLines = 0
            tableView.backgroundView = defaultLabel
            tableView.separatorStyle = .none
        }
        return numOfSections
    }
}
