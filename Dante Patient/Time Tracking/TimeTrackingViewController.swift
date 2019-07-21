//
//  TimeTrackingViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/20/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Firebase
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
    
    // return today's date in YYYY-MM-DD format
    func formattedDate() -> String {
        let calendar = Calendar.current
        let today = Date()
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)
        let formattedMonth = month < 10 ? "0\(month)" : "\(month)"
        let formattedDay = day < 10 ? "0\(day)" : "\(day)"
        return "\(year)-\(formattedMonth)-\(formattedDay)"
    }
    
    func prettifyRoom(room: String) -> String {
        switch room {
        case "femaleWaitingRoom":
            return "Female Waiting Room"
        case "CTRoom":
            return "CT Room"
        case "exam1":
            return "Exam 1 Room"
        default:
            return ""
        }
    }
    
    func parseTimeElapsed(timeElapsed: Int) -> String {
        let hr = timeElapsed / 3600
        let sec = timeElapsed % 60
        let min = (timeElapsed % 3600) / 60
        let hrStr = (hr < 10) ? "0\(hr)" : "\(hr)"
        let minStr = (min < 10) ? "0\(min)" : "\(min)"
        let secStr = (sec < 10) ? "0\(sec)" : "\(sec)"
        return "\(hrStr):\(minStr):\(secStr)"
    }
    
    func parseStartTime(startTime: Int) -> String {
        let date = NSDate(timeIntervalSince1970: TimeInterval(startTime))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        let parsedTime = dateFormatter.string(from: date as Date)
        return parsedTime
    }
}
