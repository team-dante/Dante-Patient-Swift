//
//  PinRefViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/12/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Firebase

struct Staff {
    var pinColor: String
    var room: String
    var name: String
}

class PinRefViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var titleView: UIView!
    
    var ref: DatabaseReference!
    
    let trackedStaff: Set<String> = ["111", "222", "333", "444", "555"]
    var staffArr = [Staff]()
    
    // For iOS 10 only
    private lazy var shadowLayer: CAShapeLayer = CAShapeLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.rowHeight = 70
        
        self.view.backgroundColor = UIColor(white: 1, alpha: 0.5)
    
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
            self.staffArr = []
            if let allStaff = snapshot.value as? [String: Any] {
                for staff in allStaff {
//                    let staffPhoneNum = staff.key
//                    if self.trackedStaff.contains(staffPhoneNum) {
                        if let staff = staff.value as? [String: String] {
                            let room = staff["room"]! // e.g. "CT"
                            if room != "Private" {
                                let lastName = staff["lastName"]!
                                let color = staff["pinColor"]!
                                let name = "Dr. \(lastName)"
                                let formattedRoomStr = self.prettifyRoom(room: room)
                                
                                self.staffArr.append(Staff(pinColor: color, room: formattedRoomStr, name: name))
                            }
                        }
//                    }
                }
                self.staffArr.sort(by: { $0.name < $1.name })
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
        return self.staffArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PinRefTableViewCell", for: indexPath) as? PinRefTableViewCell {
            
            let staff = self.staffArr[indexPath.row]
            
            // parse color
            let color = staff.pinColor
            let rgb = color.split(separator: "-")
            let r = CGFloat(Int(rgb[0])!)
            let g = CGFloat(Int(rgb[1])!)
            let b = CGFloat(Int(rgb[2])!)
            
            let circleLayer = CAShapeLayer()
            circleLayer.path = UIBezierPath(ovalIn: CGRect(x: 20.0, y: 16.0, width: 18.0, height: 18.0)).cgPath
            circleLayer.fillColor = UIColor(red: r/255, green: g/255, blue: b/255, alpha: 1.0).cgColor
            circleLayer.strokeColor = UIColor.black.cgColor

            let rectLayer = CAShapeLayer()
            rectLayer.path = UIBezierPath(rect: CGRect(x: 28.0, y: 34.0, width: 2.0, height: 20.0)).cgPath
            rectLayer.fillColor = UIColor.black.cgColor

            cell.layer.addSublayer(circleLayer)
            cell.layer.addSublayer(rectLayer)
            
            cell.docLabel.text = staff.name
            cell.roomLabel.text = staff.room
            
            cell.setNeedsDisplay()
            
            return cell
        }
        return UITableViewCell()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSections = 0
        if self.staffArr.count != 0 {
            tableView.separatorStyle = .singleLine
            numOfSections = 1
            tableView.backgroundView = nil
        } else {
            let defaultLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            defaultLabel.text = "Physicians may choose to remain private in the meantime"
            defaultLabel.textColor = UIColor("#919191")
            defaultLabel.textAlignment = .center
            defaultLabel.numberOfLines = 0
            tableView.backgroundView = defaultLabel
            tableView.separatorStyle = .none
        }
        return numOfSections
    }
}
