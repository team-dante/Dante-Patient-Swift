//
//  UIButtonExtension.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/20/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

class Button: UIButton {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.layer.cornerRadius = 20
        self.layer.masksToBounds = true
        self.contentHorizontalAlignment = .center
        self.contentVerticalAlignment = .center
        self.backgroundColor = UIColor("#31C1FF")
        self.setTitleColor(UIColor("#fff"), for: .normal)
        self.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 20)
    }
}
