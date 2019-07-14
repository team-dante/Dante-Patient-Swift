//
//  extensions.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/2/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

class Banner: UIView {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        self.layer.shadowOpacity = 0.4
        self.layer.shadowRadius = 5
        self.layer.cornerRadius = 5
    }
}

class CardComponent: UIView {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.layer.cornerRadius = 20
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.3
        self.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        self.layer.shadowRadius = 8
    }
}

class Inputs: UITextField {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.layer.cornerRadius = 20
        self.backgroundColor = UIColor("#f3f5f7")
        self.textColor = UIColor("#46586a")
        self.layer.borderColor = UIColor("#ededed").cgColor
        self.layer.borderWidth = 1.5
        let leftView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 7.0, height: 45.0))
        self.leftView = leftView
        self.leftViewMode = .always
        self.layer.masksToBounds = true
    }
}

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

extension UIView {
    
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        if #available(iOS 11.0, *) {
            layer.cornerRadius = radius
            layer.maskedCorners = CACornerMask(rawValue: corners.rawValue)
        } else {
            let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            layer.mask = mask
        }
    }
    
    func addShadow() {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.1
        self.layer.shadowOffset = CGSize(width: 0, height: 0.2)
        self.layer.shadowRadius = 5
    }
}
