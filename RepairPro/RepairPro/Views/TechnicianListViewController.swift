//
//  TechnicianListViewController.swift
//  RepairPro
//
//  Created by BP-36-201-02 on 14/12/2025.
//

import UIKit

class TechnicianListViewController: UIViewController,
                                   UITableViewDataSource,
                                   UITableViewDelegate {

    // MARK: - Outlets
    @IBOutlet weak var sectionContainerView: UIView!
    @IBOutlet weak var searchContainerView: UIView!
    @IBOutlet weak var departmentDropdownView: UIView!
    @IBOutlet weak var addTechnicianButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
        tableView.separatorStyle = .none

        styleScreenBackground()
        styleSectionContainer()
        styleSearchBar()
        styleDepartmentDropdown()
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Important: shadowPath must be updated AFTER layout so it matches the real size
        sectionContainerView.layer.shadowPath = UIBezierPath(
            roundedRect: sectionContainerView.bounds,
            cornerRadius: sectionContainerView.layer.cornerRadius
        ).cgPath
    }

    // MARK: - Styling

    /// Screen background (Figma canvas)
    private func styleScreenBackground() {
        view.backgroundColor = UIColor(
            red: 242/255,
            green: 242/255,
            blue: 247/255,
            alpha: 1
        )
    }

    /// Card container (search + dropdown)
    private func styleSectionContainer() {
        // Slightly darker than screen bg (so it’s visible)
        sectionContainerView.backgroundColor = UIColor(
            red: 232/255,
            green: 232/255,
            blue: 238/255,
            alpha: 1
        )

        sectionContainerView.layer.cornerRadius = 16
        sectionContainerView.layer.masksToBounds = false

        // Bottom-heavy, tighter (less spread)
        sectionContainerView.layer.shadowColor = UIColor.black.cgColor
        sectionContainerView.layer.shadowOpacity = 0.22
        sectionContainerView.layer.shadowRadius = 6
        sectionContainerView.layer.shadowOffset = CGSize(width: 0, height: 3)
    }

    /// Search bar container (should look like a filled search field)
    private func styleSearchBar() {
        // Proper "search gray" (darker than the card)
        searchContainerView.backgroundColor = UIColor(
            red: 220/255,
            green: 220/255,
            blue: 225/255,
            alpha: 1
        )

        searchContainerView.layer.cornerRadius = 12
        searchContainerView.layer.masksToBounds = true
    }

    /// Dropdown container
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
    private func styleAddTechnicianButton() {
        addTechnicianButton.layer.cornerRadius = 12
        addTechnicianButton.layer.masksToBounds = true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return 20   // Test scrolling & reuse
        }

        func tableView(
            _ tableView: UITableView,
            cellForRowAt indexPath: IndexPath
        ) -> UITableViewCell {

            let cell = tableView.dequeueReusableCell(
                withIdentifier: "TechnicianCell",
                for: indexPath
            ) as! TechnicianTableViewCell

            // 🔹 TEST DATA (intentionally varied)
            let names = [
                "Ahmed Darwish",
                "Sara Mansoor",
                "Khalid Haddad",
                "Ahmed Darwish Senior IT Infrastructure & Systems Administrator"
            ]

            let departments = [
                "IT Support",
                "Maintenance",
                "Facilities",
                "Network & Systems Operations Department"
            ]

            let phones = [
                "+973 3321 8745",
                "+973 3952 1067",
                "+973 3664 9821",
                "+973 3333 3333"
            ]

            let index = indexPath.row % names.count

            cell.configure(
                name: names[index],
                department: departments[index],
                phone: phones[index]
            )

            return cell
        }
    }
