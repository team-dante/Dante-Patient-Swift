//
//  VisitHistoryGraphViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/25/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

class VisitsHistoryGraphViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var filterView: UIView!
    @IBOutlet weak var filterTableView: UITableView!
    let filterCat = ["Day", "Month", "Year"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filterView.alpha = 0.0
        filterView.layer.cornerRadius = 20.0
        filterView.addShadow()
        
        filterTableView.delegate = self
        filterTableView.dataSource = self
        filterTableView.estimatedRowHeight = 44.0
        filterTableView.isScrollEnabled = false

        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let filter = self.filterCat[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "filterTableViewCell", for: indexPath) as! filterTableViewCell
        
        cell.filterLabel.text = filter
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! filterTableViewCell
        cell.checkBtn.image = UIImage(named: "checkBtn")
        
        filterView.fadeOut()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! filterTableViewCell
        cell.checkBtn.image = UIImage(named: "uncheckBtn")
    }


    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        if touch?.view != filterView {
            filterView.fadeOut()
        }
    }
}
