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
        
        // configure tableView
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
        
        self.loadData()
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
    
    func loadData() {
        var dict: [String:[Int]] = [:]
        var totalTime = 0
        ref.child("/PatientVisitsByDates/\(userPhoneNum!)/\(date)")
            .observeSingleEvent(of: .value, with: { (snapshot) in
                
                if self.roomObjs.count != 0 {
                    self.roomObjs.removeAll()
                }
                
                if let timeObjs = snapshot.value as? [String: Any] {
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
                    // ex. [CTRoom: 3575]
                    let newdict = dict.map { (i) in
                        return (i.key, i.value.reduce(0,+))
                    }
                    // conver to VisitForGraph obj with room = CTRoom and timeElapsed = 3575
                    self.roomObjs = newdict.map { (i) in
                        return Room(name: i.0, timeElapsed: i.1)
                    }
                    self.roomObjs.sort(by: {$0.name < $1.name})
                    self.customizePieCharts(dataObj: self.roomObjs)
                    // reload table
                    self.tableView.reloadData()
                    self.totalTimeLabel.text = self.parseTotalTime(timeElapsed: totalTime)
                } else {
                    self.roomObjs.removeAll()
                    self.tableView.reloadData()
                }
            })
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
            
            // match color in the pie chart
            let pin = CAShapeLayer()
            pin.path = UIBezierPath(ovalIn: CGRect(x: 16, y: 17, width: 20.0, height: 20.0)).cgPath
            pin.fillColor = color.cgColor
            cell.layer.addSublayer(pin)
            
            cell.roomLabel.text = self.prettifyRoom(room: room.name)
            
            // round minutes to two decimal places
            let timeSpent = (Double(room.timeElapsed) / 60.0 * 100).rounded() / 100
            cell.timeElapsedLabel.text = "\(timeSpent) min"
            
            return cell
        }
        return UITableViewCell()
    }
    
    // --- IBActions ---
    @IBAction func onRefresh(_ sender: Any) {
        self.loadData()
    }
    
    @IBAction func onClickDetails(_ sender: Any) {
        self.performSegue(withIdentifier: "TimelineSegue", sender: nil)
    }
    
    // clear roomObjs array
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.roomObjs.removeAll()
    }
    
    // pass date strings to the next VC (TimelineViewController)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let timelineVC = segue.destination as! TimelineViewController
        timelineVC.dateStr = self.dateStr.text!
        timelineVC.selectedDate = self.date
    }
}
