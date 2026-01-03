//
//  EditTechnicianViewController.swift
//  RepairPro
//

import UIKit

final class EditTechnicianViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Outlets
    @IBOutlet weak var formCardView: UIView!

    
    @IBOutlet weak var fullNameContainerView: UIView!
    @IBOutlet weak var fullNameTextField: UITextField!
    
    
    @IBOutlet weak var contactContainerView: UIView!
    @IBOutlet weak var contactTextField: UITextField!
    
    @IBOutlet weak var usernameContainerView: UIView!
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var passwordContainerView: UIView!
    
    @IBOutlet weak var departmentDropdownView: UIView!
    @IBOutlet weak var departmentValueLabel: UILabel!
    @IBOutlet weak var departmentArrowImageView: UIImageView!

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!


        // MARK: - Data
        var technician: TechnicianListViewController.Technician!
        var availableDepartments: [String] = []

        private var selectedDepartment: String?
        private var isDepartmentSheetOpen = false

        // MARK: - Lifecycle
        override func viewDidLoad() {
            super.viewDidLoad()

            setupTextFields()
            setupDropdownTap()
            setupButtons()
            styleCardAndRows()
            styleDepartmentDropdown()
            prefillData()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            formCardView.layer.shadowPath = UIBezierPath(
                roundedRect: formCardView.bounds,
                cornerRadius: 16
            ).cgPath
        }

        // MARK: - Setup
        private func setupTextFields() {
            fullNameTextField.delegate = self
            contactTextField.delegate = self

            // Username → READ ONLY
            usernameTextField.isEnabled = false
            usernameTextField.alpha = 0.6

            fullNameTextField.returnKeyType = .next
            contactTextField.returnKeyType = .done
        }

        private func setupDropdownTap() {
            let tap = UITapGestureRecognizer(
                target: self,
                action: #selector(departmentDropdownTapped)
            )
            departmentDropdownView.addGestureRecognizer(tap)
            departmentDropdownView.isUserInteractionEnabled = true
        }
    private func styleDepartmentDropdown() {
        departmentDropdownView.backgroundColor = UIColor(white: 0.97, alpha: 1)
        departmentDropdownView.layer.cornerRadius = 12
        departmentDropdownView.layer.borderWidth = 1
        departmentDropdownView.layer.borderColor = UIColor.systemGray4.cgColor
        departmentDropdownView.layer.masksToBounds = true
    }

        private func setupButtons() {
            let brandBlue = UIColor(hex: "00466F")
            let brandOrange = UIColor(hex: "FFA214")

            var cancelConfig = UIButton.Configuration.filled()
            cancelConfig.title = "Cancel"
            cancelConfig.baseBackgroundColor = brandOrange
            cancelConfig.baseForegroundColor = .black
            cancelConfig.cornerStyle = .fixed
            cancelButton.layer.cornerRadius = 12
            cancelButton.layer.masksToBounds = true
            cancelButton.configuration = cancelConfig

            var saveConfig = UIButton.Configuration.filled()
            saveConfig.title = "Save"
            saveConfig.baseBackgroundColor = brandBlue
            saveConfig.baseForegroundColor = .white
            saveConfig.cornerStyle = .fixed
            saveButton.layer.cornerRadius = 12
            saveButton.layer.masksToBounds = true
            saveButton.configuration = saveConfig

            cancelButton.addPressAnimation()
            saveButton.addPressAnimation()

            cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
            saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        }

    private func styleCardAndRows() {
        // Card
        formCardView.backgroundColor = UIColor(white: 0.97, alpha: 1)
        formCardView.layer.cornerRadius = 16
        formCardView.layer.shadowColor = UIColor.black.cgColor
        formCardView.layer.shadowOpacity = 0.14
        formCardView.layer.shadowRadius = 4
        formCardView.layer.shadowOffset = CGSize(width: 0, height: 3)

        // Row containers (MATCH ADD SCREEN)
        [
            fullNameContainerView,
            contactContainerView,
            usernameContainerView,
            passwordContainerView
        ].forEach {
            $0?.backgroundColor = UIColor(white: 0.92, alpha: 1)
            $0?.layer.cornerRadius = 12
            $0?.layer.masksToBounds = true
        }

        // Username locked styling
        usernameContainerView.alpha = 0.6
    }

        // MARK: - Prefill
        private func prefillData() {
            fullNameTextField.text = technician.name
            contactTextField.text = technician.phone

            usernameTextField.text = technician.username
            usernameTextField.isEnabled = false

            selectedDepartment = technician.department
            departmentValueLabel.text = technician.department
        }

        // MARK: - Actions
        @objc private func cancelTapped() {
            cancelButton.animateAndThen {
                self.navigationController?.popViewController(animated: true)
            }
        }

        @objc private func saveTapped() {
            saveButton.animateAndThen {

                let name = self.fullNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let phone = self.contactTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let dept = self.selectedDepartment ?? ""

                guard !name.isEmpty, !dept.isEmpty else {
                    self.showErrorAlert()
                    return
                }

                self.technician.name = name
                self.technician.department = dept
                self.technician.phone = phone

                NotificationCenter.default.post(
                    name: .technicianUpdated,
                    object: self.technician
                )

                self.navigationController?.popViewController(animated: true)
            }
        }

        private func showErrorAlert() {
            let alert = UIAlertController(
                title: "Missing Information",
                message: "Please fill in Full Name and Department.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }

        // MARK: - Department Dropdown
        @objc private func departmentDropdownTapped() {
            guard !isDepartmentSheetOpen else { return }
            isDepartmentSheetOpen = true

            UIView.animate(withDuration: 0.15) {
                self.departmentArrowImageView.transform = CGAffineTransform(rotationAngle: .pi)
            }

            let sheet = UIAlertController(title: "Department", message: nil, preferredStyle: .actionSheet)

            func closeUI() {
                self.departmentArrowImageView.transform = .identity
                self.isDepartmentSheetOpen = false
            }

            for dept in availableDepartments.sorted() {
                sheet.addAction(UIAlertAction(title: dept, style: .default) { _ in
                    self.selectedDepartment = dept
                    self.departmentValueLabel.text = dept
                    closeUI()
                })
            }

            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                closeUI()
            })

            present(sheet, animated: true)
        }
    
    }
