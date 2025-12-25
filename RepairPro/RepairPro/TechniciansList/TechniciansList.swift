//
//  TechnitionsViewController.swift
//  RepairPro
//

import UIKit

// MARK: - Technician model
struct Technician: Codable {
    let name: String
    let department: String
    let phone: String
}

class TechnitionsViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!

    var technicians: [Technician] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Technicians"
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        setupScrollViewAndStackView()
        fetchTechnicians()
    }

    // MARK: - Setup scrollView & stackView constraints
    func setupScrollViewAndStackView() {
        scrollView.constraints.forEach { scrollView.removeConstraint($0) }
        stackView.constraints.forEach { stackView.removeConstraint($0) }

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fill

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }

    // MARK: - Fetch technicians from Supabase
    func fetchTechnicians() {
        Task {
            do {
                // Adjust schema.table here to your setup: public.catch.technitions
                let fetchedTechnicians: [Technician] = try await SupabaseClientManager.shared.client
                    .from("catch.technitions") // schema "catch" + table "technitions"
                    .select()
                    .execute()
                    .value

                print("Fetched technicians:", fetchedTechnicians) // Debug print

                self.technicians = fetchedTechnicians

                await MainActor.run {
                    displayTechnicians()
                }
            } catch {
                await MainActor.run {
                    showErrorAlert(message: "Failed to load technicians: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Display technicians in stack view
    func displayTechnicians() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for technician in technicians {
            let containerView = UIView()
            containerView.backgroundColor = UIColor.systemGray6
            containerView.layer.cornerRadius = 12
            containerView.clipsToBounds = true
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.heightAnchor.constraint(equalToConstant: 100).isActive = true

            // Technician info
            let nameLabel = UILabel()
            nameLabel.text = "Name: \(technician.name)"
            nameLabel.font = .systemFont(ofSize: 16, weight: .bold)
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(nameLabel)

            let departmentLabel = UILabel()
            departmentLabel.text = "Department: \(technician.department)"
            departmentLabel.font = .systemFont(ofSize: 14)
            departmentLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(departmentLabel)

            let phoneLabel = UILabel()
            phoneLabel.text = "Phone: \(technician.phone)"
            phoneLabel.font = .systemFont(ofSize: 14)
            phoneLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(phoneLabel)

            NSLayoutConstraint.activate([
                nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),

                departmentLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                departmentLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),

                phoneLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                phoneLabel.topAnchor.constraint(equalTo: departmentLabel.bottomAnchor, constant: 4)
            ])

            stackView.addArrangedSubview(containerView)
        }
    }

    // MARK: - Error alert
    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

