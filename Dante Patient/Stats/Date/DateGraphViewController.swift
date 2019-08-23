//
//  DateGraphViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 8/20/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Charts
import Firebase
import FirebaseAuth

struct Room {
    var name: String
    var timeElapsed: Int
}

class DateGraphViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var pieChartView: PieChartView!
    @IBOutlet weak var dateStr: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalTimeLabel: UILabel!
    
    var date = ""
    var totalTime = 0
    var colors = [UIColor]()
    var userPhoneNum: String?
    var ref: DatabaseReference!
    var roomObjs = [Room]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        pieChartView.addShadow()
        pieChartView.legend.enabled = false
        pieChartView.backgroundColor = UIColor("#fff")
        pieChartView.layer.cornerRadius = 20
        pieChartView.layer.masksToBounds = true
        
        changeDateLabel()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = true
        tableView.rowHeight = 54
        tableView.allowsSelection = false
        self.customizeTableView(tableView: tableView)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        userPhoneNum = String((Auth.auth().currentUser?.email?.split(separator: "@")[0] ?? ""))
        
        var dict: [String:[Int]] = [:]
        ref.child("/PatientVisitsByDates/\(userPhoneNum!)/\(date)")
            .observeSingleEvent(of: .value, with: { (snapshot) in
                if let timeObjs = snapshot.value as? [String: Any] {
                    for timeObj in timeObjs {
                        if let obj = timeObj.value as? [String: Any] {
                            let room = obj["room"] as! String
                            let inSession = obj["inSession"] as! Bool
                            let startTime = obj["startTime"] as! Int
                            var timeElapsed = 0
                            if inSession {
                                timeElapsed = Int(NSDate().timeIntervalSince1970) - startTime
                            } else {
                                let endTime = obj["endTime"] as! Int
                                timeElapsed = endTime - startTime
                            }
                            // use defaultdict (like Python);
                            // ex: [CTRoom: [1230, 2345]] in secs
                            dict[room, default: []].append(timeElapsed)
                        }
                    }
                    // add up all time tracking data for that room of that single day
                    // ex. [CTRoom: 3575]
                    let newdict = dict.map { (i) in
                        return (i.key, i.value.reduce(0,+))
                    }
                    // conver to VisitForGraph obj with room = CTRoom and timeElapsed = 3575
                    self.roomObjs = newdict.map { (i) in
                        return Room(name: i.0, timeElapsed: i.1)
                    }
                    self.customizePieCharts(dataObj: self.roomObjs)


                    self.tableView.reloadData()
                self.tableView.heightAnchor.constraint(equalToConstant: self.tableView.contentSize.height)
                } else {
                    self.roomObjs.removeAll()
                    self.tableView.reloadData()
                }
            })
        totalTimeLabel.text = self.parseTotalTime(timeElapsed: totalTime)
    }
    
    func changeDateLabel() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let parsedDate = dateFormatter.date(from: self.date)
        
        // set the date string for the UIView at the top
        let f = DateFormatter()
        let month = self.parseMonth(mon: String(self.date.split(separator: "-")[1]))
        let day = String(self.date.split(separator: "-")[2])
        let year = String(self.date.split(separator: "-")[0])
        let weekday = f.weekdaySymbols[Calendar.current.component(.weekday, from: parsedDate!)-1].prefix(3)
        self.dateStr.text = "\(weekday) \(month) \(day), \(year)"
    }
    
    func customizePieCharts(dataObj: [Room]) {
        // pie chart animation
        self.pieChartView.animate(xAxisDuration: 1.4, easingOption: .easeOutBack)
        // pie chart value = time spent at each room in minutes; label = room
        let entries = (0..<dataObj.count).map { (i) -> PieChartDataEntry in
            return PieChartDataEntry(value: Double(dataObj[i].timeElapsed)/60.0, label: dataObj[i].name)
        }
        // create dataset for pie chart; generate random colors for each room
        let pieChartDataSet = PieChartDataSet(entries: entries, label: nil)
        pieChartDataSet.colors = self.colorsOfCharts(numberOfColor: dataObj.count)
        
        // add min to the value
        let pieChartData = PieChartData(dataSet: pieChartDataSet)
        let pFormatter = NumberFormatter()
        pFormatter.positiveSuffix = " min"
        pieChartData.setValueFormatter(DefaultValueFormatter(formatter: pFormatter))
        
        pieChartData.setValueFont(UIFont(name: "Poppins-Bold", size: 15)!)
        pieChartData.setValueTextColor(UIColor("#fff"))
        self.pieChartView.data = pieChartData
    }
    
    // generate random colors to display time tracking data for each room
    private func colorsOfCharts(numberOfColor: Int) -> [UIColor] {
        self.colors = []
        for _ in 0..<numberOfColor {
            let red = Double(arc4random_uniform(256))
            let green = Double(arc4random_uniform(256))
            let blue = Double(arc4random_uniform(256))
            let color = UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1)
            self.colors.append(color)
        }
        return self.colors
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return roomObjs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "GraphViewCell", for: indexPath) as? GraphViewCell {
            let room = self.roomObjs[indexPath.row]
            let color = self.colors[indexPath.row]
            cell.colorView.backgroundColor = color
            cell.roomLabel.text = self.prettifyRoom(room: room.name)
            
            // round minutes to two decimal places
            let timeSpent = (Double(room.timeElapsed) / 60.0 * 100).rounded() / 100
            cell.timeElapsedLabel.text = "\(timeSpent) min"
            
            return cell
        }
        return UITableViewCell()
    }
    
    @IBAction func onClickDetails(_ sender: Any) {
        self.performSegue(withIdentifier: "TimelineSegue", sender: nil)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.roomObjs.removeAll()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let timelineVC = segue.destination as! TimelineViewController
        timelineVC.dateStr = self.dateStr.text!
        timelineVC.selectedDate = self.date
    }
}
