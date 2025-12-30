//
//  FeedbackViewList.swift
//  Ticket-style feedback list with technician and date filters
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
        
        // Date filter chip - Using modern UIButton.Configuration with icon
        var dateConfig = UIButton.Configuration.plain()
        dateConfig.title = "📅 Past 3 days ⌄"
        dateConfig.baseForegroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1)
        dateConfig.background.backgroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 0.1)
        dateConfig.background.cornerRadius = 20
        dateConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        dateConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        
        dateFilterButton.configuration = dateConfig
        dateFilterButton.translatesAutoresizingMaskIntoConstraints = false
        dateFilterButton.addTarget(self, action: #selector(dateFilterTapped), for: .touchUpInside)
        filterChipsContainer.addSubview(dateFilterButton)
        
        // Technician filter chip - Using modern UIButton.Configuration with icon
        var techConfig = UIButton.Configuration.plain()
        techConfig.title = "👥 All Technicians ⌄"
        techConfig.baseForegroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1)
        techConfig.background.backgroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 0.1)
        techConfig.background.cornerRadius = 20
        techConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        techConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .medium)
            return outgoing
        }
        
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
            
            technicianFilterButton.leadingAnchor.constraint(equalTo: dateFilterButton.trailingAnchor, constant: 12),
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
    
    @objc func dateFilterTapped() {
        let alert = UIAlertController(title: "Filter by Date", message: nil, preferredStyle: .actionSheet)
        
        let dateOptions = ["All Time", "Past 24 hours", "Past 3 days", "Past week", "Past month"]
        
        for option in dateOptions {
            alert.addAction(UIAlertAction(title: option, style: .default) { [weak self] _ in
                self?.currentDateFilter = option
                self?.dateFilterButton.configuration?.title = "📅 \(option) ⌄"
                self?.applyCurrentFilters()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc func technicianFilterTapped() {
        let alert = UIAlertController(title: "Filter by Technician", message: nil, preferredStyle: .actionSheet)
        
        let technicians = Set(feedbackArray.map { $0.user_name })
        
        alert.addAction(UIAlertAction(title: "All Technicians", style: .default) { [weak self] _ in
            self?.currentTechnicianFilter = nil
            self?.technicianFilterButton.configuration?.title = "👥 All Technicians ⌄"
            self?.applyCurrentFilters()
        })
        
        for technician in technicians.sorted() {
            alert.addAction(UIAlertAction(title: technician, style: .default) { [weak self] _ in
                self?.currentTechnicianFilter = technician
                self?.technicianFilterButton.configuration?.title = "👥 \(technician) ⌄"
                self?.applyCurrentFilters()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Fetch Feedback from Firebase
    func fetchFeedback() {
        print("🔍 Fetching from 'Feedback' collection...")
        
        db.collection("Feedback").order(by: "date_submitted", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
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
                do {
                    let feedback = try doc.data(as: Feedback.self)
                    feedbacks.append(feedback)
                    print("✅ Decoded feedback ID: \(feedback.feedback_id)")
                } catch {
                    print("❌ DECODING ERROR for \(doc.documentID): \(error)")
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
    func applyCurrentFilters() {
        filteredFeedback = feedbackArray
        
        // Filter by date
        if currentDateFilter != "All Time" {
            let now = Date()
            let calendar = Calendar.current
            
            filteredFeedback = filteredFeedback.filter { feedback in
                let formatter = ISO8601DateFormatter()
                guard let submittedDate = formatter.date(from: feedback.date_submitted) else {
                    return false
                }
                
                switch currentDateFilter {
                case "Past 24 hours":
                    return calendar.dateComponents([.hour], from: submittedDate, to: now).hour ?? 0 <= 24
                case "Past 3 days":
                    return calendar.dateComponents([.day], from: submittedDate, to: now).day ?? 0 <= 3
                case "Past week":
                    return calendar.dateComponents([.day], from: submittedDate, to: now).day ?? 0 <= 7
                case "Past month":
                    return calendar.dateComponents([.day], from: submittedDate, to: now).day ?? 0 <= 30
                default:
                    return true
                }
            }
        }
        
        // Filter by technician
        if let technician = currentTechnicianFilter {
            filteredFeedback = filteredFeedback.filter {
                $0.user_name.lowercased() == technician.lowercased()
            }
        }
        
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
        let emptyContainer = UIView()
        emptyContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let iconLabel = UILabel()
        iconLabel.text = "📋"
        iconLabel.font = .systemFont(ofSize: 60)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let emptyLabel = UILabel()
        emptyLabel.text = "No feedback to display"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .systemGray
        emptyLabel.font = .systemFont(ofSize: 18, weight: .medium)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        emptyContainer.addSubview(iconLabel)
        emptyContainer.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: emptyContainer.centerXAnchor),
            iconLabel.topAnchor.constraint(equalTo: emptyContainer.topAnchor, constant: 60),
            
            emptyLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 20),
            emptyLabel.centerXAnchor.constraint(equalTo: emptyContainer.centerXAnchor),
            emptyLabel.bottomAnchor.constraint(equalTo: emptyContainer.bottomAnchor, constant: -60)
        ])
        
        stackView.addArrangedSubview(emptyContainer)
    }
    
    // MARK: - Create Ticket-Style Feedback Card (CONCEPT 1: Modern Card)
    func createFeedbackCard(for feedback: Feedback) {
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.12
        containerView.layer.shadowRadius = 10
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true
        
        containerView.tag = feedback.feedback_id
        let tap = UITapGestureRecognizer(target: self, action: #selector(feedbackTapped(_:)))
        containerView.addGestureRecognizer(tap)
        containerView.isUserInteractionEnabled = true
        
        // Left colored border - EXTRA THICK (24px)
        let leftBorder = UIView()
        leftBorder.backgroundColor = feedback.categoryColor
        leftBorder.layer.cornerRadius = 12
        leftBorder.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        leftBorder.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(leftBorder)
        
        // HEADER SECTION with divider
        // Ticket number (#50 format)
        let ticketNumberLabel = UILabel()
        ticketNumberLabel.text = "#\(feedback.feedback_id)"
        ticketNumberLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        ticketNumberLabel.textColor = .label
        ticketNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(ticketNumberLabel)
        
        // Date label
        let dateLabel = UILabel()
        dateLabel.text = feedback.formattedDate
        dateLabel.font = .systemFont(ofSize: 13)
        dateLabel.textColor = .secondaryLabel
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dateLabel)
        
        // Priority badge
        let priorityBadge = UIView()
        priorityBadge.backgroundColor = .systemRed
        priorityBadge.layer.cornerRadius = 12
        priorityBadge.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(priorityBadge)
        
        let priorityLabel = UILabel()
        priorityLabel.text = "HIGH"
        priorityLabel.font = .systemFont(ofSize: 11, weight: .bold)
        priorityLabel.textColor = .white
        priorityLabel.translatesAutoresizingMaskIntoConstraints = false
        priorityBadge.addSubview(priorityLabel)
        
        // Divider line
        let dividerLine = UIView()
        dividerLine.backgroundColor = UIColor.systemGray5
        dividerLine.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dividerLine)
        
        // MAIN CONTENT
        // Bigger title
        let titleLabel = UILabel()
        titleLabel.text = feedback.title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Description preview (2 lines)
        let descriptionLabel = UILabel()
        descriptionLabel.text = feedback.description
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 2
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(descriptionLabel)
        
        // INFO PILLS SECTION
        let pillsStack = UIStackView()
        pillsStack.axis = .horizontal
        pillsStack.spacing = 8
        pillsStack.distribution = .fill
        pillsStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(pillsStack)
        
        // Status pill
        let statusPill = createPill(icon: "●", text: feedback.status, color: feedback.statusColor, bgColor: feedback.statusColor.withAlphaComponent(0.15))
        pillsStack.addArrangedSubview(statusPill)
        
        // Campus pill
        let campusPill = createPill(icon: "📍", text: feedback.campus ?? "Not specified", color: .systemRed, bgColor: UIColor.systemRed.withAlphaComponent(0.15))
        pillsStack.addArrangedSubview(campusPill)
        
        // Time pill
        let timeAgo = getTimeAgo(from: feedback.date_submitted)
        let timePill = createPill(icon: "⏱", text: timeAgo, color: .systemGray, bgColor: UIColor.systemGray6)
        pillsStack.addArrangedSubview(timePill)
        
        // FOOTER SECTION
        // Technician name
        let techLabel = UILabel()
        techLabel.text = "👤 \(feedback.user_name)"
        techLabel.font = .systemFont(ofSize: 13)
        techLabel.textColor = .label
        techLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(techLabel)
        
        // Rating with number
        let ratingStack = UIStackView()
        ratingStack.axis = .horizontal
        ratingStack.spacing = 4
        ratingStack.alignment = .center
        ratingStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(ratingStack)
        
        // Star icons
        for i in 1...5 {
            let starImageView = UIImageView()
            starImageView.contentMode = .scaleAspectFit
            starImageView.tintColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1)
            
            if i <= feedback.safeRating {
                starImageView.image = UIImage(systemName: "star.fill")
            } else {
                starImageView.image = UIImage(systemName: "star")
                starImageView.tintColor = UIColor.systemGray3
            }
            
            starImageView.translatesAutoresizingMaskIntoConstraints = false
            starImageView.widthAnchor.constraint(equalToConstant: 14).isActive = true
            starImageView.heightAnchor.constraint(equalToConstant: 14).isActive = true
            
            ratingStack.addArrangedSubview(starImageView)
        }
        
        // Rating number
        let ratingNumber = UILabel()
        ratingNumber.text = String(format: "%.1f", Double(feedback.safeRating))
        ratingNumber.font = .systemFont(ofSize: 13)
        ratingNumber.textColor = .secondaryLabel
        ratingNumber.translatesAutoresizingMaskIntoConstraints = false
        ratingStack.addArrangedSubview(ratingNumber)
        
        // CONSTRAINTS
        NSLayoutConstraint.activate([
            // Left border
            leftBorder.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            leftBorder.topAnchor.constraint(equalTo: containerView.topAnchor),
            leftBorder.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            leftBorder.widthAnchor.constraint(equalToConstant: 24),
            
            // Header section
            ticketNumberLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            ticketNumberLabel.leadingAnchor.constraint(equalTo: leftBorder.trailingAnchor, constant: 16),
            
            dateLabel.centerYAnchor.constraint(equalTo: ticketNumberLabel.centerYAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: priorityBadge.leadingAnchor, constant: -12),
            
            priorityBadge.centerYAnchor.constraint(equalTo: ticketNumberLabel.centerYAnchor),
            priorityBadge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            priorityBadge.heightAnchor.constraint(equalToConstant: 24),
            
            priorityLabel.centerXAnchor.constraint(equalTo: priorityBadge.centerXAnchor),
            priorityLabel.centerYAnchor.constraint(equalTo: priorityBadge.centerYAnchor),
            priorityLabel.leadingAnchor.constraint(equalTo: priorityBadge.leadingAnchor, constant: 12),
            priorityLabel.trailingAnchor.constraint(equalTo: priorityBadge.trailingAnchor, constant: -12),
            
            // Divider line
            dividerLine.topAnchor.constraint(equalTo: ticketNumberLabel.bottomAnchor, constant: 12),
            dividerLine.leadingAnchor.constraint(equalTo: leftBorder.trailingAnchor, constant: 16),
            dividerLine.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            dividerLine.heightAnchor.constraint(equalToConstant: 1),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: dividerLine.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leftBorder.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Description
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: leftBorder.trailingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Pills
            pillsStack.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            pillsStack.leadingAnchor.constraint(equalTo: leftBorder.trailingAnchor, constant: 16),
            pillsStack.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),
            
            // Footer
            techLabel.topAnchor.constraint(equalTo: pillsStack.bottomAnchor, constant: 16),
            techLabel.leadingAnchor.constraint(equalTo: leftBorder.trailingAnchor, constant: 16),
            techLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            
            ratingStack.centerYAnchor.constraint(equalTo: techLabel.centerYAnchor),
            ratingStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
        
        stackView.addArrangedSubview(containerView)
    }
    
    // Helper: Create info pill
    func createPill(icon: String, text: String, color: UIColor, bgColor: UIColor) -> UIView {
        let pill = UIView()
        pill.backgroundColor = bgColor
        pill.layer.cornerRadius = 12
        pill.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "\(icon) \(text)"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = color
        label.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: pill.topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -6),
            label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -12),
            pill.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        return pill
    }
    
    // Helper: Calculate time ago
    func getTimeAgo(from dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return "Unknown"
        }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 min ago" : "\(minutes) mins ago"
        } else {
            return "Just now"
        }
    }
    
    // MARK: - Navigation
    @objc func feedbackTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view,
              let feedback = feedbackArray.first(where: { $0.feedback_id == view.tag }) else { return }
        
        let detailVC = FeedbackDetailViewController()
        detailVC.feedback = feedback
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // MARK: - Helper Methods
    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
