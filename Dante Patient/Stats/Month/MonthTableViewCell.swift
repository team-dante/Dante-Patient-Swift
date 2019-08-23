//
//  MonthTableViewCell.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 8/19/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

class MonthTableViewCell: UITableViewCell {

    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var avgTimeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
