//
//  FeedbackFilterModal.swift
//  Enhanced filter modal with segmented controls
//
import UIKit

class FeedbackFilterModal: UIViewController {
    
    var applyFilters: ((String?, String?, String?) -> Void)?
    
    var availableStatuses: [String] = []
    var availableCategories: [String] = []
    
    private var selectedStatus: String = "All"
    private var selectedPriority: String = "All"
    private var selectedSortOrder: String = "None"
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    
    // Segmented Controls
    private let statusSegmentedControl = UISegmentedControl(items: ["All", "Assigned", "In Progress", "Label"])
    private let prioritySegmentedControl = UISegmentedControl(items: ["All", "High", "Medium", "Low"])
    private let sortSegmentedControl = UISegmentedControl(items: ["None", "Nearest First", "Farthest First"])
    
    private let saveButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        setupUI()
    }
    
    func setupUI() {
        // Container
        containerView.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 245/255, alpha: 1)
        containerView.layer.cornerRadius = 20
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Title
        titleLabel.text = "Filters"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Close button
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .systemGray
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
        containerView.addSubview(closeButton)
        
        // Filter by Status Section
        let statusLabel = createSectionLabel(text: "Filter by Status")
        containerView.addSubview(statusLabel)
        
        setupSegmentedControl(statusSegmentedControl)
        statusSegmentedControl.selectedSegmentIndex = 0
        statusSegmentedControl.addTarget(self, action: #selector(statusChanged), for: .valueChanged)
        containerView.addSubview(statusSegmentedControl)
        
        // Filter by Priority Section
        let priorityLabel = createSectionLabel(text: "Filter by Priority")
        containerView.addSubview(priorityLabel)
        
        setupSegmentedControl(prioritySegmentedControl)
        prioritySegmentedControl.selectedSegmentIndex = 0
        prioritySegmentedControl.addTarget(self, action: #selector(priorityChanged), for: .valueChanged)
        containerView.addSubview(priorityLabel)
        containerView.addSubview(prioritySegmentedControl)
        
        // Sort by Deadline Section
        let sortLabel = createSectionLabel(text: "Sort by Deadline:")
        containerView.addSubview(sortLabel)
        
        setupSegmentedControl(sortSegmentedControl)
        sortSegmentedControl.selectedSegmentIndex = 0
        sortSegmentedControl.addTarget(self, action: #selector(sortChanged), for: .valueChanged)
        containerView.addSubview(sortLabel)
        containerView.addSubview(sortSegmentedControl)
        
        // Save Button
        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        saveButton.backgroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 12
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        containerView.addSubview(saveButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Status section
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            
            statusSegmentedControl.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            statusSegmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            statusSegmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
            statusSegmentedControl.heightAnchor.constraint(equalToConstant: 50),
            
            // Priority section
            priorityLabel.topAnchor.constraint(equalTo: statusSegmentedControl.bottomAnchor, constant: 30),
            priorityLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            
            prioritySegmentedControl.topAnchor.constraint(equalTo: priorityLabel.bottomAnchor, constant: 12),
            prioritySegmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            prioritySegmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
            prioritySegmentedControl.heightAnchor.constraint(equalToConstant: 50),
            
            // Sort section
            sortLabel.topAnchor.constraint(equalTo: prioritySegmentedControl.bottomAnchor, constant: 30),
            sortLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            
            sortSegmentedControl.topAnchor.constraint(equalTo: sortLabel.bottomAnchor, constant: 12),
            sortSegmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            sortSegmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
            sortSegmentedControl.heightAnchor.constraint(equalToConstant: 50),
            
            // Save button
            saveButton.topAnchor.constraint(equalTo: sortSegmentedControl.bottomAnchor, constant: 40),
            saveButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            saveButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
            saveButton.heightAnchor.constraint(equalToConstant: 55),
            saveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30)
        ])
    }
    
    func setupSegmentedControl(_ control: UISegmentedControl) {
        control.backgroundColor = UIColor(red: 210/255, green: 210/255, blue: 220/255, alpha: 1)
        control.selectedSegmentTintColor = UIColor(red: 200/255, green: 200/255, blue: 210/255, alpha: 1)
        
        // Text attributes for normal state
        control.setTitleTextAttributes([
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 15, weight: .medium)
        ], for: .normal)
        
        // Text attributes for selected state
        control.setTitleTextAttributes([
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold)
        ], for: .selected)
        
        control.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func createSectionLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    @objc func statusChanged() {
        let selectedIndex = statusSegmentedControl.selectedSegmentIndex
        selectedStatus = statusSegmentedControl.titleForSegment(at: selectedIndex) ?? "All"
    }
    
    @objc func priorityChanged() {
        let selectedIndex = prioritySegmentedControl.selectedSegmentIndex
        selectedPriority = prioritySegmentedControl.titleForSegment(at: selectedIndex) ?? "All"
    }
    
    @objc func sortChanged() {
        let selectedIndex = sortSegmentedControl.selectedSegmentIndex
        selectedSortOrder = sortSegmentedControl.titleForSegment(at: selectedIndex) ?? "None"
    }
    
    @objc func saveTapped() {
        applyFilters?(
            selectedStatus == "All" ? nil : selectedStatus,
            selectedPriority == "All" ? nil : selectedPriority,
            selectedSortOrder == "None" ? nil : selectedSortOrder
        )
        dismiss(animated: true)
    }
    
    @objc func dismissModal() {
        dismiss(animated: true)
    }
}
