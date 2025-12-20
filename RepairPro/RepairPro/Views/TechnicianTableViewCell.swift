//
//  TechnicianTableViewCell.swift
//  RepairPro
//
//  Created by BP-36-201-18 on 20/12/2025.
//

import UIKit

class TechnicianTableViewCell: UITableViewCell {


    @IBOutlet weak var cardContainerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCardStyle()
    }

    private func setupCardStyle() {
        // Card appearance
        cardContainerView.backgroundColor = .white
        cardContainerView.layer.cornerRadius = 16
        cardContainerView.layer.masksToBounds = false

        // Bottom-heavy shadow (Figma style)
        cardContainerView.layer.shadowColor = UIColor.black.cgColor
        cardContainerView.layer.shadowOpacity = 0.18
        cardContainerView.layer.shadowRadius = 12
        cardContainerView.layer.shadowOffset = CGSize(width: 0, height: 8)

        // Performance + clean shadow edges
        cardContainerView.layer.shadowPath = UIBezierPath(
            roundedRect: cardContainerView.bounds,
            cornerRadius: 16
        ).cgPath
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Keep shadow correct when cell resizes
        cardContainerView.layer.shadowPath = UIBezierPath(
            roundedRect: cardContainerView.bounds,
            cornerRadius: 16
        ).cgPath
    }
}
