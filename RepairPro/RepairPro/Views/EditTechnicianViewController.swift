//
//  EditTechnicianViewController.swift
//  RepairPro
//
//  Created by ec2-user on 26/12/2025.
//

import Foundation
import UIKit

final class EditTechnicianViewController: UIViewController {

    // Just to prove data is passing (optional)
    var technicianName: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
        // Later you’ll populate fields using technicianName / full technician object
    }

    @IBAction func returnTapped(_ sender: UIButton) {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
