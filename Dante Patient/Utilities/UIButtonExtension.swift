//
//  UIButtonExtension.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/20/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import DeviceKit

class Button: UIButton {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.layer.masksToBounds = true
        self.contentHorizontalAlignment = .center
        self.contentVerticalAlignment = .center
        self.backgroundColor = UIColor("#31C1FF")
        self.setTitleColor(UIColor("#fff"), for: .normal)
        
        let device = Device.current
        let smallDevice: [Device] = [.iPhoneSE, .simulator(.iPhoneSE), .iPhone5s, .simulator(.iPhone5s)]
        if device.isOneOf(smallDevice) {
            self.layer.cornerRadius = 14
            self.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 16)
        } else {
            self.layer.cornerRadius = self.frame.height/3
            self.titleLabel?.font = UIFont(name: "Poppins-Bold", size: 19)
        }
        self.titleLabel?.minimumScaleFactor = 0.5
        self.titleLabel?.adjustsFontSizeToFitWidth = true

    }
}
