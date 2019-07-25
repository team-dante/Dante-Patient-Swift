//
//  TimeTrackingViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/20/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Firebase
import UIColor_Hex_Swift

import FirebaseAuth

struct Room {
    var endTime: Int!
    var room: String!
    var startTime: Int!
    var timeElapsed: Int!
    
}

class TimeTrackingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var ref: DatabaseReference!
    var dateToday: String!
    var userPhoneNum: String?
    var rooms = [Room]()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        
        dateToday = self.formattedDate()
        userPhoneNum = String((Auth.auth().currentUser?.email?.split(separator: "@")[0] ?? ""))
        
        ref = Database.database().reference()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        ref.child("/PatientVisitsByDates/\(userPhoneNum!)/\(dateToday!)").observe(.value, with: { (snapshot) in
            self.rooms = []
            if let timeObjs = snapshot.value as? [String: Any] {
                for timeObj in timeObjs {
                    if let obj = timeObj.value as? [String: Any] {
                        let room = obj["room"] as? String
                        let endTime = obj["endTime"] as? Int
                        let startTime = obj["startTime"] as? Int
                        let timeElapsed = obj["timeElapsed"] as? Int
                        self.rooms.append(Room(endTime: endTime!, room: room!, startTime: startTime!, timeElapsed: timeElapsed!))
                        self.rooms.sort(by: {$0.endTime > $1.endTime})
                        self.tableView.reloadData()
                    }
                }
            }
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSections = 0
        if self.rooms.count != 0 {
            tableView.separatorStyle = .singleLine
            numOfSections = 1
            tableView.backgroundView = nil
        } else {
            let defaultLabel: UILabel  = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            defaultLabel.text = "No time tracking data available"
            defaultLabel.textColor = UIColor("#9e9e9e")
            defaultLabel.textAlignment = .center
            tableView.backgroundView = defaultLabel
            tableView.separatorStyle = .none
        }
        return numOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let room = self.rooms[indexPath.row]
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CurrRoomTableViewCell", for: indexPath) as! CurrRoomTableViewCell
            
            cell.currRoom.text = self.prettifyRoom(room: room.room)
            cell.clockLabel.text = "\(self.parseTimeElapsed(timeElapsed: room.timeElapsed!))"
            cell.startTimeLabel.text = "Start: \(self.parseStartTime(startTime: room.startTime!))"
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PrevRoomsTableViewCell", for: indexPath) as! PrevRoomsTableViewCell
            cell.prevRoom.text = self.prettifyRoom(room: room.room)
            cell.timeElapsed.text = "\(self.parseTimeElapsed(timeElapsed: room.timeElapsed!))"
            
            return cell
        }
    }
}
