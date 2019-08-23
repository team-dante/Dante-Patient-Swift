//
//  TimelineViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 8/21/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

struct Timeline {
    var room: String
    var startTime: Int
    var endTime: Int
}

class TimelineViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dateStrLabel: UILabel!
    var dateStr = ""
    var selectedDate = ""
    var userPhoneNum: String?
    var ref: DatabaseReference!
    
    var timelineArr = [Timeline]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideNavigationBar()
        
        self.dateStrLabel.text = dateStr
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 84
        tableView.allowsSelection = false
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 58, bottom: 0, right: 0)
        tableView.tableFooterView = UIView(frame: .zero)

        self.customizeTableView(tableView: tableView)
        
        ref = Database.database().reference()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        userPhoneNum = String((Auth.auth().currentUser?.email?.split(separator: "@")[0] ?? ""))
        // get room, startTime, and timeElapsed for each time tracking slot and append them to a list of struct Visit(room, startTime, timeElapsed); else get empty list
    ref.child("/PatientVisitsByDates/\(userPhoneNum!)/\(self.selectedDate)").observeSingleEvent(of: .value, with: { (snapshot) in
            if let timeObjs = snapshot.value as? [String: Any] {
                for timeObj in timeObjs {
                    if let obj = timeObj.value as? [String: Any] {
                        let room = obj["room"] as! String
                        let startTime = obj["startTime"] as! Int
                        let endTime = obj["endTime"] as! Int
                        self.timelineArr.append(Timeline(room: room, startTime: startTime, endTime: endTime))
                    }
                }
                self.timelineArr.sort(by: {$0.startTime > $1.startTime})
                self.tableView.reloadData()
            } else {
                self.timelineArr.removeAll()
                self.tableView.reloadData()
            }
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timelineArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let timeSlot = timelineArr[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimelineTableViewCell", for: indexPath) as! TimelineTableViewCell
        
        cell.allRows = timelineArr.count
        cell.currentIndexPath = indexPath
        cell.roomLabel.text = self.prettifyRoom(room: timeSlot.room)
        
        var endTimeStr = ""
        if timeSlot.endTime == 0 {
            endTimeStr = "PRESENT"
        } else {
            endTimeStr = "\(self.parseEndTime(endTime: timeSlot.endTime))"
        }
        
        let startTimeStr = self.parseStartTime(startTime: timeSlot.startTime)
        
        cell.durationLabel.text = "\(startTimeStr) - \(endTimeStr)"
        
        return cell
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.timelineArr.removeAll()
    }

}
