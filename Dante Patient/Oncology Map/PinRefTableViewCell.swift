//
//  PinRefTableViewCell.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/12/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

class PinRefTableViewCell: UITableViewCell {
    
    // three objects for each table cell: image, doctor's name, and room name

    @IBOutlet weak var docLabel: UILabel!
    @IBOutlet weak var roomLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
