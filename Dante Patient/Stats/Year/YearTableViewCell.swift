//
//  YearTableViewCell.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 8/20/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

class YearTableViewCell: UITableViewCell {

    @IBOutlet weak var yearLabel: UILabel!
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
