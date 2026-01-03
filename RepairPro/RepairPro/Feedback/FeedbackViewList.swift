//
//  FeedbackViewList.swift
//  WORKING VERSION - With proper technician filtering
//

import UIKit
import FirebaseFirestore
import Cloudinary

class FeedbackViewList: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    var feedbackArray: [Feedback] = []
    var filteredFeedback: [Feedback] = []
    
    var currentTechnicianFilter: String? = nil
    var currentDateFilter: String = "All Time"
    
    // MARK: - Notification Properties
    var existingFeedbackIDs: Set<Int> = []  // Track which feedbacks we've already seen
    var isFirstLoad = true  // Don't show notifications on initial load
    var currentNotificationView: UIView?  // Reference to active notification
    
    let db = Firestore.firestore()
    let cloudinary = CLDCloudinary(configuration: CLDConfiguration(cloudName: "dtthzideh"))
    
    // Filter chips container
    private let filterChipsContainer = UIView()
    private let dateFilterButton = UIButton(type: .system)
    private let technicianFilterButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Feedback History"
        view.backgroundColor = .systemBackground
        
        setupFilterChips()
        setupScrollViewAndStackView()
        fetchFeedback()
    }
    
    func setupFilterChips() {
        filterChipsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(filterChipsContainer)
        
        // Date filter chip
        var dateConfig = UIButton.Configuration.filled()
        dateConfig.title = "All Time"
        dateConfig.baseForegroundColor = .white
        dateConfig.baseBackgroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1)
        dateConfig.cornerStyle = .capsule
        dateConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        let chevronImage = UIImage(systemName: "chevron.down", withConfiguration: chevronConfig)
        dateConfig.image = chevronImage
        dateConfig.imagePlacement = .trailing
        dateConfig.imagePadding = 8
        
        dateFilterButton.configuration = dateConfig
        dateFilterButton.translatesAutoresizingMaskIntoConstraints = false
        dateFilterButton.addTarget(self, action: #selector(dateFilterTapped), for: .touchUpInside)
        filterChipsContainer.addSubview(dateFilterButton)
        
        // Technician filter chip
        var techConfig = UIButton.Configuration.filled()
        techConfig.title = "All Technicians"
        techConfig.baseForegroundColor = .white
        techConfig.baseBackgroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1)
        techConfig.cornerStyle = .capsule
        techConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        techConfig.image = chevronImage
        techConfig.imagePlacement = .trailing
        techConfig.imagePadding = 8
        
        technicianFilterButton.configuration = techConfig
        technicianFilterButton.translatesAutoresizingMaskIntoConstraints = false
        technicianFilterButton.addTarget(self, action: #selector(technicianFilterTapped), for: .touchUpInside)
        filterChipsContainer.addSubview(technicianFilterButton)
        
        NSLayoutConstraint.activate([
            filterChipsContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            filterChipsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterChipsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filterChipsContainer.heightAnchor.constraint(equalToConstant: 50),
            
            dateFilterButton.leadingAnchor.constraint(equalTo: filterChipsContainer.leadingAnchor),
            dateFilterButton.centerYAnchor.constraint(equalTo: filterChipsContainer.centerYAnchor),
            dateFilterButton.heightAnchor.constraint(equalToConstant: 40),
            
            technicianFilterButton.leadingAnchor.constraint(equalTo: dateFilterButton.trailingAnchor, constant: 10),
            technicianFilterButton.centerYAnchor.constraint(equalTo: filterChipsContainer.centerYAnchor),
            technicianFilterButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func setupScrollViewAndStackView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: filterChipsContainer.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        stackView.distribution = .fill
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -12),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    @objc func dateFilterTapped() {
        print("📅 Date filter button tapped")
        
        let dateModal = DateFilterModal()
        dateModal.selectedDate = currentDateFilter
        
        dateModal.applyFilter = { [weak self] selectedDate in
            guard let self = self else { return }
            
            print("✅ Date filter applied: \(selectedDate)")
            
            // Update current filter
            self.currentDateFilter = selectedDate
            
            // Update button title
            var config = self.dateFilterButton.configuration
            config?.title = selectedDate
            self.dateFilterButton.configuration = config
            
            // Apply filters
            self.applyCurrentFilters()
        }
        
        // Present modal
        dateModal.modalPresentationStyle = .overFullScreen
        dateModal.modalTransitionStyle = .crossDissolve
        self.present(dateModal, animated: false)
    }
    
    @objc func technicianFilterTapped() {
        print("🔘 Technician filter button tapped")
        
        let filterModal = FeedbackFilterModal()
        
        // Get unique technician names
        let technicians = Set(feedbackArray.map { $0.user_name })
        filterModal.availableTechnicians = Array(technicians).sorted()
        
        print("📋 Available technicians: \(filterModal.availableTechnicians)")
        print("🎯 Current filter: \(currentTechnicianFilter ?? "None")")
        
        // Set current selection
        filterModal.selectedTechnician = currentTechnicianFilter ?? "All Technicians"
        
        // Handle filter application
        filterModal.applyFilters = { [weak self] selectedTechnician in
            guard let self = self else { return }
            
            print("✅ Filter applied! Selected: \(selectedTechnician ?? "All Technicians")")
            
            // Update the filter
            self.currentTechnicianFilter = selectedTechnician
            
            // Update button title
            let buttonTitle = selectedTechnician ?? "All Technicians"
            print("🔄 Updating button to: \(buttonTitle)")
            
            var config = self.technicianFilterButton.configuration
            config?.title = buttonTitle
            self.technicianFilterButton.configuration = config
            
            // Apply filters
            print("🔍 Applying filters now...")
            self.applyCurrentFilters()
        }
        
        // Present modal
        filterModal.modalPresentationStyle = .overFullScreen
        filterModal.modalTransitionStyle = .crossDissolve
        self.present(filterModal, animated: false)
    }
    
    func fetchFeedback() {
        print("🔍 Fetching feedback...")
        
        db.collection("Feedback").order(by: "date_submitted", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                self.showErrorAlert(message: "Failed to load feedback.")
                return
            }
            
            guard let snapshot = snapshot else {
                print("❌ No snapshot")
                return
            }
            
            print("✅ Received \(snapshot.documents.count) documents")
            
            var feedbacks: [Feedback] = []
            var newFeedbacks: [Feedback] = []  // Track truly new feedback
            
            for doc in snapshot.documents {
                do {
                    let feedback = try doc.data(as: Feedback.self)
                    feedbacks.append(feedback)
                    
                    // Check if this is a NEW feedback (not in our existing set)
                    if !self.isFirstLoad && !self.existingFeedbackIDs.contains(feedback.feedback_id) {
                        newFeedbacks.append(feedback)
                        print("🆕 NEW FEEDBACK DETECTED: #\(feedback.feedback_id)")
                    }
                    
                    print("  ✓ Feedback \(feedback.feedback_id): \(feedback.user_name)")
                } catch {
                    print("  ✗ Error decoding: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.feedbackArray = feedbacks
                print("📊 Total feedbacks: \(feedbacks.count)")
                
                // Update existing feedback IDs
                self.existingFeedbackIDs = Set(self.feedbackArray.map { $0.feedback_id })
                
                // Show notification for new feedback (only after first load)
                if !self.isFirstLoad && !newFeedbacks.isEmpty {
                    for newFeedback in newFeedbacks {
                        self.showNewFeedbackNotification(feedback: newFeedback)
                    }
                }
                
                // Mark first load as complete
                if self.isFirstLoad {
                    self.isFirstLoad = false
                    print("📍 First load complete. Will now show notifications for new feedback.")
                }
                
                self.applyCurrentFilters()
            }
        }
    }
    
    func applyCurrentFilters() {
        print("\n🔍 === APPLYING FILTERS ===")
        print("📊 Total feedbacks: \(feedbackArray.count)")
        print("📅 Date filter: \(currentDateFilter)")
        print("👤 Technician filter: \(currentTechnicianFilter ?? "None")")
        
        filteredFeedback = feedbackArray
        
        // Filter by technician FIRST
        if let technician = currentTechnicianFilter, !technician.isEmpty {
            let beforeCount = filteredFeedback.count
            filteredFeedback = filteredFeedback.filter { feedback in
                let match = feedback.user_name.lowercased() == technician.lowercased()
                print("  Comparing '\(feedback.user_name)' with '\(technician)': \(match ? "✓" : "✗")")
                return match
            }
            print("👤 After technician filter: \(beforeCount) → \(filteredFeedback.count)")
        }
        
        // Filter by date
        if currentDateFilter != "All Time" {
            let now = Date()
            let beforeCount = filteredFeedback.count
            
            print("\n📅 === DATE FILTERING ===")
            print("Filter: \(currentDateFilter)")
            print("Current time: \(now)")
            print("Total items to filter: \(beforeCount)")
            
            var parseErrors = 0
            var passedCount = 0
            var failedCount = 0
            
            filteredFeedback = filteredFeedback.filter { feedback in
                let formatter = ISO8601DateFormatter()
                
                // Try to parse the date
                guard let submittedDate = formatter.date(from: feedback.date_submitted) else {
                    print("⚠️ Could not parse date for feedback #\(feedback.feedback_id): '\(feedback.date_submitted)'")
                    parseErrors += 1
                    // If we can't parse the date, INCLUDE it (safer than excluding)
                    return true
                }
                
                // Calculate time interval in seconds (positive means submittedDate is in the past)
                let timeInterval = now.timeIntervalSince(submittedDate)
                let hoursAgo = timeInterval / 3600.0
                let daysAgo = hoursAgo / 24.0
                
                // Check if the date is within the selected time range
                let isWithinRange: Bool
                
                switch currentDateFilter {
                case "Past 24 hours":
                    let hours24 = 24.0 * 3600.0
                    isWithinRange = timeInterval >= 0 && timeInterval <= hours24
                    if passedCount + failedCount < 5 {
                        print("\n  Feedback #\(feedback.feedback_id):")
                        print("    Submitted: \(submittedDate)")
                        print("    Time ago: \(String(format: "%.1f", hoursAgo)) hours (\(String(format: "%.1f", daysAgo)) days)")
                        print("    Past 24h? \(isWithinRange)")
                    }
                    
                case "Past 3 days":
                    let days3 = 3.0 * 24.0 * 3600.0
                    isWithinRange = timeInterval >= 0 && timeInterval <= days3
                    if passedCount + failedCount < 5 {
                        print("\n  Feedback #\(feedback.feedback_id):")
                        print("    Submitted: \(submittedDate)")
                        print("    Time ago: \(String(format: "%.1f", hoursAgo)) hours (\(String(format: "%.1f", daysAgo)) days)")
                        print("    Past 3d? \(isWithinRange) (need <= 72 hours)")
                    }
                    
                case "Past week":
                    let week = 7.0 * 24.0 * 3600.0
                    isWithinRange = timeInterval >= 0 && timeInterval <= week
                    if passedCount + failedCount < 5 {
                        print("\n  Feedback #\(feedback.feedback_id):")
                        print("    Submitted: \(submittedDate)")
                        print("    Time ago: \(String(format: "%.1f", hoursAgo)) hours (\(String(format: "%.1f", daysAgo)) days)")
                        print("    Past week? \(isWithinRange) (need <= 168 hours)")
                    }
                    
                case "Past month":
                    let month = 30.0 * 24.0 * 3600.0
                    isWithinRange = timeInterval >= 0 && timeInterval <= month
                    if passedCount + failedCount < 5 {
                        print("\n  Feedback #\(feedback.feedback_id):")
                        print("    Submitted: \(submittedDate)")
                        print("    Time ago: \(String(format: "%.1f", hoursAgo)) hours (\(String(format: "%.1f", daysAgo)) days)")
                        print("    Past month? \(isWithinRange) (need <= 720 hours)")
                    }
                    
                default:
                    isWithinRange = true
                }
                
                if isWithinRange {
                    passedCount += 1
                } else {
                    failedCount += 1
                }
                
                return isWithinRange
            }
            
            print("\n📊 FILTER RESULTS:")
            print("  Parse errors: \(parseErrors)")
            print("  Passed filter: \(passedCount)")
            print("  Failed filter: \(failedCount)")
            print("  Final count: \(beforeCount) → \(filteredFeedback.count)")
            print("=======================\n")
        }
        
        print("✅ Final count: \(filteredFeedback.count)")
        print("======================\n")
        
        displayFeedback(filteredFeedback)
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
        emptyLabel.text = "No feedback matches the selected filters"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .systemGray
        emptyLabel.font = .systemFont(ofSize: 16)
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(emptyLabel)
        
        emptyLabel.heightAnchor.constraint(equalToConstant: 200).isActive = true
    }
    
    func createFeedbackCard(for feedback: Feedback) {
        let cardView = UIView()
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOpacity = 0.1
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        // Left color bar
        let colorBar = UIView()
        colorBar.backgroundColor = feedback.categoryColor
        colorBar.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(colorBar)
        
        // Ticket ID
        let ticketIDLabel = UILabel()
        ticketIDLabel.text = "Ticket ID: \(feedback.feedback_id)"
        ticketIDLabel.font = .systemFont(ofSize: 16, weight: .bold)
        ticketIDLabel.textColor = .label
        ticketIDLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(ticketIDLabel)
        
        // Date
        let dateLabel = UILabel()
        dateLabel.text = feedback.formattedDate
        dateLabel.font = .systemFont(ofSize: 13)
        dateLabel.textColor = .secondaryLabel
        dateLabel.textAlignment = .right
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(dateLabel)
        
        // Description Label and Text
        let descLabel = UILabel()
        descLabel.text = "Description:"
        descLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        descLabel.textColor = .label
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(descLabel)
        
        let descText = UILabel()
        let hasValidDescription = !feedback.description.isEmpty &&
                                  feedback.description != "none" &&
                                  feedback.description != "No description provided"
        descText.text = hasValidDescription ? feedback.description : "No description provided"
        descText.font = .systemFont(ofSize: 14, weight: .regular)
        descText.textColor = hasValidDescription ? .label : .systemGray2
        descText.numberOfLines = 2
        descText.lineBreakMode = .byTruncatingTail
        descText.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(descText)
        
        // Status Icon - WITH COLOR
        let statusIcon = UIImageView()
        statusIcon.image = UIImage(systemName: "gearshape.fill")
        statusIcon.tintColor = feedback.categoryColor
        statusIcon.contentMode = .scaleAspectFit
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(statusIcon)
        
        // Status Label
        let statusLabel = UILabel()
        statusLabel.text = "Status: \(feedback.status)"
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = .label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(statusLabel)
        
        // Location Icon - WITH COLOR (BLUE)
        let locationIcon = UIImageView()
        locationIcon.image = UIImage(systemName: "info.circle.fill")
        locationIcon.tintColor = .systemBlue
        locationIcon.contentMode = .scaleAspectFit
        locationIcon.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(locationIcon)
        
        // Location Label
        let locationLabel = UILabel()
        locationLabel.text = feedback.campus ?? "Not specified"
        locationLabel.font = .systemFont(ofSize: 13)
        locationLabel.textColor = .secondaryLabel
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(locationLabel)
        
        // Technician Icon - WITH COLOR (ORANGE)
        let techIcon = UIImageView()
        techIcon.image = UIImage(systemName: "wrench.and.screwdriver.fill")
        techIcon.tintColor = .systemOrange
        techIcon.contentMode = .scaleAspectFit
        techIcon.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(techIcon)
        
        // Technician Label
        let techLabel = UILabel()
        techLabel.text = "Technician: \(feedback.user_name)"
        techLabel.font = .systemFont(ofSize: 13)
        techLabel.textColor = .label
        techLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(techLabel)
        
        // Rating stars (5 stars in a row)
        let starsStack = createStarsView(rating: feedback.safeRating)
        starsStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(starsStack)
        
        // Status text below stars
        let ratingText = UILabel()
        ratingText.text = feedback.status.lowercased()
        ratingText.font = .systemFont(ofSize: 12)
        ratingText.textColor = .systemGray
        ratingText.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(ratingText)
        
        // Status circle
        let statusCircle = UIView()
        statusCircle.backgroundColor = feedback.categoryColor
        statusCircle.layer.cornerRadius = 30
        statusCircle.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(statusCircle)
        
        let tickLabel = UILabel()
        tickLabel.text = "✓"
        tickLabel.font = .boldSystemFont(ofSize: 30)
        tickLabel.textColor = .white
        tickLabel.textAlignment = .center
        tickLabel.translatesAutoresizingMaskIntoConstraints = false
        statusCircle.addSubview(tickLabel)
        
        // Ticket image view
        let ticketImageView = UIImageView()
        ticketImageView.contentMode = .scaleAspectFill
        ticketImageView.clipsToBounds = true
        ticketImageView.layer.cornerRadius = 8
        ticketImageView.backgroundColor = .systemGray4
        ticketImageView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(ticketImageView)
        
        // Load image from Cloudinary
        loadImageForFeedback(into: ticketImageView, feedbackID: feedback.feedback_id)
        
        // Constraints
        NSLayoutConstraint.activate([
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 215),
            
            colorBar.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            colorBar.topAnchor.constraint(equalTo: cardView.topAnchor),
            colorBar.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            colorBar.widthAnchor.constraint(equalToConstant: 30),
            
            ticketIDLabel.leadingAnchor.constraint(equalTo: colorBar.trailingAnchor, constant: 16),
            ticketIDLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            
            dateLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            dateLabel.centerYAnchor.constraint(equalTo: ticketIDLabel.centerYAnchor),
            
            descLabel.leadingAnchor.constraint(equalTo: colorBar.trailingAnchor, constant: 16),
            descLabel.topAnchor.constraint(equalTo: ticketIDLabel.bottomAnchor, constant: 12),
            
            descText.leadingAnchor.constraint(equalTo: colorBar.trailingAnchor, constant: 16),
            descText.trailingAnchor.constraint(equalTo: ticketImageView.leadingAnchor, constant: -16),
            descText.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 4),
            descText.heightAnchor.constraint(greaterThanOrEqualToConstant: 28),
            
            statusIcon.leadingAnchor.constraint(equalTo: colorBar.trailingAnchor, constant: 16),
            statusIcon.topAnchor.constraint(equalTo: descText.bottomAnchor, constant: 10),
            statusIcon.widthAnchor.constraint(equalToConstant: 16),
            statusIcon.heightAnchor.constraint(equalToConstant: 16),
            
            statusLabel.leadingAnchor.constraint(equalTo: statusIcon.trailingAnchor, constant: 6),
            statusLabel.centerYAnchor.constraint(equalTo: statusIcon.centerYAnchor),
            
            locationIcon.leadingAnchor.constraint(equalTo: colorBar.trailingAnchor, constant: 16),
            locationIcon.topAnchor.constraint(equalTo: statusIcon.bottomAnchor, constant: 6),
            locationIcon.widthAnchor.constraint(equalToConstant: 16),
            locationIcon.heightAnchor.constraint(equalToConstant: 16),
            
            locationLabel.leadingAnchor.constraint(equalTo: locationIcon.trailingAnchor, constant: 6),
            locationLabel.centerYAnchor.constraint(equalTo: locationIcon.centerYAnchor),
            
            techIcon.leadingAnchor.constraint(equalTo: colorBar.trailingAnchor, constant: 16),
            techIcon.topAnchor.constraint(equalTo: locationIcon.bottomAnchor, constant: 6),
            techIcon.widthAnchor.constraint(equalToConstant: 16),
            techIcon.heightAnchor.constraint(equalToConstant: 16),
            
            techLabel.leadingAnchor.constraint(equalTo: techIcon.trailingAnchor, constant: 6),
            techLabel.centerYAnchor.constraint(equalTo: techIcon.centerYAnchor),
            
            starsStack.leadingAnchor.constraint(equalTo: colorBar.trailingAnchor, constant: 16),
            starsStack.topAnchor.constraint(equalTo: techIcon.bottomAnchor, constant: 10),
            starsStack.heightAnchor.constraint(equalToConstant: 20),
            
            ratingText.leadingAnchor.constraint(equalTo: colorBar.trailingAnchor, constant: 16),
            ratingText.topAnchor.constraint(equalTo: starsStack.bottomAnchor, constant: 2),
            ratingText.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -12),
            
            statusCircle.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            statusCircle.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            statusCircle.widthAnchor.constraint(equalToConstant: 60),
            statusCircle.heightAnchor.constraint(equalToConstant: 60),
            
            tickLabel.centerXAnchor.constraint(equalTo: statusCircle.centerXAnchor),
            tickLabel.centerYAnchor.constraint(equalTo: statusCircle.centerYAnchor),
            
            ticketImageView.trailingAnchor.constraint(equalTo: statusCircle.leadingAnchor, constant: -12),
            ticketImageView.centerYAnchor.constraint(equalTo: statusCircle.centerYAnchor),
            ticketImageView.widthAnchor.constraint(equalToConstant: 60),
            ticketImageView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // Tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(feedbackCardTapped(_:)))
        cardView.tag = feedback.feedback_id
        cardView.addGestureRecognizer(tap)
        cardView.isUserInteractionEnabled = true
        
        stackView.addArrangedSubview(cardView)
    }
    
    func createStarsView(rating: Int) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.distribution = .fillEqually
        
        for i in 1...5 {
            let star = UILabel()
            star.text = "★"
            star.font = .systemFont(ofSize: 16)
            star.textColor = i <= rating ? .systemYellow : .systemGray4
            stack.addArrangedSubview(star)
        }
        
        return stack
    }
    
    @objc func feedbackCardTapped(_ sender: UITapGestureRecognizer) {
        print("🔘 Card tapped!")
        print("   Gesture view tag: \(sender.view?.tag ?? -1)")
        
        guard let feedbackID = sender.view?.tag,
              let feedback = feedbackArray.first(where: { $0.feedback_id == feedbackID }) else {
            print("❌ Could not find feedback with ID: \(sender.view?.tag ?? -1)")
            return
        }
        
        print("✅ Found feedback: ID \(feedback.feedback_id)")
        
        // Create detail view controller programmatically
        let detailVC = FeedbackDetailViewController()
        detailVC.feedback = feedback
        
        if let navigationController = navigationController {
            print("✅ Pushing to navigation controller")
            navigationController.pushViewController(detailVC, animated: true)
        } else {
            print("❌ No navigation controller - presenting modally")
            present(detailVC, animated: true)
        }
    }
    
    func loadImageForFeedback(into imageView: UIImageView, feedbackID: Int) {
        // Array of default images to select from (same as normal tickets)
        let defaultImageURLs = [
            "https://wlefukllkrvgpjelkxav.supabase.co/storage/v1/object/public/images/Copilot_20251225_111257.png",
            "https://wlefukllkrvgpjelkxav.supabase.co/storage/v1/object/public/images/Copilot_20251225_112235.png",
            "https://wlefukllkrvgpjelkxav.supabase.co/storage/v1/object/public/images/Copilot_20251225_112136.png"
        ]
        
        // Use feedback ID to rotate through images
        let imageIndex = feedbackID % defaultImageURLs.count
        let selectedImageURL = defaultImageURLs[imageIndex]
        
        loadRemoteImage(from: selectedImageURL, into: imageView)
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
    
    // MARK: - Notification Methods
    
    /// Shows a notification for newly submitted feedback
    /// - Parameter feedback: The new feedback that was submitted
    func showNewFeedbackNotification(feedback: Feedback) {
        // Dismiss any existing notification first
        if let existing = currentNotificationView {
            dismissNotification(existing, animated: false)
        }
        
        // Create notification view
        let notificationView = createFeedbackNotificationView(for: feedback)
        notificationView.alpha = 0
        notificationView.transform = CGAffineTransform(translationX: 0, y: -100)
        
        view.addSubview(notificationView)
        currentNotificationView = notificationView
        
        // Position it at the top (below safe area)
        notificationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            notificationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            notificationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            notificationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            notificationView.heightAnchor.constraint(greaterThanOrEqualToConstant: 70)
        ])
        
        // Force layout
        view.layoutIfNeeded()
        
        // Animate in with slide down + fade
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            notificationView.alpha = 1
            notificationView.transform = .identity
        }
        
        // Add haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Auto-dismiss after 3.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            self?.dismissNotification(notificationView, animated: true)
        }
        
        print("🔔 Notification shown for feedback #\(feedback.feedback_id)")
    }
    
    /// Creates the notification view for feedback
    /// - Parameter feedback: The feedback to display information about
    /// - Returns: Configured notification view
    func createFeedbackNotificationView(for feedback: Feedback) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Main notification card with gradient
        let notificationCard = UIView()
        notificationCard.translatesAutoresizingMaskIntoConstraints = false
        
        // Create gradient layer (green/teal gradient for feedback)
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1).cgColor,  // Green
            UIColor(red: 48/255, green: 176/255, blue: 199/255, alpha: 1).cgColor  // Teal
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 16
        notificationCard.layer.insertSublayer(gradientLayer, at: 0)
        
        // Shadow
        notificationCard.layer.shadowColor = UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 0.4).cgColor
        notificationCard.layer.shadowOffset = CGSize(width: 0, height: 8)
        notificationCard.layer.shadowRadius = 24
        notificationCard.layer.shadowOpacity = 1
        notificationCard.layer.cornerRadius = 16
        
        containerView.addSubview(notificationCard)
        
        // Icon container
        let iconContainer = UIView()
        iconContainer.backgroundColor = UIColor(white: 1, alpha: 0.2)
        iconContainer.layer.cornerRadius = 12
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        notificationCard.addSubview(iconContainer)
        
        // Icon - SF Symbol chat bubble
        let iconImageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        iconImageView.image = UIImage(systemName: "bubble.left.fill", withConfiguration: config)
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconImageView)
        
        // Content stack
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 4
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        notificationCard.addSubview(contentStack)
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.text = "New Feedback Submitted"
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white
        contentStack.addArrangedSubview(titleLabel)
        
        // Message label with rating stars
        let messageLabel = UILabel()
        let stars = String(repeating: "⭐", count: feedback.rating)
        messageLabel.text = "Feedback #\(feedback.feedback_id) - \(stars) by \(feedback.user_name)"
        messageLabel.font = .systemFont(ofSize: 13, weight: .regular)
        messageLabel.textColor = UIColor(white: 1, alpha: 0.9)
        messageLabel.numberOfLines = 2
        contentStack.addArrangedSubview(messageLabel)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            notificationCard.topAnchor.constraint(equalTo: containerView.topAnchor),
            notificationCard.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            notificationCard.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            notificationCard.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            iconContainer.leadingAnchor.constraint(equalTo: notificationCard.leadingAnchor, constant: 20),
            iconContainer.centerYAnchor.constraint(equalTo: notificationCard.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            contentStack.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 15),
            contentStack.trailingAnchor.constraint(equalTo: notificationCard.trailingAnchor, constant: -20),
            contentStack.topAnchor.constraint(equalTo: notificationCard.topAnchor, constant: 20),
            contentStack.bottomAnchor.constraint(equalTo: notificationCard.bottomAnchor, constant: -20)
        ])
        
        // Update gradient frame when layout changes
        DispatchQueue.main.async {
            gradientLayer.frame = notificationCard.bounds
        }
        
        // Add tap gesture to dismiss or view feedback
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(feedbackNotificationTapped(_:)))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
        containerView.tag = feedback.feedback_id  // Store feedback ID in tag
        
        return containerView
    }
    
    /// Dismisses the notification with animation
    /// - Parameters:
    ///   - notification: The notification view to dismiss
    ///   - animated: Whether to animate the dismissal
    func dismissNotification(_ notification: UIView, animated: Bool) {
        guard notification.superview != nil else { return }
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                notification.alpha = 0
                notification.transform = CGAffineTransform(translationX: 0, y: -100)
            }) { _ in
                notification.removeFromSuperview()
                if self.currentNotificationView == notification {
                    self.currentNotificationView = nil
                }
            }
        } else {
            notification.removeFromSuperview()
            if currentNotificationView == notification {
                currentNotificationView = nil
            }
        }
    }
    
    /// Handles tap on notification - opens the feedback
    @objc func feedbackNotificationTapped(_ sender: UITapGestureRecognizer) {
        guard let notificationView = sender.view,
              let feedbackID = notificationView.tag as Int?,
              let feedback = feedbackArray.first(where: { $0.feedback_id == feedbackID }) else {
            // Just dismiss if we can't find the feedback
            if let view = sender.view {
                dismissNotification(view, animated: true)
            }
            return
        }
        
        // Dismiss notification
        dismissNotification(notificationView, animated: true)
        
        // Open feedback details
        let detailVC = FeedbackDetailViewController()
        detailVC.feedback = feedback
        
        if let navigationController = navigationController {
            navigationController.pushViewController(detailVC, animated: true)
        } else {
            present(detailVC, animated: true)
        }
        
        print("📱 Opened feedback #\(feedbackID) from notification")
    }
}
