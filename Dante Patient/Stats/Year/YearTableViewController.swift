//
//  YearTableViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 8/19/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class YearTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var ref: DatabaseReference!
    var userPhoneNum: String?
    var yearArr = [Visit]()
    var selectedYear = ""
    
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
            if self.yearArr.count > 0 {
                self.yearArr.removeAll()
            }
            
            if let dateObjs = snapshot.value as? [String: Any] {
                for dateObj in dateObjs {
                    let key = String((dateObj.key).prefix(4))
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
                self.yearArr = avg.map { (i) in
                    return Visit(date: i.0, timeElapsed: i.1)
                }
                self.yearArr.sort(by: {$0.date > $1.date})
                self.tableView.reloadData()
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.yearArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "YearTableViewCell", for: indexPath) as? YearTableViewCell {
            let visit = self.yearArr[indexPath.row]
            
            let year = visit.date
            cell.yearLabel.text = "\(year)"
            
            let timeSpent = (Double(visit.timeElapsed) / 60.0 * 100).rounded() / 100
            cell.avgTimeLabel.text = "\(timeSpent) mins spent per visit"
            
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let visit = self.yearArr[indexPath.row]
        self.selectedYear = visit.date
        
        self.performSegue(withIdentifier: "YearGraphSegue", sender: nil)
    }
    
    
    @IBAction func onRefresh(_ sender: Any) {
        self.loadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.yearArr.removeAll()
    }

     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let graphVC = segue.destination as? YearGraphViewController {
            graphVC.year = self.selectedYear
        }
     }

    
}
