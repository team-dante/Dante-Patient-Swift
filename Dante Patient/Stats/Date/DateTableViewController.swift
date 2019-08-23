//
//  DateTableViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 8/19/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

struct Visit {
    var date: String
    var timeElapsed: Int
}

class DateTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var ref: DatabaseReference!
    var userPhoneNum: String?
    var selectedDate = ""
    var dateArr = [Visit]()
    var timeSpent = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        ref = Database.database().reference()
        
        self.hideNavigationBar()
        self.customizeTableView(tableView: tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        userPhoneNum = String((Auth.auth().currentUser?.email?.split(separator: "@")[0] ?? ""))
        
        self.loadData()
    }
    
    func loadData() {
        ref.child("/PatientVisitsByDates/\(userPhoneNum!)").observeSingleEvent(of: .value, with: { (snapshot) in
            
            if self.dateArr.count != 0 {
                self.dateArr.removeAll()
            }
            
            if let dateObjs = snapshot.value as? [String: Any] {
                for dateObj in dateObjs {
                    var totalTime = 0
                    if let timeObjs = dateObj.value as? [String:Any] {
                        for timeObj in timeObjs {
                            if let obj = timeObj.value as? [String: Any] {
                                let inSession = obj["inSession"] as! Bool
                                let start = obj["startTime"] as! Int
                                
                                // curr room duration = now() - entry time
                                // past rooms = end time - entry time
                                if inSession {
                                    totalTime += Int(NSDate().timeIntervalSince1970) - start
                                } else {
                                    let end = obj["endTime"] as! Int
                                    totalTime += end - start
                                }
                            }
                        }
                    }
                    // e.g. Visit(date: 2019-07-08, timeElapsed: 103); in secs
                    self.dateArr.append(Visit(date: dateObj.key, timeElapsed: totalTime))
                }
                // sort by date; reload table data
                self.dateArr.sort(by: {$0.date > $1.date})
                self.tableView.reloadData()
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dateArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "DateTableViewCell", for: indexPath) as? DateTableViewCell {
            let visit = self.dateArr[indexPath.row]
            
            cell.dateLabel.text = visit.date
            
            let duration = (Double(visit.timeElapsed) / 60.0 * 100).rounded() / 100
            cell.totalTimeLabel.text = "\(duration) MINS SPENT"
            
            // format weekday
            let f = DateFormatter()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let parsedDate = dateFormatter.date(from: visit.date)
            let weekday = f.weekdaySymbols[Calendar.current.component(.weekday, from: parsedDate!)-1]
            cell.weekdayLabel.text = weekday
            
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let visit = self.dateArr[indexPath.row]
        self.timeSpent = visit.timeElapsed
        
        if let cell = tableView.cellForRow(at: indexPath) as? DateTableViewCell {
            self.selectedDate = cell.dateLabel.text!
            self.performSegue(withIdentifier: "DateGraphSegue", sender: nil)
        }
    }
    
    @IBAction func onRefresh(_ sender: Any) {
        self.loadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.dateArr.removeAll()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let graphVC = segue.destination as? DateGraphViewController {
            graphVC.date = self.selectedDate
            graphVC.totalTime = self.timeSpent
        }
    }

}
