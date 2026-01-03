import UIKit

// MARK: - Filter Modal View Controller
// Popup modal that allows filtering tickets by Status, Priority, and Deadline
class FilterModalViewController: UIViewController {

    // MARK: - Callback Closure
    // This closure gets called when user applies filters
    // It passes back the selected filter values to the calling view controller
    var applyFilters: ((_ status: String?, _ priority: String?, _ deadline: String?) -> Void)?

    // MARK: - UI Elements - Status Filter Section
    
    // Label for status section
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Filtered by Status:"
        label.font = .boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Segmented control for selecting status
    // Options: "Complete", "In Progress", "Assigned"
    private let statusSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Complete", "In Progress", "Assigned"])
        sc.selectedSegmentIndex = UISegmentedControl.noSegment  // Nothing selected by default
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    // MARK: - UI Elements - Priority Filter Section
    
    // Label for priority section
    private let priorityLabel: UILabel = {
        let label = UILabel()
        label.text = "Filtered by Priority:"
        label.font = .boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Segmented control for selecting priority
    // Options: "High", "Medium", "Low"
    private let prioritySegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["High", "Medium", "Low"])
        sc.selectedSegmentIndex = UISegmentedControl.noSegment  // Nothing selected by default
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    // MARK: - UI Elements - Deadline Filter Section
    
    // Label for deadline section
    private let deadlineLabel: UILabel = {
        let label = UILabel()
        label.text = "Filtered by Deadline:"
        label.font = .boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Segmented control for selecting deadline sort order
    // Options: "Nearest" (soonest first), "Furthest" (latest first)
    private let deadlineSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Nearest", "Furthest"])
        sc.selectedSegmentIndex = UISegmentedControl.noSegment  // Nothing selected by default
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    // MARK: - UI Elements - Apply Button
    
    // Button to apply the selected filters
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Apply Filters", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Semi-transparent black background
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        // Setup the UI layout
        setupUI()
        
        // Connect the apply button to its action method
        saveButton.addTarget(self, action: #selector(applyButtonTapped), for: .touchUpInside)
    }

    // MARK: - Setup UI Layout
    // Creates and positions all the UI elements
    private func setupUI() {
        // Create white container for the modal
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        // Add all UI elements to the container
        container.addSubview(statusLabel)
        container.addSubview(statusSegment)
        container.addSubview(priorityLabel)
        container.addSubview(prioritySegment)
        container.addSubview(deadlineLabel)
        container.addSubview(deadlineSegment)
        container.addSubview(saveButton)

        // MARK: - Auto Layout Constraints
        // Position all elements inside the container
        NSLayoutConstraint.activate([
            // Container centered on screen, 80% width
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),

            // Status label at top
            statusLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),

            // Status segmented control below label
            statusSegment.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            statusSegment.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            statusSegment.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            // Priority label below status segment
            priorityLabel.topAnchor.constraint(equalTo: statusSegment.bottomAnchor, constant: 20),
            priorityLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),

            // Priority segmented control below label
            prioritySegment.topAnchor.constraint(equalTo: priorityLabel.bottomAnchor, constant: 8),
            prioritySegment.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            prioritySegment.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            // Deadline label below priority segment
            deadlineLabel.topAnchor.constraint(equalTo: prioritySegment.bottomAnchor, constant: 20),
            deadlineLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),

            // Deadline segmented control below label
            deadlineSegment.topAnchor.constraint(equalTo: deadlineLabel.bottomAnchor, constant: 8),
            deadlineSegment.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            deadlineSegment.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            // Apply button at bottom
            saveButton.topAnchor.constraint(equalTo: deadlineSegment.bottomAnchor, constant: 20),
            saveButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            saveButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Apply Button Action
    // Called when user taps "Apply Filters"
    @objc private func applyButtonTapped() {
        
        // MARK: - Map Status Selection
        // Convert segment index to status string
        var statusValue: String? = nil
        switch statusSegment.selectedSegmentIndex {
        case 0: statusValue = "complete"      // User selected "Complete"
        case 1: statusValue = "in progress"   // User selected "In Progress"
        case 2: statusValue = "assigned"      // User selected "Assigned"
        default: statusValue = nil            // Nothing selected
        }

        // MARK: - Map Priority Selection
        // Convert segment index to priority string
        // ✅ FIXED: Now correctly maps to High, Medium, Low only
        var priorityValue: String? = nil
        switch prioritySegment.selectedSegmentIndex {
        case 0: priorityValue = "High"     // User selected "High"
        case 1: priorityValue = "Medium"   // User selected "Medium"
        case 2: priorityValue = "Low"      // User selected "Low"
        default: priorityValue = nil       // Nothing selected
        }

        // MARK: - Map Deadline Selection
        // Convert segment index to deadline sort order
        var deadlineValue: String? = nil
        switch deadlineSegment.selectedSegmentIndex {
        case 0: deadlineValue = "nearest"   // Show tickets with earliest deadlines first
        case 1: deadlineValue = "furthest"  // Show tickets with latest deadlines first
        default: deadlineValue = nil        // No deadline sorting
        }

        // Log what filters were selected (for debugging)
        print("🔍 Applying filters - Status: \(statusValue ?? "none"), Priority: \(priorityValue ?? "none"), Deadline: \(deadlineValue ?? "none")")

        // Dismiss this modal, then call the callback with selected filters
        dismiss(animated: true) {
            self.applyFilters?(statusValue, priorityValue, deadlineValue)
        }
    }
}
