//
//  ViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/1/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController, UIScrollViewDelegate {

    var ref: DatabaseReference!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mapUIView: UIView!
    @IBOutlet weak var mapImageView: UIImageView!
    
    // import images
    let img1 = UIImageView(image: UIImage(named: "greenPin"))
    let img2 = UIImageView(image: UIImage(named: "purplePin"))

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // connecting to Firebase initially
        ref = Database.database().reference()
        
        // zoom in
        self.scrollView.delegate = self
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 4.0
        
        // set scrollView height
        self.scrollView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height * 0.7).isActive = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let docDict: [String: UIImageView] = [
            "111": img1,
            "222": img2
        ]
        
        var mapDict = [
            "femaleWaitingRoom": [(wp(percent: 41), hp(percent: 20)),(wp(percent: 44), hp(percent: 22))],
            "CTRoom": [(wp(percent: 3), hp(percent: 41)),(wp(percent: 12), hp(percent: 40))],
            "exam1": [(wp(percent: 59), hp(percent: 33)),(wp(percent: 61), hp(percent: 33))]
        ]
        // call observe to always listen for event changes
        ref.child("DoctorLocation").observe(.value, with: {(snapshot) in
            if let doctors = snapshot.value as? [String: Any] {
                for doctor in doctors {
                    let key = doctor.key
                    // get doctor's value e.g. {"room": "CTRoom"}
                    if let doc = doctor.value as? [String: String] {
                        let room = doc["room"]! // e.g. "CTRoom"
                        
                        // add the assigned doctor pin onto the image; re-render when event changes
                        self.updateDocLoc(doctor: docDict[key]!, x: mapDict[room]![0].0, y: mapDict[room]![0].1)
                        
                        let firstElement = mapDict[room]!.remove(at: 0)
                        mapDict[room]!.append(firstElement)
                    }
                }
            }
        })
    }
    // delegate method to help zooming
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.mapUIView
    }
    // utilize offsets; add doc pin(UIImage) to UIView
    func updateDocLoc(doctor: UIImageView, x: Int, y: Int) {
        doctor.frame = CGRect(x: x, y: y, width: 15, height: 30)
        self.mapUIView.addSubview(doctor)
    }
}
