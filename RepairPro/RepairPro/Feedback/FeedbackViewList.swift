//
//  FeedbackViewList.swift
//  WITH TOP FILTERS - Technician and Time period selection
//

import UIKit
import FirebaseFirestore
import Cloudinary

class FeedbackViewList: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    var feedbackArray: [Feedback] = []
    var filteredFeedback: [Feedback] = []
    
    // Filter states
    var currentStatusFilter: String? = nil
    var currentCategoryFilter: String? = nil
    var currentRatingFilter: Int? = nil
    var currentTechnicianFilter: String? = nil  // NEW
    var currentTimePeriodFilter: String? = nil  // NEW
    
    // Top filter buttons
    private var timePeriodButton: UIButton!
    private var technicianButton: UIButton!
    private var topFilterStack: UIStackView!
    
    let db = Firestore.firestore()
    let cloudinary = CLDCloudinary(configuration: CLDConfiguration(cloudName: "dtthzideh"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Feedback History"
        view.backgroundColor = .systemGroupedBackground
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        setupTopFilters()  // NEW: Setup top filter buttons
        setupScrollViewAndStackView()
        setupFilterButton()
        fetchFeedback()
    }
    
    // MARK: - Setup Top Filters (NEW)
    func setupTopFilters() {
        // Container for top filters
        let filterContainer = UIView()
        filterContainer.backgroundColor = .systemGroupedBackground
        filterContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(filterContainer)
        
        // Stack for filter buttons
        topFilterStack = UIStackView()
        topFilterStack.axis = .horizontal
        topFilterStack.spacing = 12
        topFilterStack.distribution = .fillEqually
        topFilterStack.translatesAutoresizingMaskIntoConstraints = false
        filterContainer.addSubview(topFilterStack)
        
        // Time Period Button
        timePeriodButton = createTopFilterButton(
            title: "All Time",
            icon: "clock",
            action: #selector(timePeriodFilterTapped)
        )
        topFilterStack.addArrangedSubview(timePeriodButton)
        
        // Technician Button
        technicianButton = createTopFilterButton(
            title: "All Technicians",
            icon: "person.2",
            action: #selector(technicianFilterTapped)
        )
        topFilterStack.addArrangedSubview(technicianButton)
        
        NSLayoutConstraint.activate([
            filterContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            filterContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterContainer.heightAnchor.constraint(equalToConstant: 60),
            
            topFilterStack.leadingAnchor.constraint(equalTo: filterContainer.leadingAnchor, constant: 16),
            topFilterStack.trailingAnchor.constraint(equalTo: filterContainer.trailingAnchor, constant: -16),
            topFilterStack.topAnchor.constraint(equalTo: filterContainer.topAnchor, constant: 8),
            topFilterStack.bottomAnchor.constraint(equalTo: filterContainer.bottomAnchor, constant: -8)
        ])
    }
    
    func createTopFilterButton(title: String, icon: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        
        // Configure button appearance
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .secondarySystemGroupedBackground
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Add icon
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = UIImage(systemName: icon, withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .label
        
        // Layout image and title
        button.semanticContentAttribute = .forceLeftToRight
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        
        button.addTarget(self, action: action, for: .touchUpInside)
        
        return button
    }
    
    @objc func timePeriodFilterTapped() {
        let alert = UIAlertController(title: "Select Time Period", message: nil, preferredStyle: .actionSheet)
        
        let periods = [
            ("All Time", nil),
            ("Past 24 Hours", 1),
            ("Past 3 Days", 3),
            ("Past Week", 7),
            ("Past Month", 30)
        ]
        
        for (title, days) in periods {
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.applyTimePeriodFilter(title: title, days: days)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = timePeriodButton
            popover.sourceRect = timePeriodButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc func technicianFilterTapped() {
        // Get unique technicians from feedback
        let technicians = Set(feedbackArray.compactMap { $0.user_name })
        let sortedTechnicians = technicians.sorted()
        
        let alert = UIAlertController(title: "Select Technician", message: nil, preferredStyle: .actionSheet)
        
        // All Technicians option
        alert.addAction(UIAlertAction(title: "All Technicians", style: .default) { [weak self] _ in
            self?.applyTechnicianFilter(technician: nil)
        })
        
        // Individual technicians
        for technician in sortedTechnicians {
            alert.addAction(UIAlertAction(title: technician, style: .default) { [weak self] _ in
                self?.applyTechnicianFilter(technician: technician)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = technicianButton
            popover.sourceRect = technicianButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    func applyTimePeriodFilter(title: String, days: Int?) {
        currentTimePeriodFilter = days != nil ? "\(days!)" : nil
        timePeriodButton.setTitle(title, for: .normal)
        
        // Update button appearance
        if days != nil {
            timePeriodButton.backgroundColor = .systemBlue.withAlphaComponent(0.2)
            timePeriodButton.layer.borderColor = UIColor.systemBlue.cgColor
            timePeriodButton.setTitleColor(.systemBlue, for: .normal)
            timePeriodButton.tintColor = .systemBlue
        } else {
            timePeriodButton.backgroundColor = .secondarySystemGroupedBackground
            timePeriodButton.layer.borderColor = UIColor.systemGray4.cgColor
            timePeriodButton.setTitleColor(.label, for: .normal)
            timePeriodButton.tintColor = .label
        }
        
        applyCurrentFilters()
    }
    
    func applyTechnicianFilter(technician: String?) {
        currentTechnicianFilter = technician
        technicianButton.setTitle(technician ?? "All Technicians", for: .normal)
        
        // Update button appearance
        if technician != nil {
            technicianButton.backgroundColor = .systemBlue.withAlphaComponent(0.2)
            technicianButton.layer.borderColor = UIColor.systemBlue.cgColor
            technicianButton.setTitleColor(.systemBlue, for: .normal)
            technicianButton.tintColor = .systemBlue
        } else {
            technicianButton.backgroundColor = .secondarySystemGroupedBackground
            technicianButton.layer.borderColor = UIColor.systemGray4.cgColor
            technicianButton.setTitleColor(.label, for: .normal)
            technicianButton.tintColor = .label
        }
        
        applyCurrentFilters()
    }
    
    func setupScrollViewAndStackView() {
        scrollView.constraints.forEach { scrollView.removeConstraint($0) }
        stackView.constraints.forEach { stackView.removeConstraint($0) }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),  // Offset for top filters
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.distribution = .fill
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    func setupFilterButton() {
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "slider.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(filterButtonTapped)
        )
        filterButton.tintColor = .systemBlue
        navigationItem.rightBarButtonItem = filterButton
    }
    
    @objc func filterButtonTapped() {
        let filterVC = FeedbackFilterModal()
        filterVC.modalPresentationStyle = .overFullScreen
        
        // Get unique values from existing feedback
        let statuses = Set(feedbackArray.map { $0.status })
        let categories = Set(feedbackArray.map { $0.category })
        
        filterVC.availableStatuses = Array(statuses)
        filterVC.availableCategories = Array(categories)
        
        filterVC.applyFilters = { [weak self] status, category, rating in
            self?.applyFilters(status: status, category: category, rating: rating)
        }
        present(filterVC, animated: true)
    }
    
    // MARK: - Fetch Feedback from Firebase
    func fetchFeedback() {
        print("🔍 Fetching from 'Feedback' collection...")
        
        db.collection("Feedback").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ FIREBASE ERROR: \(error.localizedDescription)")
                self.showErrorAlert(message: "Failed to load feedback.")
                return
            }
            
            guard let snapshot = snapshot else {
                print("❌ SNAPSHOT ERROR: No data received.")
                return
            }
            
            print("✅ Received \(snapshot.documents.count) feedback documents")
            
            var feedbacks: [Feedback] = []
            
            for doc in snapshot.documents {
                print("--- Feedback Document \(doc.documentID) ---")
                let data = doc.data()
                print("📋 Fields: \(data.keys.joined(separator: ", "))")
                
                do {
                    let feedback = try doc.data(as: Feedback.self)
                    feedbacks.append(feedback)
                    print("✅ Decoded feedback ID: \(feedback.feedback_id)")
                } catch {
                    print("❌ DECODING ERROR for \(doc.documentID): \(error)")
                    print("   Data: \(data)")
                }
            }
            
            DispatchQueue.main.async {
                self.feedbackArray = feedbacks
                self.applyCurrentFilters()
                print("✅ Displaying \(self.feedbackArray.count) feedback items")
            }
        }
    }
    
    // MARK: - Filtering
    func applyFilters(status: String?, category: String?, rating: Int?) {
        currentStatusFilter = status
        currentCategoryFilter = category
        currentRatingFilter = rating
        applyCurrentFilters()
    }
    
    func applyCurrentFilters() {
        filteredFeedback = feedbackArray
        
        // Filter by technician (user_name)
        if let technician = currentTechnicianFilter {
            filteredFeedback = filteredFeedback.filter {
                $0.user_name.lowercased() == technician.lowercased()
            }
            print("🔍 Filtered by technician '\(technician)': \(filteredFeedback.count) items")
        }
        
        // Filter by time period
        if let daysString = currentTimePeriodFilter, let days = Int(daysString) {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
            let formatter = ISO8601DateFormatter()
            
            filteredFeedback = filteredFeedback.filter { feedback in
                if let submittedDate = formatter.date(from: feedback.date_submitted) {
                    return submittedDate >= cutoffDate
                }
                return false
            }
            print("🔍 Filtered by past \(days) days: \(filteredFeedback.count) items")
        }
        
        // Filter by status
        if let status = currentStatusFilter {
            filteredFeedback = filteredFeedback.filter {
                $0.status.lowercased() == status.lowercased()
            }
            print("🔍 Filtered by status '\(status)': \(filteredFeedback.count) items")
        }
        
        // Filter by category
        if let category = currentCategoryFilter {
            filteredFeedback = filteredFeedback.filter {
                $0.category.lowercased() == category.lowercased()
            }
            print("🔍 Filtered by category '\(category)': \(filteredFeedback.count) items")
        }
        
        // Filter by rating
        if let rating = currentRatingFilter {
            filteredFeedback = filteredFeedback.filter {
                $0.safeRating == rating
            }
            print("🔍 Filtered by rating \(rating): \(filteredFeedback.count) items")
        }
        
        displayFeedback(filteredFeedback)
        print("✅ Displaying \(filteredFeedback.count) feedback items after filters")
    }
    
    func displayFeedback(_ feedbacks: [Feedback]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if feedbacks.isEmpty {
            showEmptyState()
        } else {
            feedbacks.forEach { createFeedbackCard(for: $0) }
        }
    }
    
    func showEmptyState() {
        let emptyLabel = UILabel()
        emptyLabel.text = "No feedback found"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .systemGray
        emptyLabel.font = .systemFont(ofSize: 18, weight: .medium)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(emptyLabel)
    }
    
    // MARK: - Create Feedback Card
    func createFeedbackCard(for feedback: Feedback) {
        let statusColor = getStatusColor(for: feedback.status)
        
        let containerView = UIView()
        containerView.backgroundColor = .secondarySystemGroupedBackground
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let baseHeight: CGFloat = 220
        let hasResponse = feedback.hasResponse
        let hasCampus = feedback.campus != nil
        let extraHeight: CGFloat = (hasResponse ? 40.0 : 0.0) + (hasCampus ? 20.0 : 0.0)
        containerView.heightAnchor.constraint(equalToConstant: baseHeight + extraHeight).isActive = true
        
        containerView.tag = feedback.feedback_id
        let tap = UITapGestureRecognizer(target: self, action: #selector(feedbackTapped(_:)))
        containerView.addGestureRecognizer(tap)
        containerView.isUserInteractionEnabled = true
        
        // Colored side bar
        let sideBar = UIView()
        sideBar.backgroundColor = statusColor
        sideBar.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(sideBar)
        
        // Feedback ID
        let feedbackIDLabel = UILabel()
        feedbackIDLabel.text = "Feedback #\(feedback.feedback_id)"
        feedbackIDLabel.font = .systemFont(ofSize: 18, weight: .bold)
        feedbackIDLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(feedbackIDLabel)
        
        // Category with emoji
        let categoryLabel = UILabel()
        categoryLabel.text = "\(feedback.categoryEmoji) \(feedback.category)"
        categoryLabel.font = .systemFont(ofSize: 14, weight: .medium)
        categoryLabel.textColor = .secondaryLabel
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(categoryLabel)
        
        // Star rating
        let starStack = createStarRating(rating: feedback.safeRating)
        starStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(starStack)
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = feedback.title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Description
        let descriptionLabel = UILabel()
        descriptionLabel.text = feedback.description
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 3
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(descriptionLabel)
        
        // User info
        let userLabel = UILabel()
        userLabel.text = "👤 \(feedback.user_name)"
        userLabel.font = .systemFont(ofSize: 13)
        userLabel.textColor = .label
        userLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(userLabel)
        
        // Time ago
        let timeLabel = UILabel()
        timeLabel.text = "🕐 \(feedback.timeAgo)"
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = .systemGray
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(timeLabel)
        
        // Status badge
        let statusBadge = createStatusBadge(status: feedback.status, color: statusColor)
        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusBadge)
        
        // Response indicator
        var responseIndicator: UIView?
        if feedback.hasResponse {
            let indicator = UIView()
            indicator.backgroundColor = .systemGreen.withAlphaComponent(0.2)
            indicator.layer.cornerRadius = 8
            indicator.translatesAutoresizingMaskIntoConstraints = false
            
            let label = UILabel()
            label.text = "✓ Admin Response Available"
            label.font = .systemFont(ofSize: 12, weight: .medium)
            label.textColor = .systemGreen
            label.translatesAutoresizingMaskIntoConstraints = false
            indicator.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: indicator.leadingAnchor, constant: 8),
                label.trailingAnchor.constraint(equalTo: indicator.trailingAnchor, constant: -8),
                label.topAnchor.constraint(equalTo: indicator.topAnchor, constant: 6),
                label.bottomAnchor.constraint(equalTo: indicator.bottomAnchor, constant: -6)
            ])
            
            containerView.addSubview(indicator)
            responseIndicator = indicator
        }
        
        // Campus label
        var campusLabel: UILabel?
        if let campus = feedback.campus {
            let label = UILabel()
            label.text = "📍 Campus \(campus)"
            label.font = .systemFont(ofSize: 13)
            label.textColor = .secondaryLabel
            label.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(label)
            campusLabel = label
        }
        
        // Priority indicator
        var priorityDot: UIView?
        var priorityLabel: UILabel?
        if let priority = feedback.priority {
            let dot = UIView()
            dot.backgroundColor = feedback.priorityColor
            dot.layer.cornerRadius = 6
            dot.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(dot)
            priorityDot = dot
            
            let label = UILabel()
            label.text = "\(priority) Priority"
            label.font = .systemFont(ofSize: 11, weight: .medium)
            label.textColor = feedback.priorityColor
            label.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(label)
            priorityLabel = label
            
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 12),
                dot.heightAnchor.constraint(equalToConstant: 12),
                label.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 4),
                label.centerYAnchor.constraint(equalTo: dot.centerYAnchor)
            ])
        }
        
        // Image preview
        var imagePreview: UIImageView?
        if let imageURLs = feedback.image_urls, !imageURLs.isEmpty, let firstImage = imageURLs.first {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 12
            imageView.backgroundColor = .systemGray5
            imageView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(imageView)
            imagePreview = imageView
            
            loadImageFromCloudinary(publicIDOrURL: firstImage, into: imageView)
            
            if imageURLs.count > 1 {
                let badge = UILabel()
                badge.text = "+\(imageURLs.count - 1)"
                badge.font = .systemFont(ofSize: 10, weight: .bold)
                badge.textColor = .white
                badge.backgroundColor = .black.withAlphaComponent(0.7)
                badge.textAlignment = .center
                badge.layer.cornerRadius = 10
                badge.clipsToBounds = true
                badge.translatesAutoresizingMaskIntoConstraints = false
                imageView.addSubview(badge)
                
                NSLayoutConstraint.activate([
                    badge.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -4),
                    badge.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -4),
                    badge.widthAnchor.constraint(equalToConstant: 20),
                    badge.heightAnchor.constraint(equalToConstant: 20)
                ])
            }
        }
        
        // Layout constraints
        var constraints = [
            sideBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            sideBar.topAnchor.constraint(equalTo: containerView.topAnchor),
            sideBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            sideBar.widthAnchor.constraint(equalToConstant: 6),
            
            feedbackIDLabel.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 16),
            feedbackIDLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            
            categoryLabel.leadingAnchor.constraint(equalTo: feedbackIDLabel.trailingAnchor, constant: 12),
            categoryLabel.centerYAnchor.constraint(equalTo: feedbackIDLabel.centerYAnchor),
            
            statusBadge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            statusBadge.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            
            starStack.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 16),
            starStack.topAnchor.constraint(equalTo: feedbackIDLabel.bottomAnchor, constant: 8),
            
            titleLabel.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: starStack.bottomAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 16),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6)
        ]
        
        if let imageView = imagePreview {
            constraints.append(contentsOf: [
                imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                imageView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
                imageView.widthAnchor.constraint(equalToConstant: 80),
                imageView.heightAnchor.constraint(equalToConstant: 80),
                descriptionLabel.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -12)
            ])
        } else {
            constraints.append(
                descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
            )
        }
        
        constraints.append(contentsOf: [
            userLabel.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 16),
            userLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            timeLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
        
        if let indicator = responseIndicator {
            constraints.append(contentsOf: [
                indicator.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 16),
                indicator.bottomAnchor.constraint(equalTo: userLabel.topAnchor, constant: -8),
                indicator.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16)
            ])
        }
        
        if let campus = campusLabel {
            if let indicator = responseIndicator {
                constraints.append(contentsOf: [
                    campus.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 16),
                    campus.bottomAnchor.constraint(equalTo: indicator.topAnchor, constant: -8)
                ])
            } else {
                constraints.append(contentsOf: [
                    campus.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 16),
                    campus.bottomAnchor.constraint(equalTo: userLabel.topAnchor, constant: -8)
                ])
            }
        }
        
        if let dot = priorityDot, let label = priorityLabel {
            constraints.append(contentsOf: [
                dot.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: -8),
                dot.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
                label.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8)
            ])
        }
        
        NSLayoutConstraint.activate(constraints)
        stackView.addArrangedSubview(containerView)
    }
    
    func createStarRating(rating: Int) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
        
        for i in 1...5 {
            let star = UILabel()
            star.text = i <= rating ? "⭐" : "☆"
            star.font = .systemFont(ofSize: 20)
            stackView.addArrangedSubview(star)
        }
        
        let ratingLabel = UILabel()
        ratingLabel.text = "(\(rating)/5)"
        ratingLabel.font = .systemFont(ofSize: 14, weight: .medium)
        ratingLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(ratingLabel)
        
        return stackView
    }
    
    func createStatusBadge(status: String, color: UIColor) -> UIView {
        let badge = UIView()
        badge.backgroundColor = color.withAlphaComponent(0.2)
        badge.layer.cornerRadius = 12
        
        let label = UILabel()
        label.text = status
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = color
        label.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: badge.topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -6)
        ])
        
        return badge
    }
    
    @objc func feedbackTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view,
              let feedback = feedbackArray.first(where: { $0.feedback_id == view.tag }) else { return }
        
        let detailVC = FeedbackDetailViewController()
        detailVC.feedback = feedback
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func getStatusColor(for status: String) -> UIColor {
        let lowercased = status.lowercased()
        
        if lowercased.contains("good") || lowercased.contains("resolve") || lowercased.contains("complete") || lowercased.contains("done") || lowercased.contains("fixed") {
            return UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1)
        } else if lowercased.contains("review") || lowercased.contains("progress") || lowercased.contains("working") {
            return UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        } else if lowercased.contains("pending") || lowercased.contains("wait") || lowercased.contains("new") {
            return UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1)
        } else if lowercased.contains("close") || lowercased.contains("reject") || lowercased.contains("cancel") {
            return UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)
        } else if lowercased.contains("bad") || lowercased.contains("urgent") || lowercased.contains("critical") {
            return .systemRed
        } else {
            return .systemBlue
        }
    }
    
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
    
    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
