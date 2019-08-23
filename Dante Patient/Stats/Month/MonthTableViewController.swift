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
    var monthArr = [Visit]()
    var selectedMonth = ""
    var avgTimeSpent = 0
    
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
        
        self.loadData()
    }
    
    func loadData() {
        var dict: [String:[Int]] = [:]
        ref.child("/PatientVisitsByDates/\(userPhoneNum!)").observeSingleEvent(of: .value, with: { (snapshot) in
            if self.monthArr.count > 0 {
                self.monthArr.removeAll()
            }
            
            if let dateObjs = snapshot.value as? [String: Any] {
                for dateObj in dateObjs {
                    // e.g. 2019-07
                    let key = String((dateObj.key).prefix(7))
                    
                    // calculate the total visit time for each day
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
                    // default dict: e.g. [2019-07 : [104, 120]]
                    dict[key, default: []].append(totalTime)
                }
                // e.g. [2019-07 : <Avg Time>]
                let avg = dict.map { (i) in
                    return (i.key, i.value.reduce(0,+)/i.value.count)
                }
                // transform to Visit object
                self.monthArr = avg.map { (i) in
                    return Visit(date: i.0, timeElapsed: i.1)
                }
                self.monthArr.sort(by: {$0.date > $1.date})
                self.tableView.reloadData()
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.monthArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "MonthTableViewCell", for: indexPath) as? MonthTableViewCell {
            let visit = self.monthArr[indexPath.row]
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let visit = self.monthArr[indexPath.row]
        
        self.avgTimeSpent = visit.timeElapsed
        self.selectedMonth = visit.date
        
        self.performSegue(withIdentifier: "MonthGraphSegue", sender: nil)
    }
    
    @IBAction func onRefresh(_ sender: Any) {
        self.loadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.monthArr.removeAll()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let graphVC = segue.destination as? MonthGraphViewController {
            graphVC.month = self.selectedMonth
            graphVC.avgTime = self.avgTimeSpent
        }
    }

}
