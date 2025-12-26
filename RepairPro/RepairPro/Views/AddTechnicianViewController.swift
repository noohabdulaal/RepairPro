//
//  AddTechnicianViewController.swift
//  RepairPro
//
//  Created by ec2-user on 26/12/2025.
//

import Foundation
import UIKit

final class AddTechnicianViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
    }

    // Connect your "Return" button to this (or use a back button if pushed)
    @IBAction func returnTapped(_ sender: UIButton) {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
