//
//  VisitHistoryGraphViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/25/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Charts

struct VisitForGraph {
    var room: String
    var timeElapsed: Int
}

class VisitsHistoryGraphViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var filterView: UIView!
    @IBOutlet weak var filterTableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var dateUILabel: UILabel!
    @IBOutlet weak var pieChartView: PieChartView!
    
    var selectedDate: String!
    let filterCat = ["Day", "Month", "Year"]
    var dates = [String]()
    var visitObjs = [VisitForGraph]()
    var filterTableViewIndexPath: IndexPath?
    var spinner: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        customizeFilterView()
        customizeFilterTableView()
        customizeCollectionView()
        
        pieChartView.backgroundColor = UIColor("#f3f5f7")
        pieChartView.legend.enabled = false
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.showSpinner(onView: self.view)
        
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
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        spinner = spinnerView
    }
    
    // clear spinner
    func removeSpinner() {
        DispatchQueue.main.async {
            self.spinner?.removeFromSuperview()
            self.spinner = nil
        }
    }
    
    // set collectionView data based on filters (day, month, or year)
    func loadDataBasedOnFilter() {
        if let indexPath = self.filterTableViewIndexPath {
            if indexPath.row == 0 {
                self.dates = ["2019-06-27", "2019-06-28", "2019-07-29", "2019-07-30", "2019-07-31"]
            } else if indexPath.row == 1 {
                self.dates = ["June", "July"]
                
            } else {
                self.dates = ["2019"]
            }
            self.collectionView.reloadData()
            
            DispatchQueue.main.async {
                let index = IndexPath(item: self.dates.count-1, section: 0)
                self.collectionView.selectItem(at: index, animated: false, scrollPosition: .right)
                self.collectionView.delegate?.collectionView!(self.collectionView, didSelectItemAt: index)
            }
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
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GraphCollectionViewCell", for: indexPath) as! GraphCollectionViewCell
        
        // cell stylings
        cell.backgroundColor = UIColor("#fff")
        cell.filterLabel.textColor = UIColor("#31c1ff")
        cell.layer.borderColor = UIColor("#31c1ff").cgColor
        cell.layer.borderWidth = 0.6
        cell.layer.cornerRadius = cell.frame.height/2
        cell.layer.masksToBounds = true
        
        if let index = self.filterTableViewIndexPath {
            if index.row == 0 {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let parsedDate = dateFormatter.date(from: date)
                let f = DateFormatter()
                let formattedMonth = f.monthSymbols[Calendar.current.component(.month, from: parsedDate!)-1].prefix(3)
                let day = String(date.split(separator: "-")[2])
                cell.filterLabel.text = "\(formattedMonth) \(day)"
            } else {
                cell.filterLabel.text = date
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)

        let cell = collectionView.cellForItem(at: indexPath) as! GraphCollectionViewCell
        cell.backgroundColor = UIColor("#31c1ff")
        cell.filterLabel.textColor = UIColor("#fff")
        
        // get the selected date
        self.selectedDate = dates[indexPath.item]
        if let index = self.filterTableViewIndexPath {
            if index.row == 0 {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let parsedDate = dateFormatter.date(from: self.selectedDate)
                
                // set the date string for the UIView at the top
                let f = DateFormatter()
                let month = f.monthSymbols[Calendar.current.component(.month, from: parsedDate!)-1].prefix(3)
                let day = String(self.selectedDate.split(separator: "-")[2])
                let year = String(self.selectedDate.split(separator: "-")[0])
                let weekday = f.weekdaySymbols[Calendar.current.component(.weekday, from: parsedDate!)-1]
                self.dateUILabel.text = "\(weekday), \(month) \(day), \(year)"
                
                self.visitObjs = [VisitForGraph(room: "exam1", timeElapsed: 1800),
                                  VisitForGraph(room: "CTRoom", timeElapsed: 1200)]
                self.removeSpinner()
                self.customizeCharts(dataObj: visitObjs)
                
            } else if index.row == 1 {
                self.dateUILabel.text = "2019"
            } else {
                self.dateUILabel.text = "Year"
            }
        }
    }
    
    func customizeCharts(dataObj: [VisitForGraph]) {
        self.pieChartView.animate(xAxisDuration: 1.4, easingOption: .easeOutBack)
        
        let entries = (0..<dataObj.count).map { (i) -> PieChartDataEntry in
            return PieChartDataEntry(value: Double(dataObj[i].timeElapsed)/60.0, label: self.prettifyRoom(room: dataObj[i].room))
        }
        
        let pieChartDataSet = PieChartDataSet(entries: entries, label: nil)
        pieChartDataSet.colors = colorsOfCharts(numberOfColor: dataObj.count)
        
        let pieChartData = PieChartData(dataSet: pieChartDataSet)
        let pFormatter = NumberFormatter()
        pFormatter.positiveSuffix = " min"
        pieChartData.setValueFormatter(DefaultValueFormatter(formatter: pFormatter))
        
        pieChartData.setValueFont(UIFont(name: "Poppins-Bold", size: 15)!)
        pieChartData.setValueTextColor(UIColor("#fcfcfc"))
        self.pieChartView.data = pieChartData

    }
    
    private func colorsOfCharts(numberOfColor: Int) -> [UIColor] {
        var colors: [UIColor] = []
        for _ in 0..<numberOfColor {
            let red = Double(arc4random_uniform(256))
            let green = Double(arc4random_uniform(256))
            let blue = Double(arc4random_uniform(256))
            let color = UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1)
            colors.append(color)
        }
        return colors
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! GraphCollectionViewCell
        cell.backgroundColor = UIColor("#fff")
        cell.filterLabel.textColor = UIColor("#31c1ff")
        cell.layer.borderColor = UIColor("#31c1ff").cgColor
        cell.layer.borderWidth = 0.6
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === filterTableView {
            let filter = self.filterCat[indexPath.row]
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "filterTableViewCell", for: indexPath) as! filterTableViewCell
            
            cell.filterLabel.text = filter
            
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
