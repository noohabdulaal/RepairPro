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
        dateConfig.title = "Past 3 days"
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
            
            for doc in snapshot.documents {
                do {
                    let feedback = try doc.data(as: Feedback.self)
                    feedbacks.append(feedback)
                    print("  ✓ Feedback \(feedback.feedback_id): \(feedback.user_name)")
                } catch {
                    print("  ✗ Error decoding: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.feedbackArray = feedbacks
                print("📊 Total feedbacks: \(feedbacks.count)")
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
            let calendar = Calendar.current
            let beforeCount = filteredFeedback.count
            
            filteredFeedback = filteredFeedback.filter { feedback in
                let formatter = ISO8601DateFormatter()
                guard let submittedDate = formatter.date(from: feedback.date_submitted) else {
                    return false
                }
                
                let daysDiff = calendar.dateComponents([.day], from: submittedDate, to: now).day ?? 0
                
                switch currentDateFilter {
                case "Past 24 hours":
                    return calendar.dateComponents([.hour], from: submittedDate, to: now).hour ?? 0 <= 24
                case "Past 3 days":
                    return daysDiff <= 3
                case "Past week":
                    return daysDiff <= 7
                case "Past month":
                    return daysDiff <= 30
                default:
                    return true
                }
            }
            
            print("📅 After date filter: \(beforeCount) → \(filteredFeedback.count)")
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
        
        // Description Label and Text - REDESIGNED
        let descLabel = UILabel()
        descLabel.text = "Description:"
        descLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        descLabel.textColor = .label
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(descLabel)
        
        let descText = UILabel()
        // Check if description is empty or "none" or "No description provided"
        let hasValidDescription = !feedback.description.isEmpty &&
                                  feedback.description != "none" &&
                                  feedback.description != "No description provided"
        descText.text = hasValidDescription ? feedback.description : "No description provided"
        descText.font = .systemFont(ofSize: 14, weight: .regular)  // Slightly larger font
        descText.textColor = hasValidDescription ? .label : .systemGray2  // Darker for visibility
        descText.numberOfLines = 2  // Changed from 3 to 2 lines
        descText.lineBreakMode = .byTruncatingTail
        descText.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(descText)
        
        // Status Icon
        let statusIcon = UIImageView()
        statusIcon.image = UIImage(systemName: "gearshape.fill")
        statusIcon.tintColor = feedback.statusColor
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
        
        // Location Icon
        let locationIcon = UIImageView()
        locationIcon.image = UIImage(systemName: "info.circle")
        locationIcon.tintColor = .systemGray
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
        
        // Technician Icon
        let techIcon = UIImageView()
        techIcon.image = UIImage(systemName: "wrench.and.screwdriver")
        techIcon.tintColor = .systemGray
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
        
        let exclamation = UILabel()
        exclamation.text = "!"
        exclamation.font = .boldSystemFont(ofSize: 32)
        exclamation.textColor = .white
        exclamation.textAlignment = .center
        exclamation.translatesAutoresizingMaskIntoConstraints = false
        statusCircle.addSubview(exclamation)
        
        // Constraints
        NSLayoutConstraint.activate([
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 215),  // Reduced from 240
            
            colorBar.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            colorBar.topAnchor.constraint(equalTo: cardView.topAnchor),
            colorBar.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            colorBar.widthAnchor.constraint(equalToConstant: 20),
            
            ticketIDLabel.leadingAnchor.constraint(equalTo: colorBar.trailingAnchor, constant: 16),
            ticketIDLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            
            dateLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            dateLabel.centerYAnchor.constraint(equalTo: ticketIDLabel.centerYAnchor),
            
            descLabel.leadingAnchor.constraint(equalTo: colorBar.trailingAnchor, constant: 16),
            descLabel.topAnchor.constraint(equalTo: ticketIDLabel.bottomAnchor, constant: 12),
            
            descText.leadingAnchor.constraint(equalTo: colorBar.trailingAnchor, constant: 16),
            descText.trailingAnchor.constraint(equalTo: statusCircle.leadingAnchor, constant: -16),
            descText.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 4),
            descText.heightAnchor.constraint(greaterThanOrEqualToConstant: 28),  // Reduced from 40 to 28
            
            statusIcon.leadingAnchor.constraint(equalTo: colorBar.trailingAnchor, constant: 16),
            statusIcon.topAnchor.constraint(equalTo: descText.bottomAnchor, constant: 10),  // Reduced from 16 to 10
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
            
            exclamation.centerXAnchor.constraint(equalTo: statusCircle.centerXAnchor),
            exclamation.centerYAnchor.constraint(equalTo: statusCircle.centerYAnchor)
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
    
    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
