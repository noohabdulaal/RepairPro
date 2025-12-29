//
//  FeedbackFilterModal.swift
//  FLEXIBLE VERSION - Works with any status/category values
//

import UIKit

class FeedbackFilterModal: UIViewController {
    
    var applyFilters: ((String?, String?, Int?) -> Void)?
    
    // Dynamic values from existing feedback
    var availableStatuses: [String] = []
    var availableCategories: [String] = []
    
    private var selectedStatus: String?
    private var selectedCategory: String?
    private var selectedRating: Int?
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    
    private var statusButtons: [UIButton] = []
    private var categoryButtons: [UIButton] = []
    private let ratingButtons: [UIButton] = {
        return (1...5).map { rating in
            let button = UIButton(type: .system)
            button.setTitle("\(rating) ⭐", for: .normal)
            button.tag = rating
            return button
        }
    }()
    
    private let clearButton = UIButton(type: .system)
    private let applyButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Create buttons dynamically based on available values
        createDynamicButtons()
        
        setupContainerView()
        setupTitleSection()
        setupFilters()
        setupActionButtons()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissModal))
        view.addGestureRecognizer(tapGesture)
    }
    
    func createDynamicButtons() {
        // Create status buttons from available statuses
        statusButtons = availableStatuses.enumerated().map { index, status in
            let button = UIButton(type: .system)
            button.setTitle(status, for: .normal)
            button.tag = index
            return button
        }
        
        // Create category buttons from available categories
        categoryButtons = availableCategories.enumerated().map { index, category in
            let button = UIButton(type: .system)
            button.setTitle(category, for: .normal)
            button.tag = index
            return button
        }
    }
    
    func setupContainerView() {
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 20
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            containerView.heightAnchor.constraint(lessThanOrEqualToConstant: 650)
        ])
    }
    
    func setupTitleSection() {
        titleLabel.text = "Filter Feedback"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .systemGray
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
        containerView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func setupFilters() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(scrollView)
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -100),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        var topConstraint = contentView.topAnchor
        
        // Status Section (if any statuses available)
        if !statusButtons.isEmpty {
            let (label, stack) = createFilterSection(
                title: "Status",
                buttons: statusButtons,
                action: #selector(statusTapped)
            )
            contentView.addSubview(label)
            contentView.addSubview(stack)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: topConstraint, constant: 16),
                label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
                
                stack.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
                stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
                stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
            ])
            
            topConstraint = stack.bottomAnchor
        }
        
        // Category Section (if any categories available)
        if !categoryButtons.isEmpty {
            let (label, stack) = createFilterSection(
                title: "Category",
                buttons: categoryButtons,
                action: #selector(categoryTapped)
            )
            contentView.addSubview(label)
            contentView.addSubview(stack)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: topConstraint, constant: 24),
                label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
                
                stack.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
                stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
                stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
            ])
            
            topConstraint = stack.bottomAnchor
        }
        
        // Rating Section (always shown)
        let (ratingLabel, ratingStack) = createFilterSection(
            title: "Rating",
            buttons: ratingButtons,
            action: #selector(ratingTapped)
        )
        contentView.addSubview(ratingLabel)
        contentView.addSubview(ratingStack)
        
        NSLayoutConstraint.activate([
            ratingLabel.topAnchor.constraint(equalTo: topConstraint, constant: 24),
            ratingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            
            ratingStack.topAnchor.constraint(equalTo: ratingLabel.bottomAnchor, constant: 12),
            ratingStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            ratingStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            ratingStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    func createFilterSection(title: String, buttons: [UIButton], action: Selector) -> (UILabel, UIStackView) {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        for button in buttons {
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            button.setTitleColor(.label, for: .normal)
            button.backgroundColor = .secondarySystemBackground
            button.layer.cornerRadius = 10
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            button.addTarget(self, action: action, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
        
        return (label, stack)
    }
    
    func setupActionButtons() {
        clearButton.setTitle("Clear Filters", for: .normal)
        clearButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        clearButton.setTitleColor(.systemRed, for: .normal)
        clearButton.backgroundColor = .secondarySystemBackground
        clearButton.layer.cornerRadius = 12
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.addTarget(self, action: #selector(clearFilters), for: .touchUpInside)
        containerView.addSubview(clearButton)
        
        applyButton.setTitle("Apply Filters", for: .normal)
        applyButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        applyButton.setTitleColor(.white, for: .normal)
        applyButton.backgroundColor = .systemBlue
        applyButton.layer.cornerRadius = 12
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.addTarget(self, action: #selector(applyFiltersAction), for: .touchUpInside)
        containerView.addSubview(applyButton)
        
        NSLayoutConstraint.activate([
            clearButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            clearButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            clearButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.4),
            clearButton.heightAnchor.constraint(equalToConstant: 50),
            
            applyButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            applyButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            applyButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.4),
            applyButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Actions
    @objc func statusTapped(_ sender: UIButton) {
        let status = availableStatuses[sender.tag]
        
        if selectedStatus == status {
            selectedStatus = nil
            sender.backgroundColor = .secondarySystemBackground
        } else {
            statusButtons.forEach { $0.backgroundColor = .secondarySystemBackground }
            selectedStatus = status
            sender.backgroundColor = .systemBlue.withAlphaComponent(0.3)
        }
    }
    
    @objc func categoryTapped(_ sender: UIButton) {
        let category = availableCategories[sender.tag]
        
        if selectedCategory == category {
            selectedCategory = nil
            sender.backgroundColor = .secondarySystemBackground
        } else {
            categoryButtons.forEach { $0.backgroundColor = .secondarySystemBackground }
            selectedCategory = category
            sender.backgroundColor = .systemBlue.withAlphaComponent(0.3)
        }
    }
    
    @objc func ratingTapped(_ sender: UIButton) {
        let rating = sender.tag
        
        if selectedRating == rating {
            selectedRating = nil
            sender.backgroundColor = .secondarySystemBackground
        } else {
            ratingButtons.forEach { $0.backgroundColor = .secondarySystemBackground }
            selectedRating = rating
            sender.backgroundColor = .systemBlue.withAlphaComponent(0.3)
        }
    }
    
    @objc func clearFilters() {
        selectedStatus = nil
        selectedCategory = nil
        selectedRating = nil
        
        statusButtons.forEach { $0.backgroundColor = .secondarySystemBackground }
        categoryButtons.forEach { $0.backgroundColor = .secondarySystemBackground }
        ratingButtons.forEach { $0.backgroundColor = .secondarySystemBackground }
        
        applyFilters?(nil, nil, nil)
        dismiss(animated: true)
    }
    
    @objc func applyFiltersAction() {
        applyFilters?(selectedStatus, selectedCategory, selectedRating)
        dismiss(animated: true)
    }
    
    @objc func dismissModal() {
        dismiss(animated: true)
    }
}
