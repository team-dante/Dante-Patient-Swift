//
//  MonthTableViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 8/19/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class MonthTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var ref: DatabaseReference!
    var userPhoneNum: String?
    var dateArr = [Visit]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        ref = Database.database().reference()
        
        self.hideNavigationBar()
        self.customizeTableView(tableView: tableView)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        userPhoneNum = String((Auth.auth().currentUser?.email?.split(separator: "@")[0] ?? ""))
        
        var dict: [String:[Int]] = [:]
        self.dateArr.removeAll()
        ref.child("/PatientVisitsByDates/\(userPhoneNum!)").observeSingleEvent(of: .value, with: { (snapshot) in
            if let dateObjs = snapshot.value as? [String: Any] {
                for dateObj in dateObjs {
                    let key = String((dateObj.key).prefix(7))
                    var totalTime = 0
                    if let timeObjs = dateObj.value as? [String:Any] {
                        for timeObj in timeObjs {
                            if let obj = timeObj.value as? [String: Any] {
                                let inSession = obj["inSession"] as! Bool
                                let start = obj["startTime"] as! Int
                                if inSession {
                                    totalTime += Int(NSDate().timeIntervalSince1970) - start
                                } else {
                                    let end = obj["endTime"] as! Int
                                    totalTime += end - start
                                }
                            }
                        }
                    }
                    dict[key, default: []].append(totalTime)
                }
                let avg = dict.map { (i) in
                    return (i.key, i.value.reduce(0,+)/i.value.count)
                }
                self.dateArr = avg.map { (i) in
                    return Visit(date: i.0, timeElapsed: i.1)
                }
                self.dateArr.sort(by: {$0.date > $1.date})
                self.tableView.reloadData()
            }
        })
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dateArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "MonthTableViewCell", for: indexPath) as? MonthTableViewCell {
            let visit = self.dateArr[indexPath.row]
            let date = visit.date
            
            let month = self.parseMonth(mon: String(date.split(separator: "-")[1]))
            let year = String(date.split(separator: "-")[0])
            cell.monthLabel.text = "\(month) \(year)"
            
            let timeSpent = (Double(visit.timeElapsed) / 60.0 * 100).rounded() / 100
            cell.avgTimeLabel.text = "\(timeSpent) mins spent per visit"
            
            return cell
        } else {
            return UITableViewCell()
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
