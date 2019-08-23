//
//  UITextFieldExtension.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/20/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

class Inputs: UITextField {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.layer.cornerRadius = self.frame.height/3
        self.backgroundColor = UIColor("#f3f5f7")
        self.textColor = UIColor("#46586a")
        self.layer.borderColor = UIColor("#ededed").cgColor
        self.layer.borderWidth = 1.5
        let leftView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 7.0, height: self.frame.height))
        self.leftView = leftView
        self.leftViewMode = .always
        self.layer.masksToBounds = true
    }
}
