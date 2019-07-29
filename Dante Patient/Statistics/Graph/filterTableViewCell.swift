//
//  filterTableViewCell.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 7/29/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit

class filterTableViewCell: UITableViewCell {

    @IBOutlet weak var filterLabel: UILabel!
    @IBOutlet weak var checkBtn: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
