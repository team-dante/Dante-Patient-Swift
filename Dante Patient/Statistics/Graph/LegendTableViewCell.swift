//
//  LegendTableViewCell.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/31/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

class LegendTableViewCell: UITableViewCell {

    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
