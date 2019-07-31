//
//  StatsMasterViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/25/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

class StatsMasterViewController: UIViewController {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    private lazy var visitsHistoryViewController: VisitsHistoryViewController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "VisitsHistoryViewController") as! VisitsHistoryViewController
        
        // Add View Controller as Child View Controller
        self.add(asChildViewController: viewController)
        
        return viewController
    }()
    
    private lazy var visitsHistoryGraphViewController: VisitsHistoryGraphViewController = {
        
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "VisitsHistoryGraphViewController") as! VisitsHistoryGraphViewController
        
        // Add View Controller as Child View Controller
        self.add(asChildViewController: viewController)
        
        return viewController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        updateView()
        
        // Do any additional setup after loading the view.
    }
    
    private func setupView() {
        setupSegmentedControl()
    }
    
    private func setupSegmentedControl() {
        // Configure Segmented Control
        segmentedControl.removeAllSegments()
        segmentedControl.insertSegment(withTitle: "Table", at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "Graph", at: 1, animated: false)
        segmentedControl.addTarget(self, action: #selector(selectionDidChange(_:)), for: .valueChanged)
        
        // Select First Segment
        segmentedControl.selectedSegmentIndex = 0
        
    }
    
    @objc func selectionDidChange(_ sender: UISegmentedControl) {
        updateView()
    }
    
    private func updateView() {
        if segmentedControl.selectedSegmentIndex == 0 {
            remove(asChildViewController: visitsHistoryGraphViewController)
            add(asChildViewController: visitsHistoryViewController)
            self.navigationItem.rightBarButtonItem = nil
        } else {
            remove(asChildViewController: visitsHistoryViewController)
            add(asChildViewController: visitsHistoryGraphViewController)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(toggleFilter))
        }
    }
    
    @objc func toggleFilter(sender: UIButton) {
        let view = visitsHistoryGraphViewController.filterView!
        if view.alpha == 0.0 {
            view.fadeIn()
        } else {
            view.fadeOut()
        }
    }
    
    
    private func add(asChildViewController viewController: UIViewController) {
        // Add Child View Controller
        addChild(viewController)
        
        // Add Child View as Subview
        view.addSubview(viewController.view)
        
        // Configure Child View
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Notify Child View Controller
        viewController.didMove(toParent: self)
    }
    
    private func remove(asChildViewController viewController: UIViewController) {
        // Notify Child View Controller
        viewController.willMove(toParent: nil)
        
        // Remove Child View From Superview
        viewController.view.removeFromSuperview()
        
        // Notify Child View Controller
        viewController.removeFromParent()
    }
}
