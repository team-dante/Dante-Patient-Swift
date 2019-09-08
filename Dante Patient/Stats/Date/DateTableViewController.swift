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

struct Week {
    var startOfWeek: String
    var visit: [Visit]
}
struct Visit {
    var date: String
    var timeElapsed: Int
}

class DateTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var ref: DatabaseReference!
    var userPhoneNum: String?
    var selectedDate = ""
    var weekArr = [Week]()
    var selectedWeek = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = false
        
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
        var dateArr = [String:[Visit]]()
        
        ref.child("/PatientVisitsByDates/\(userPhoneNum!)").observeSingleEvent(of: .value, with: { (snapshot) in
            
            if self.weekArr.count != 0 {
                self.weekArr.removeAll()
            }
            
            if let dateObjs = snapshot.value as? [String: Any] {
                for dateObj in dateObjs {
                    
                    let date = dateObj.key
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
                    
                    let week = self.parseStartOfWeek(date: date)
                    
                    // e.g. Visit(date: 2019-07-08, timeElapsed: 103); in secs
                    dateArr[week, default: []].append(Visit(date: date, timeElapsed: totalTime))
                }
                // sort by date; reload table data
                
                for (key, value) in dateArr {
                    var visits = value
                    visits.sort(by: {$0.date > $1.date})
                    dateArr[key] = visits
                }
                self.weekArr = dateArr.map { (i) in
                    return Week(startOfWeek: i.key, visit: i.value)
                }
                self.weekArr.sort(by: {$0.startOfWeek > $1.startOfWeek})
                self.tableView.reloadData()
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.weekArr[section].visit.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 52.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor("#f1f1f1")
        
        let titleLabel = UILabel()
        titleLabel.frame = CGRect(x: 8, y: 10, width: tableView.frame.width/2, height: 40)
        let startOfWeek = self.weekArr[section].startOfWeek
        let endOfWeek = self.parseEndOfWeek(date: startOfWeek)
        
        let weekStr = self.parseWeek(firstDay: startOfWeek, lastDay: endOfWeek)
        
        titleLabel.text = weekStr
        titleLabel.font = UIFont(name: "Poppins-Bold", size: 19)
        titleLabel.textColor = UIColor("#5C7B8C")
        
        let button = UIButton(type: .system)
        button.setTitle("Details", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.setTitleColor(UIColor("#0070ff"), for: .normal)
        button.titleLabel?.textAlignment = .right
        button.frame = CGRect(x: self.tableView.frame.width - 70, y: 20, width: 70, height: 20)
        button.addTarget(self, action: #selector(showDetail(_:)), for: .touchUpInside)
        button.tag = section

        view.addSubview(titleLabel)
        view.addSubview(button)
        
        return view
    }
    
    @objc func showDetail(_ button: UIButton) {
        let section = button.tag
        self.selectedWeek = self.weekArr[section].startOfWeek
        self.performSegue(withIdentifier: "ShowWeekSegue", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "DateTableViewCell", for: indexPath) as? DateTableViewCell {
            let visit = self.weekArr[indexPath.section].visit[indexPath.row]
            
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
        if let cell = tableView.cellForRow(at: indexPath) as? DateTableViewCell {
            self.selectedDate = cell.dateLabel.text!
            self.performSegue(withIdentifier: "DateGraphSegue", sender: nil)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.weekArr.count
    }
    
    @IBAction func onRefresh(_ sender: Any) {
        self.loadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.weekArr.removeAll()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let graphVC = segue.destination as? DateGraphViewController {
            graphVC.date = self.selectedDate
        } else if let graphVC = segue.destination as? WeekGraphViewController {
            graphVC.startOfWeek = self.selectedWeek
        }
    }

}
