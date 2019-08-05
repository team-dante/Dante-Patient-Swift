//
//  VisitHistoryGraphViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/25/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Charts
import Firebase
import FirebaseAuth
import NVActivityIndicatorView

struct VisitForGraph {
    var room: String
    var timeElapsed: Int
}

class VisitsHistoryGraphViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var filterView: UIView!
    @IBOutlet weak var filterTableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var dateUILabel: UILabel!
    @IBOutlet var chartView: UIView!
    @IBOutlet weak var legendTableView: UITableView!
    @IBOutlet weak var pieChartView: PieChartView!
    @IBOutlet weak var barChartView: BarChartView!
    @IBOutlet weak var avgReminderLabel: UILabel!
    
    var selectedDate: String!
    let filterCat = ["Day", "Month", "Year"]
    var dates = [String]()
    var visitObjs = [VisitForGraph]()
    var filterTableViewIndexPath: IndexPath?
    var spinner: NVActivityIndicatorView!
    var colors: [UIColor] = []
    var ref: DatabaseReference!
    var userPhoneNum: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        userPhoneNum = String((Auth.auth().currentUser?.email?.split(separator: "@")[0] ?? ""))
        
        ref = Database.database().reference()
        customizeFilterView()
        customizeFilterTableView()
        customizeCollectionView()
        customizeLegendTableView()
        
        customizePieChart()
        customizeBarChart()
    }
    
    func customizeFilterView() {
        filterView.alpha = 0.0
        filterView.layer.cornerRadius = 20.0
        filterView.addShadow()
    }
    
    func customizeFilterTableView() {
        filterTableView.delegate = self
        filterTableView.dataSource = self
        filterTableView.estimatedRowHeight = 44.0
        filterTableView.isScrollEnabled = false
        filterTableView.allowsMultipleSelection = false
    }
    
    func customizeCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.layer.borderColor = UIColor("#adadad").cgColor
        collectionView.layer.borderWidth = 0.4
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    func customizeLegendTableView() {
        legendTableView.delegate = self
        legendTableView.dataSource = self
        legendTableView.estimatedRowHeight = 60.0
    }
    
    func customizePieChart() {
        self.pieChartView.legend.enabled = false
        self.pieChartView.backgroundColor = UIColor("#f9f9f9")
    }
    
    func customizeBarChart() {
        self.barChartView.drawBarShadowEnabled = false
        self.barChartView.drawBordersEnabled = false
        self.barChartView.doubleTapToZoomEnabled = false
        self.barChartView.drawValueAboveBarEnabled = true
        self.barChartView.legend.enabled = false
        
        let xAxis = self.barChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.enabled = false
        
        let leftAxis = self.barChartView.leftAxis
        leftAxis.labelFont = UIFont(name: "Poppins-Regular", size: 14)!
        leftAxis.labelTextColor = UIColor("#adadad")
        
        let rightAxis = self.barChartView.rightAxis
        rightAxis.enabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.showSpinner()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let indexPath = self.filterTableViewIndexPath {
                self.filterTableView.delegate?.tableView!(self.filterTableView, didSelectRowAt: indexPath)
            } else {
                self.filterTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
                self.filterTableView.delegate?.tableView!(self.filterTableView, didSelectRowAt: IndexPath(row: 0, section: 0))
            }
            DispatchQueue.main.async {
                self.loadDataBasedOnFilter()
            }
        }
    }
    
    // show loading status
    func showSpinner() {
        let view = UIApplication.shared.keyWindow!
        self.spinner = NVActivityIndicatorView(frame: view.frame, type: .lineScale, color: .white, padding: 250)
        view.addSubview(self.spinner)
        self.spinner.backgroundColor = UIColor("#31c1ff")
        self.spinner.startAnimating()
    }
    
    // clear spinner
    func removeSpinner() {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.spinner.removeFromSuperview()
        }
    }
    
    // set collectionView data based on filters (day, month, or year)
    func loadDataBasedOnFilter() {
        loadData { (success) -> Void in
            if success {
                self.processData()
            }
        }
    }
    
   func loadData(completion: @escaping (_ success: Bool) -> Void) {
        if let indexPath = self.filterTableViewIndexPath {
            if indexPath.row == 0 {
                
            ref.child("/PatientVisitsByDates/\(userPhoneNum!)").observeSingleEvent(of: .value, with: { (snapshot) in
                    self.dates.removeAll()
                    if let dateObjs = snapshot.value as? [String: Any] {
                        for dateObj in dateObjs {
                            self.dates.append(dateObj.key)
                        }
                        self.dates.sort(by: {$0 < $1})
                        print(self.dates)
                        self.collectionView.reloadData()
                        completion(true)
                    }
                })
            } else if indexPath.row == 1 {
                var month = Set<String>()
                self.dates.removeAll()
                ref.child("/PatientVisitsByDates/\(userPhoneNum!)").observeSingleEvent(of: .value, with: { (snapshot) in
                    if let dateObjs = snapshot.value as? [String: Any] {
                        for dateObj in dateObjs {
                            let key = (dateObj.key).prefix(7)
                            month.insert(String(key))
                        }
                        self.dates = Array(month)
                        self.dates.sort(by: {$0 < $1})
                        print(self.dates)
                        self.collectionView.reloadData()
                        completion(true)
                    }
                })
            } else {
                var year = Set<String>()
                self.dates.removeAll()
                ref.child("/PatientVisitsByDates/\(userPhoneNum!)").observeSingleEvent(of: .value, with: { (snapshot) in
                    if let dateObjs = snapshot.value as? [String: Any] {
                        for dateObj in dateObjs {
                            let key = (dateObj.key).prefix(4)
                            year.insert(String(key))
                        }
                        self.dates = Array(year)
                        if self.dates.count > 1 {
                            self.dates.sort(by: {$0 < $1})
                        }
                        print(self.dates)
                        self.collectionView.reloadData()
                        completion(true)
                    }
                })
            }
        }
    }

    func processData() {
        let index = IndexPath(item: self.dates.count-1, section: 0)
        self.collectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.collectionView.selectItem(at: index, animated: true, scrollPosition: [])
            self.collectionView(self.collectionView, didSelectItemAt: index)
        }
    }
    // estimate collectionView cell size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 80, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dates.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let date = self.dates[indexPath.item]
        print(date)
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GraphCollectionViewCell", for: indexPath) as? GraphCollectionViewCell {
            // cell stylings
            cell.backgroundColor = UIColor("#fff")
            cell.filterLabel.textColor = UIColor("#31c1ff")
            cell.layer.borderColor = UIColor("#31c1ff").cgColor
            cell.layer.borderWidth = 0.6
            cell.layer.cornerRadius = cell.frame.height/2
            cell.layer.masksToBounds = true
            
            if let index = self.filterTableViewIndexPath {
                if index.row == 0 {
                    let month = self.parseMonth(mon: String(date.split(separator: "-")[1]))
                    let day = String(date.split(separator: "-")[2])
                    cell.filterLabel.text = "\(month) \(day)"
                } else if index.row == 1 {
                    let month = self.parseMonth(mon: String(date.split(separator: "-")[1]))
                    cell.filterLabel.text = month
                } else {
                    cell.filterLabel.text = date
                }
            }
            return cell
        } else {
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)

        if let cell = collectionView.cellForItem(at: indexPath) as? GraphCollectionViewCell {
            cell.backgroundColor = UIColor("#31c1ff")
            cell.filterLabel.textColor = UIColor("#fff")
        }
        
        // get the selected date
        self.selectedDate = dates[indexPath.item]
        if let index = self.filterTableViewIndexPath {
            if index.row == 0 {
                self.barChartView.alpha = 0.0
                self.avgReminderLabel.alpha = 0.0
                self.pieChartView.alpha = 1.0
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let parsedDate = dateFormatter.date(from: self.selectedDate)
                
                // set the date string for the UIView at the top
                let f = DateFormatter()
                let month = self.parseMonth(mon: String(self.selectedDate.split(separator: "-")[1]))
                let day = String(self.selectedDate.split(separator: "-")[2])
                let year = String(self.selectedDate.split(separator: "-")[0])
                let weekday = f.weekdaySymbols[Calendar.current.component(.weekday, from: parsedDate!)-1]
                self.dateUILabel.text = "\(weekday), \(month) \(day), \(year)"
                
                var dict: [String:[Int]] = [:]
            ref.child("/PatientVisitsByDates/\(userPhoneNum!)/\(self.selectedDate!)").observeSingleEvent(of: .value, with: { (snapshot) in
                    if let timeObjs = snapshot.value as? [String: Any] {
                        self.visitObjs.removeAll()
                        for timeObj in timeObjs {
                            if let obj = timeObj.value as? [String: Any] {
                                let room = obj["room"] as? String
                                let timeElapsed = obj["timeElapsed"] as? Int
                                
                                dict[room!, default: []].append(timeElapsed!)
                            }
                        }
                        print(dict)
                        let newdict = dict.map { (i) in
                            return (i.key, i.value.reduce(0,+))
                        }
                        self.visitObjs = newdict.map { (i) in
                            return VisitForGraph(room: i.0, timeElapsed: i.1)
                        }
                        self.removeSpinner()
                        self.customizePieCharts(dataObj: self.visitObjs)
                        self.legendTableView.reloadData()
                    } else {
                        self.visitObjs.removeAll()
                        self.legendTableView.reloadData()
                    }
                })
                
            } else if index.row == 1 {
                self.barChartView.alpha = 1.0
                self.avgReminderLabel.alpha = 1.0
                self.pieChartView.alpha = 0.0
                
                let year = String(self.selectedDate.split(separator: "-")[0])

                var monthDict = [[(String, Int)]]()
                var acc: [String:[Int]] = [:]

                ref.child("/PatientVisitsByDates/\(userPhoneNum!)/").queryStarting(atValue: nil, childKey: "\(self.selectedDate!)-01")
                .observeSingleEvent(of: .value, with: { (snapshot) in
                    if let dateObjs = snapshot.value as? [String: Any] {
                        self.visitObjs.removeAll()
                        for dateObj in dateObjs {
                            let key = dateObj.key
                            if key.contains(self.selectedDate) {
                                print(key)
                                if let timeObjs = dateObj.value as? [String: Any] {
                                    var dict: [String:[Int]] = [:]

                                    for timeObj in timeObjs {
                                        if let obj = timeObj.value as? [String: Any] {
                                            let room = obj["room"] as? String
                                            let timeElapsed = obj["timeElapsed"] as? Int
                                            dict[room!, default: []].append(timeElapsed!)
                                        }
                                    }
                                    let newdict = dict.map { (i) in
                                        return (i.key, i.value.reduce(0,+))
                                    }
                                    monthDict.append(newdict)
                                }
                            }
                        }
                        for data in monthDict {
                            for room in data {
                                acc[room.0, default: []].append(room.1)
                            }
                        }
                        let avg = acc.map { (i) in
                            return (i.key, i.value.reduce(0,+)/i.value.count)
                        }
                        self.visitObjs = avg.map { (i) in
                            return VisitForGraph(room: i.0, timeElapsed: i.1)
                        }
                        self.removeSpinner()
                        self.customizeBarCharts(dataObj: self.visitObjs)
                        self.legendTableView.reloadData()
                    } else {
                        self.visitObjs.removeAll()
                        self.legendTableView.reloadData()
                    }
                })
                self.dateUILabel.text = year
            } else {
                self.barChartView.alpha = 1.0
                self.avgReminderLabel.alpha = 1.0
                self.pieChartView.alpha = 0.0
                
                var yearDict = [[(String, Int)]]()
                var acc: [String:[Int]] = [:]
                
                ref.child("/PatientVisitsByDates/\(userPhoneNum!)/").queryStarting(atValue: nil, childKey: "\(self.selectedDate!)-01-01")
                    .observeSingleEvent(of: .value, with: { (snapshot) in
                        if let dateObjs = snapshot.value as? [String: Any] {
                            self.visitObjs.removeAll()
                            for dateObj in dateObjs {
                                let key = dateObj.key
                                if key.contains(self.selectedDate) {
                                    print(key)
                                    if let timeObjs = dateObj.value as? [String: Any] {
                                        var dict: [String:[Int]] = [:]
                                        
                                        for timeObj in timeObjs {
                                            if let obj = timeObj.value as? [String: Any] {
                                                let room = obj["room"] as? String
                                                let timeElapsed = obj["timeElapsed"] as? Int
                                                dict[room!, default: []].append(timeElapsed!)
                                            }
                                        }
                                        let newdict = dict.map { (i) in
                                            return (i.key, i.value.reduce(0,+))
                                        }
                                        yearDict.append(newdict)
                                    }
                                }
                            }
                            for data in yearDict {
                                for room in data {
                                    acc[room.0, default: []].append(room.1)
                                }
                            }
                            let avg = acc.map { (i) in
                                return (i.key, i.value.reduce(0,+)/i.value.count)
                            }
                            self.visitObjs = avg.map { (i) in
                                return VisitForGraph(room: i.0, timeElapsed: i.1)
                            }
                            self.removeSpinner()
                            self.customizeBarCharts(dataObj: self.visitObjs)
                            self.legendTableView.reloadData()
                        } else {
                            self.visitObjs.removeAll()
                            self.legendTableView.reloadData()
                        }
                    })
                self.dateUILabel.text = "Year"
            }
        }
    }
    
    func customizePieCharts(dataObj: [VisitForGraph]) {
        self.pieChartView.animate(xAxisDuration: 1.4, easingOption: .easeOutBack)
        let entries = (0..<dataObj.count).map { (i) -> PieChartDataEntry in
            return PieChartDataEntry(value: Double(dataObj[i].timeElapsed)/60.0, label: self.roomGraphLabel(room: dataObj[i].room))
        }
        
        let pieChartDataSet = PieChartDataSet(entries: entries, label: nil)
        pieChartDataSet.colors = colorsOfCharts(numberOfColor: dataObj.count)
        
        let pieChartData = PieChartData(dataSet: pieChartDataSet)
        let pFormatter = NumberFormatter()
        pFormatter.positiveSuffix = " min"
        pieChartData.setValueFormatter(DefaultValueFormatter(formatter: pFormatter))
        
        pieChartData.setValueFont(UIFont(name: "Poppins-Bold", size: 15)!)
        pieChartData.setValueTextColor(UIColor("#fff"))
        self.pieChartView.data = pieChartData
    }
    
    func customizeBarCharts(dataObj: [VisitForGraph]) {
        self.barChartView.animate(yAxisDuration: 1.0)
        let entries = (0..<dataObj.count).map { (i) -> BarChartDataEntry in
            return BarChartDataEntry(x: Double(i), y: Double(dataObj[i].timeElapsed)/60.0)
        }
//        let xAxisRooms = dataObj.map { (i) -> String in return i.room }
//        self.barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: xAxisRooms)
//        self.barChartView.xAxis.granularity = 1

        let barChartDataSet = BarChartDataSet(entries: entries, label: "On average")
        barChartDataSet.drawValuesEnabled = true
        
        barChartDataSet.colors = colorsOfCharts(numberOfColor: dataObj.count)

        let barChartData = BarChartData(dataSet: barChartDataSet)
        barChartData.setValueFont(UIFont(name: "Poppins-Regular", size: 14)!)
        barChartData.barWidth = 0.6
        self.barChartView.data = barChartData
    }
    
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
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? GraphCollectionViewCell {
            cell.backgroundColor = UIColor("#fff")
            cell.filterLabel.textColor = UIColor("#31c1ff")
            cell.layer.borderColor = UIColor("#31c1ff").cgColor
            cell.layer.borderWidth = 0.6
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === filterTableView {
            return self.filterCat.count
        } else {
            return self.visitObjs.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === filterTableView {
            let filter = self.filterCat[indexPath.row]
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "filterTableViewCell", for: indexPath) as! filterTableViewCell
            
            cell.filterLabel.text = filter
            
            return cell
        } else if tableView === legendTableView {

            let cell = tableView.dequeueReusableCell(withIdentifier: "LegendTableViewCell", for: indexPath) as! LegendTableViewCell
            let legend = self.visitObjs[indexPath.row]
            let color = self.colors[indexPath.row]
            cell.colorView.backgroundColor = color
            cell.roomLabel.text = self.prettifyRoom(room: legend.room)
            let timeSpent = (Double(legend.timeElapsed) / 60.0 * 100).rounded() / 100
            cell.timeLabel.text = "\(timeSpent) min"
            
            return cell
        }
        return UITableViewCell()

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView === filterTableView {
            self.filterTableViewIndexPath = indexPath
            let cell = tableView.cellForRow(at: indexPath) as! filterTableViewCell
            cell.selectionStyle = .none
            cell.checkBtn.image = UIImage(named: "checkBtn")
            filterView.fadeOut()
            self.loadDataBasedOnFilter()
        } else if tableView === legendTableView {
            let cell = tableView.cellForRow(at: indexPath) as! LegendTableViewCell
            cell.selectionStyle = .none
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView === filterTableView {
            let cell = tableView.cellForRow(at: indexPath) as! filterTableViewCell
            cell.checkBtn.image = UIImage(named: "uncheckBtn")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        filterView.alpha = 0.0
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        if touch?.view != filterView {
            filterView.fadeOut()
        }
    }
}
