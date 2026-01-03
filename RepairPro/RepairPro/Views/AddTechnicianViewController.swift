//
//  AddTechnicianViewController.swift
//  RepairPro
//

import UIKit

final class AddTechnicianViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Outlets
    @IBOutlet weak var formCardView: UIView!

    @IBOutlet weak var fullNameContainerView: UIView!
    @IBOutlet weak var fullNameTextField: UITextField!

    @IBOutlet weak var departmentDropdownView: UIView!
    @IBOutlet weak var departmentValueLabel: UILabel!
    @IBOutlet weak var departmentArrowImageView: UIImageView!

    @IBOutlet weak var contactContainerView: UIView!
    @IBOutlet weak var contactTextField: UITextField!

    @IBOutlet weak var usernameContainerView: UIView!
    @IBOutlet weak var usernameTextField: UITextField!

    @IBOutlet weak var passwordContainerView: UIView!
    @IBOutlet weak var passwordTextField: UITextField!

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!


        // MARK: - Data
        var availableDepartments: [String] = []
        var onSave: ((_ name: String, _ department: String, _ phone: String, _ username: String) -> Void)?

        private var selectedDepartment: String?
        private var isDepartmentSheetOpen = false

        // MARK: - Lifecycle
        override func viewDidLoad() {
            super.viewDidLoad()

            setupTextFields()
            setupDropdownTap()
            setupButtons()
            styleCardAndRows()
            setInitialDepartmentUI()
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
            usernameTextField.delegate = self
            passwordTextField.delegate = self

            passwordTextField.isSecureTextEntry = true

            fullNameTextField.returnKeyType = .next
            contactTextField.returnKeyType = .next
            usernameTextField.returnKeyType = .next
            passwordTextField.returnKeyType = .done
        }

        private func setupDropdownTap() {
            let tap = UITapGestureRecognizer(
                target: self,
                action: #selector(departmentDropdownTapped)
            )
            departmentDropdownView.addGestureRecognizer(tap)
            departmentDropdownView.isUserInteractionEnabled = true
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

        private func setInitialDepartmentUI() {
            departmentValueLabel.text = "Select Department"
            departmentArrowImageView.transform = .identity
        }

        // MARK: - Styling
        private func styleCardAndRows() {
            formCardView.backgroundColor = UIColor(white: 0.97, alpha: 1)
            formCardView.layer.cornerRadius = 16
            formCardView.layer.shadowColor = UIColor.black.cgColor
            formCardView.layer.shadowOpacity = 0.14
            formCardView.layer.shadowRadius = 4
            formCardView.layer.shadowOffset = CGSize(width: 0, height: 3)

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

            departmentDropdownView.backgroundColor = UIColor(white: 0.97, alpha: 1)
            departmentDropdownView.layer.cornerRadius = 12
            departmentDropdownView.layer.borderWidth = 1
            departmentDropdownView.layer.borderColor = UIColor.systemGray4.cgColor
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
                let username = self.usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let password = self.passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let phone = self.contactTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                var missing: [String] = []
                if name.isEmpty { missing.append("Full Name") }
                if self.selectedDepartment == nil { missing.append("Department") }
                if username.isEmpty { missing.append("Username") }
                if password.isEmpty { missing.append("Password") }

                guard missing.isEmpty else {
                    self.showErrorAlert(missing: missing)
                    return
                }

                // ✅ FIXED LINE
                self.onSave?(name, self.selectedDepartment!, phone, username)
                self.navigationController?.popViewController(animated: true)
            }
        }

        private func showErrorAlert(missing: [String]) {
            let message = "Please fill in:\n• " + missing.joined(separator: "\n• ")
            let alert = UIAlertController(title: "Missing Information", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }

        // MARK: - Department Dropdown
        @objc private func departmentDropdownTapped() {
            view.endEditing(true)
            guard !isDepartmentSheetOpen else { return }
            isDepartmentSheetOpen = true

            UIView.animate(withDuration: 0.15) {
                self.departmentArrowImageView.transform = CGAffineTransform(rotationAngle: .pi)
            }

            let sheet = UIAlertController(title: "Department", message: nil, preferredStyle: .actionSheet)

            func closeUI() {
                UIView.animate(withDuration: 0.15) {
                    self.departmentArrowImageView.transform = .identity
                }
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

            if let pop = sheet.popoverPresentationController {
                pop.sourceView = departmentDropdownView
                pop.sourceRect = departmentDropdownView.bounds
            }

            present(sheet, animated: true)
        }

        // MARK: - UITextFieldDelegate
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            switch textField {
            case fullNameTextField: contactTextField.becomeFirstResponder()
            case contactTextField: usernameTextField.becomeFirstResponder()
            case usernameTextField: passwordTextField.becomeFirstResponder()
            default: textField.resignFirstResponder()
            }
            return true
        }
    }

    // MARK: - UIColor Hex Helper
    extension UIColor {
        convenience init(hex: String) {
            let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            var int: UInt64 = 0
            Scanner(string: hex).scanHexInt64(&int)
            self.init(
                red: CGFloat((int >> 16) & 0xFF) / 255,
                green: CGFloat((int >> 8) & 0xFF) / 255,
                blue: CGFloat(int & 0xFF) / 255,
                alpha: 1
            )
        }
    }
