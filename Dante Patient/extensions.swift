//
//  extensions.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/2/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

extension UIViewController {
    func hp(percent: Float) -> Int {
        return Int(Float(UIScreen.main.bounds.size.height) * (percent / 100));
    }
    
    func wp(percent: Float) -> Int {
        return Int(Float(UIScreen.main.bounds.size.width) * (percent / 100));
    }
}
