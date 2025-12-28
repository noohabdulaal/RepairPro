import UIKit
import FirebaseFirestore
import Cloudinary

// MARK: - Technician model
struct Technician: Codable {
    let name: String
    let department: String
    let phone: String
    let profileImage: String? // Optional Cloudinary public ID or URL
}

class TechnitionsViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!

    var technicians: [Technician] = []

    let db = Firestore.firestore()
    let cloudinary = CLDCloudinary(configuration: CLDConfiguration(cloudName: "dtthzideh"))

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

    // MARK: - Fetch technicians from Firestore
    func fetchTechnicians() {
        db.collection("Technicians").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                self.showErrorAlert(message: "Failed to load technicians: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                self.showErrorAlert(message: "No technicians found.")
                return
            }

            var fetchedTechnicians: [Technician] = []

            for doc in documents {
                do {
                    let data = try JSONSerialization.data(withJSONObject: doc.data())
                    let technician = try JSONDecoder().decode(Technician.self, from: data)
                    fetchedTechnicians.append(technician)
                } catch {
                    print("Error decoding technician:", error)
                }
            }

            self.technicians = fetchedTechnicians
            DispatchQueue.main.async {
                self.displayTechnicians()
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
            containerView.heightAnchor.constraint(equalToConstant: 120).isActive = true

            // Technician Image
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 30
            imageView.backgroundColor = .systemGray4
            imageView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(imageView)

            loadImageFromCloudinary(publicIDOrURL: technician.profileImage, into: imageView)

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
                imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
                imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 60),
                imageView.heightAnchor.constraint(equalToConstant: 60),

                nameLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
                nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),

                departmentLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
                departmentLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),

                phoneLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
                phoneLabel.topAnchor.constraint(equalTo: departmentLabel.bottomAnchor, constant: 4)
            ])

            stackView.addArrangedSubview(containerView)
        }
    }

    // MARK: - Cloudinary Image Loader
    func loadImageFromCloudinary(publicIDOrURL: String?, into imageView: UIImageView) {
        let defaultImageURL = "https://res.cloudinary.com/dtthzideh/image/upload/v1766927687/Copilot_20251225_112235_zuxqkf.png"
        guard let path = publicIDOrURL, !path.isEmpty else {
            loadRemoteImage(from: defaultImageURL, into: imageView)
            return
        }

        if path.starts(with: "http") {
            loadRemoteImage(from: path, into: imageView)
        } else {
            if let url = cloudinary.createUrl().generate(path) {
                loadRemoteImage(from: url, into: imageView)
            }
        }
    }

    func loadRemoteImage(from urlString: String, into imageView: UIImageView) {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                imageView.image = image
            }
        }.resume()
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

