//
//  RoomDetailsViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 9/15/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

class RoomDetailsViewController: UIViewController {

    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var navigationVIew: UIView!
    @IBOutlet weak var navHeight: NSLayoutConstraint!
    @IBOutlet weak var roomImageView: UIImageView!
    @IBOutlet weak var roomDespLabel: UILabel!
    
    var roomStr: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let height = UIScreen.main.bounds.height
        if height >= 812 {
            self.navHeight.constant = 88
        } else {
            self.navHeight.constant = 64
        }
        
        self.roomLabel.text = self.prettifyRoom(room: roomStr, fullName: true)
        self.roomImageView.image = UIImage(named: roomStr)
        self.roomDespLabel.text = "\(roomLabel.text!) is Lorem ipsum dolor sit amet, in purto appetere delicata quo, erant molestie voluptatibus duo ei, mazim utamur lucilius vim te. Exerci dicunt legendos ut has, noster maluisset mea ad, ei equidem accumsan antiopam eam. Erroribus definiebas vis ea. Scribentur reformidans no cum. Ex usu inermis volumus alienum. Pro ea abhorreant interesset theophrastus."
    }

    @IBAction func onCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
