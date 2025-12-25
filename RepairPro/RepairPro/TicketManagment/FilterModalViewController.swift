import UIKit

class FilterModalViewController: UIViewController {

    // MARK: - Callbacks
    var applyFilters: ((_ status: String?, _ priority: String?, _ deadline: String?) -> Void)?

    // MARK: - UI Elements
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Filtered by Status:"
        label.font = .boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statusSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Complete", "In Progress", "Assigned"])
        sc.selectedSegmentIndex = UISegmentedControl.noSegment
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    private let priorityLabel: UILabel = {
        let label = UILabel()
        label.text = "Filtered by Priority:"
        label.font = .boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let prioritySegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["High", "Medium", "Low"])
        sc.selectedSegmentIndex = UISegmentedControl.noSegment
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    private let deadlineLabel: UILabel = {
        let label = UILabel()
        label.text = "Filtered by Deadline:"
        label.font = .boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let deadlineSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Nearest", "Furthest"])
        sc.selectedSegmentIndex = UISegmentedControl.noSegment
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Apply Filters", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        setupUI()
        saveButton.addTarget(self, action: #selector(applyButtonTapped), for: .touchUpInside)
    }

    private func setupUI() {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        container.addSubview(statusLabel)
        container.addSubview(statusSegment)
        container.addSubview(priorityLabel)
        container.addSubview(prioritySegment)
        container.addSubview(deadlineLabel)
        container.addSubview(deadlineSegment)
        container.addSubview(saveButton)

        NSLayoutConstraint.activate([
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),

            statusLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),

            statusSegment.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            statusSegment.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            statusSegment.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            priorityLabel.topAnchor.constraint(equalTo: statusSegment.bottomAnchor, constant: 20),
            priorityLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),

            prioritySegment.topAnchor.constraint(equalTo: priorityLabel.bottomAnchor, constant: 8),
            prioritySegment.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            prioritySegment.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            deadlineLabel.topAnchor.constraint(equalTo: prioritySegment.bottomAnchor, constant: 20),
            deadlineLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),

            deadlineSegment.topAnchor.constraint(equalTo: deadlineLabel.bottomAnchor, constant: 8),
            deadlineSegment.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            deadlineSegment.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            saveButton.topAnchor.constraint(equalTo: deadlineSegment.bottomAnchor, constant: 20),
            saveButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            saveButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func applyButtonTapped() {
        // Status mapping
        var statusValue: String? = nil
        switch statusSegment.selectedSegmentIndex {
        case 0: statusValue = "complete"
        case 1: statusValue = "in progress"
        case 2: statusValue = "assigned"
        default: statusValue = nil
        }

        // Priority mapping
        var priorityValue: String? = nil
        switch prioritySegment.selectedSegmentIndex {
        case 0: priorityValue = "in progress"   // High → In Progress
        case 1: priorityValue = "assigned"      // Medium → Assigned
        case 2: priorityValue = "complete"       // Low → Complete
        default: priorityValue = nil
        }

        // Deadline
        var deadlineValue: String? = nil
        switch deadlineSegment.selectedSegmentIndex {
        case 0: deadlineValue = "nearest"
        case 1: deadlineValue = "furthest"
        default: deadlineValue = nil
        }

        dismiss(animated: true) {
            self.applyFilters?(statusValue, priorityValue, deadlineValue)
        }
    }
}

