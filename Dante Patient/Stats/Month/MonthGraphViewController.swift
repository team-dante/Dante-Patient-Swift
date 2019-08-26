//
//  MonthGraphViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 8/22/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Charts
import Firebase
import FirebaseAuth

class MonthGraphViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var barChartView: BarChartView!
    @IBOutlet weak var monthStr: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var avgTimeLabel: UILabel!
    
    var month = ""
    var colors = [UIColor]()
    var userPhoneNum: String?
    var ref: DatabaseReference!
    var roomObjs = [Room]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ref = Database.database().reference()
        
        barChartView.addShadow()
        barChartView.legend.enabled = false
        barChartView.backgroundColor = UIColor("#fff")
        barChartView.layer.cornerRadius = 20
        barChartView.layer.masksToBounds = true
        
        // customize axis
        let xAxis = self.barChartView.xAxis
        xAxis.enabled = false
        
        let leftAxis = self.barChartView.leftAxis
        leftAxis.labelFont = .systemFont(ofSize: 12)
        leftAxis.labelTextColor = UIColor("#adadad")
        
        let rightAxis = self.barChartView.rightAxis
        rightAxis.enabled = false
        
        changeDateLabel()
        
        // configure tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = true
        tableView.rowHeight = 50
        tableView.allowsSelection = false
        self.customizeTableView(tableView: tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        userPhoneNum = String((Auth.auth().currentUser?.email?.split(separator: "@")[0] ?? ""))
        
        self.loadData()
    }
    
    func changeDateLabel() {
        let mon = self.parseMonth(mon: String(self.month.split(separator: "-")[1]))
        let year = String(self.month.split(separator: "-")[0])
        self.monthStr.text = "\(mon) \(year)"
    }
    
    func loadData() {
        var monthDict = [[(String, Int)]]()
        var acc: [String:[Int]] = [:]
        
        var totalTime = 0
        var visitCount = 0
        // if month = 2019-01
        // query start with month (e.g. 2019-01-01)
        ref.child("/PatientVisitsByDates/\(userPhoneNum!)/").queryStarting(atValue: nil, childKey: "\(self.month)-01")
            .observeSingleEvent(of: .value, with: { (snapshot) in
                
                if let dateObjs = snapshot.value as? [String: Any] {
                    if self.roomObjs.count > 0 {
                        self.roomObjs.removeAll()
                    }
                    
                    for dateObj in dateObjs {
                        let key = dateObj.key
                        
                        // if key contains the month (2019-01)
                        if key.contains(self.month) {
                            visitCount += 1
                            if let timeObjs = dateObj.value as? [String: Any] {
                                var dict: [String:[Int]] = [:]
                                // for each day; loop thru all time tracking objs
                                for timeObj in timeObjs {
                                    if let obj = timeObj.value as? [String: Any] {
                                        let room = obj["room"] as! String
                                        let inSession = obj["inSession"] as! Bool
                                        let startTime = obj["startTime"] as! Int
                                        var timeElapsed = 0
                                        
                                        // current room duration = now() - entry time
                                        if inSession {
                                            timeElapsed = Int(NSDate().timeIntervalSince1970) - startTime
                                            totalTime += timeElapsed
                                        } else {
                                            let endTime = obj["endTime"] as! Int
                                            timeElapsed = endTime - startTime
                                            totalTime += timeElapsed
                                        }
                                        // use defaultdict (like Python);
                                        // ex: [CTRoom: [1230, 2345]] in secs
                                        dict[room, default: []].append(timeElapsed)
                                    }
                                }
                                // add up all time tracking data for that room of that single day
                                let newdict = dict.map { (i) in
                                    return (i.key, i.value.reduce(0,+))
                                }
                                monthDict.append(newdict)
                            }
                        }
                    }
                    // monthDict structure: [[("femaleWaitingRoom", 111), ("exam1", 222)],
                    //                       [("CTRoom", 333), ("exam1", 444)]]
                    for data in monthDict {
                        for room in data {
                            acc[room.0, default: []].append(room.1)
                        }
                    }
                    // exam1 = 222 + 444 = 666/2 = 333
                    // avg = [("femaleWaitingRoom", 111), ("exam1", 333), ("CTRoom", 333)]
                    let avg = acc.map { (i) in
                        return (i.key, i.value.reduce(0,+)/i.value.count)
                    }
                    // convert to visitForGraph obj
                    self.roomObjs = avg.map { (i) in
                        return Room(name: i.0, timeElapsed: i.1)
                    }
                    self.roomObjs.sort(by: {$0.name < $1.name})

                    self.customizeBarCharts(dataObj: self.roomObjs)
                    self.tableView.reloadData()
                    self.avgTimeLabel.text = self.parseTotalTime(timeElapsed: totalTime / visitCount)

                } else {
                    self.roomObjs.removeAll()
                    self.tableView.reloadData()
                }
            })
    }
    
    func customizeBarCharts(dataObj: [Room]) {
        // animate bar chart
        self.barChartView.animate(yAxisDuration: 1.0)
        
        // bar char x-axis = temporarily indexes; y-axis = time tracking data in minutes
        let entries = (0..<dataObj.count).map { (i) -> BarChartDataEntry in
            return BarChartDataEntry(x: Double(i), y: Double(dataObj[i].timeElapsed)/60.0)
        }
        // x-axis can be formatted as strings to show rooms
        //        let xAxisRooms = dataObj.map { (i) -> String in return i.room }
        //        self.barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: xAxisRooms)
        //        self.barChartView.xAxis.granularity = 1
        let barChartDataSet = BarChartDataSet(entries: entries, label: nil)
        barChartDataSet.drawValuesEnabled = true
        
        // generate random colors for each bar
        barChartDataSet.colors = colorsOfCharts(numberOfColor: dataObj.count)
        
        let barChartData = BarChartData(dataSet: barChartDataSet)
        barChartData.setValueFont(.systemFont(ofSize: 12))
        barChartData.barWidth = 0.6
        self.barChartView.data = barChartData
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
            
            // match color in the pie chart
            cell.colorView.backgroundColor = color
            
            cell.roomLabel.text = self.prettifyRoom(room: room.name)
            
            // round minutes to two decimal places
            let timeSpent = (Double(room.timeElapsed) / 60.0 * 100).rounded() / 100
            cell.timeElapsedLabel.text = "\(timeSpent) min"
            
            return cell
        }
        return UITableViewCell()
    }
    
    @IBAction func onRefresh(_ sender: Any) {
        self.loadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.roomObjs.removeAll()
    }

}
