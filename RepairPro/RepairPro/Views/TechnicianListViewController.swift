//
//  TechnicianListViewController.swift
//  RepairPro
//
//  Created by BP-36-201-02 on 14/12/2025.
//

import Foundation
import UIKit

class TechnicianListViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var sectionContainerView: UIView!
    @IBOutlet weak var searchContainerView: UIView!
    @IBOutlet weak var departmentDropdownView: UIView!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        styleScreenBackground()
        styleSectionContainer()
        styleSearchBar()
        styleDepartmentDropdown()
    }

    // MARK: - Styling Methods

    /// Light grey background for the whole screen (Figma canvas)
    private func styleScreenBackground() {
        view.backgroundColor = UIColor(
            red: 242/255,
            green: 242/255,
            blue: 247/255,
            alpha: 1
        )
    }

    /// Grey container that groups search + dropdown
    private func styleSectionContainer() {
        sectionContainerView.backgroundColor = UIColor(
            red: 242/255,
            green: 242/255,
            blue: 247/255,
            alpha: 1
        )

        sectionContainerView.layer.cornerRadius = 16
        sectionContainerView.layer.masksToBounds = true
    }

    /// White rounded search bar (NO border)
    private func styleSearchBar() {
        searchContainerView.backgroundColor = .white
        searchContainerView.layer.cornerRadius = 12
        searchContainerView.layer.masksToBounds = true
    }

    /// White rounded dropdown with subtle stroke
    private func styleDepartmentDropdown() {
        departmentDropdownView.backgroundColor = .white
        departmentDropdownView.layer.cornerRadius = 12

        departmentDropdownView.layer.borderWidth = 1
        departmentDropdownView.layer.borderColor = UIColor(
            red: 209/255,
            green: 209/255,
            blue: 214/255,
            alpha: 1
        ).cgColor

        departmentDropdownView.layer.masksToBounds = true
    }
}
