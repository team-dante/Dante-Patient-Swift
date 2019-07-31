//
//  VisitHistoryGraphViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/25/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

class VisitsHistoryGraphViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var filterView: UIView!
    @IBOutlet weak var filterTableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var dateUILabel: UILabel!
    
    var selectedDate: String!
    let filterCat = ["Day", "Month", "Year"]
    var dates = [String]()
    var filterTableViewIndexPath: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        filterView.alpha = 0.0
        filterView.layer.cornerRadius = 20.0
        filterView.addShadow()
        
        filterTableView.delegate = self
        filterTableView.dataSource = self
        filterTableView.estimatedRowHeight = 44.0
        filterTableView.isScrollEnabled = false
        filterTableView.allowsMultipleSelection = false
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.layer.borderColor = UIColor("#adadad").cgColor
        collectionView.layer.borderWidth = 0.4
        collectionView.showsHorizontalScrollIndicator = false

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let alert = UIAlertController(title: nil, message: "Loading Graph...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let indexPath = self.filterTableViewIndexPath {
                self.filterTableView.delegate?.tableView!(self.filterTableView, didSelectRowAt: indexPath)
            } else {
                self.filterTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
                self.filterTableView.delegate?.tableView!(self.filterTableView, didSelectRowAt: IndexPath(row: 0, section: 0))
            }
            DispatchQueue.main.async {
                self.loadDataBasedOnFilter()
                self.dismissAlert()
            }
        }
    }
    
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
    
    internal func dismissAlert() {
        if let vc = self.presentedViewController, vc is UIAlertController { dismiss(animated: false, completion: nil)
        }
    }
    
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
        print(cell.filterLabel.text!)
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
            } else if index.row == 1 {
                self.dateUILabel.text = "2019"
            } else {
                self.dateUILabel.text = "Year"
            }
        }
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
