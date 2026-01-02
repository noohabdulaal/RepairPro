//
//  FeedbackViewList.swift
//  Ticket-style feedback list with technician and date filters
//  ENHANCED VERSION - Smaller cards, modern filter chips
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
        
        // Date filter chip - Modern design without emoji
        var dateConfig = UIButton.Configuration.filled()
        dateConfig.title = "Past 3 days"
        dateConfig.baseForegroundColor = .white
        dateConfig.baseBackgroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1)
        dateConfig.cornerStyle = .capsule
        dateConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        dateConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .semibold)
            return outgoing
        }
        
        // Add chevron down icon
        dateConfig.image = UIImage(systemName: "chevron.down")
        dateConfig.imagePlacement = .trailing
        dateConfig.imagePadding = 6
        
        dateFilterButton.configuration = dateConfig
        dateFilterButton.translatesAutoresizingMaskIntoConstraints = false
        dateFilterButton.addTarget(self, action: #selector(dateFilterTapped), for: .touchUpInside)
        filterChipsContainer.addSubview(dateFilterButton)
        
        // Technician filter chip - Modern design without emoji
        var techConfig = UIButton.Configuration.filled()
        techConfig.title = "All Technicians"
        techConfig.baseForegroundColor = .white
        techConfig.baseBackgroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1)
        techConfig.cornerStyle = .capsule
        techConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        techConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .semibold)
            return outgoing
        }
        
        // Add chevron down icon
        techConfig.image = UIImage(systemName: "chevron.down")
        techConfig.imagePlacement = .trailing
        techConfig.imagePadding = 6
        
        technicianFilterButton.configuration = techConfig
        technicianFilterButton.translatesAutoresizingMaskIntoConstraints = false
        technicianFilterButton.addTarget(self, action: #selector(technicianFilterTapped), for: .touchUpInside)
        filterChipsContainer.addSubview(technicianFilterButton)
        
        NSLayoutConstraint.activate([
            filterChipsContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
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
        stackView.spacing = 12  // Reduced from 16
        stackView.alignment = .fill
        stackView.distribution = .fill
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 12),  // Reduced from 16
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -12),  // Reduced from -16
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    @objc func dateFilterTapped() {
        let alert = UIAlertController(title: "Filter by Date", message: nil, preferredStyle: .actionSheet)
        
        let dateOptions = ["All Time", "Past 24 hours", "Past 3 days", "Past week", "Past month"]
        
        for option in dateOptions {
            alert.addAction(UIAlertAction(title: option, style: .default) { [weak self] _ in
                self?.currentDateFilter = option
                self?.dateFilterButton.configuration?.title = option
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
            self?.technicianFilterButton.configuration?.title = "All Technicians"
            self?.applyCurrentFilters()
        })
        
        for technician in technicians.sorted() {
            alert.addAction(UIAlertAction(title: technician, style: .default) { [weak self] _ in
                self?.currentTechnicianFilter = technician
                self?.technicianFilterButton.configuration?.title = technician
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
                print("📄 Processing document: \(doc.documentID)")
                print("📄 Document data: \(doc.data())")
                
                do {
                    let feedback = try doc.data(as: Feedback.self)
                    feedbacks.append(feedback)
                    print("✅ Successfully decoded feedback ID: \(feedback.feedback_id), Title: \(feedback.title)")
                } catch {
                    print("❌ DECODING ERROR for \(doc.documentID): \(error)")
                    print("❌ Error details: \(error.localizedDescription)")
                }
            }
            
            print("📊 Total feedbacks decoded: \(feedbacks.count)")
            
            DispatchQueue.main.async {
                self.feedbackArray = feedbacks
                print("📊 feedbackArray count: \(self.feedbackArray.count)")
                self.applyCurrentFilters()
            }
        }
    }
    
    // MARK: - Filtering
    func applyCurrentFilters() {
        print("🔍 Applying filters...")
        print("🔍 Starting with \(feedbackArray.count) feedbacks")
        print("🔍 Current date filter: \(currentDateFilter)")
        print("🔍 Current technician filter: \(currentTechnicianFilter ?? "None")")
        
        filteredFeedback = feedbackArray
        
        // Filter by date
        if currentDateFilter != "All Time" {
            let now = Date()
            let calendar = Calendar.current
            let beforeCount = filteredFeedback.count
            
            filteredFeedback = filteredFeedback.filter { feedback in
                let formatter = ISO8601DateFormatter()
                guard let submittedDate = formatter.date(from: feedback.date_submitted) else {
                    print("⚠️ Could not parse date for feedback \(feedback.feedback_id): \(feedback.date_submitted)")
                    return false
                }
                
                let daysDiff = calendar.dateComponents([.day], from: submittedDate, to: now).day ?? 0
                print("📅 Feedback \(feedback.feedback_id) date: \(feedback.date_submitted), Days ago: \(daysDiff)")
                
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
            
            print("🔍 After date filter: \(beforeCount) → \(filteredFeedback.count)")
        }
        
        // Filter by technician
        if let technician = currentTechnicianFilter {
            let beforeCount = filteredFeedback.count
            filteredFeedback = filteredFeedback.filter {
                $0.user_name.lowercased() == technician.lowercased()
            }
            print("🔍 After technician filter: \(beforeCount) → \(filteredFeedback.count)")
        }
        
        print("✅ Final filtered count: \(filteredFeedback.count)")
        displayFeedback(filteredFeedback)
    }
    
    func displayFeedback(_ feedbacks: [Feedback]) {
        print("🎨 Displaying \(feedbacks.count) feedback cards")
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if feedbacks.isEmpty {
            showEmptyState()
        } else {
            feedbacks.forEach {
                print("🎨 Creating card for feedback ID: \($0.feedback_id)")
                createFeedbackCard(for: $0)
            }
        }
    }
    
    func showEmptyState() {
        let emptyContainer = UIView()
        emptyContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let iconLabel = UILabel()
        iconLabel.text = "📋"
        iconLabel.font = .systemFont(ofSize: 50)  // Reduced from 60
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let emptyLabel = UILabel()
        emptyLabel.text = "No feedback to display"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .systemGray
        emptyLabel.font = .systemFont(ofSize: 16, weight: .medium)  // Reduced from 18
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        emptyContainer.addSubview(iconLabel)
        emptyContainer.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: emptyContainer.centerXAnchor),
            iconLabel.topAnchor.constraint(equalTo: emptyContainer.topAnchor, constant: 50),  // Reduced from 60
            
            emptyLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 16),
            emptyLabel.centerXAnchor.constraint(equalTo: emptyContainer.centerXAnchor),
            emptyLabel.bottomAnchor.constraint(equalTo: emptyContainer.bottomAnchor, constant: -50)  // Reduced from -60
        ])
        
        stackView.addArrangedSubview(emptyContainer)
    }
    
    // MARK: - Create Feedback Card (SMALLER SIZE)
    func createFeedbackCard(for feedback: Feedback) {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 12  // Reduced from 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.08
        containerView.layer.shadowRadius = 6  // Reduced from 8
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.tag = feedback.feedback_id
        let tap = UITapGestureRecognizer(target: self, action: #selector(feedbackTapped(_:)))
        containerView.addGestureRecognizer(tap)
        containerView.isUserInteractionEnabled = true
        
        // Left colored stripe
        let leftStripe = UIView()
        leftStripe.backgroundColor = feedback.categoryColor
        leftStripe.layer.cornerRadius = 12  // Reduced from 16
        leftStripe.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        leftStripe.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(leftStripe)
        
        // Content container
        let contentContainer = UIView()
        contentContainer.backgroundColor = .white
        contentContainer.layer.cornerRadius = 10  // Reduced from 12
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentContainer)
        
        // Ticket ID
        let ticketIDLabel = UILabel()
        ticketIDLabel.text = "Ticket ID: \(feedback.feedback_id)"
        ticketIDLabel.font = .systemFont(ofSize: 16, weight: .bold)  // Reduced from 18
        ticketIDLabel.textColor = .label
        ticketIDLabel.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(ticketIDLabel)
        
        // Date
        let dateLabel = UILabel()
        dateLabel.text = feedback.formattedDate
        dateLabel.font = .systemFont(ofSize: 13)  // Reduced from 15
        dateLabel.textColor = .label
        dateLabel.textAlignment = .right
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(dateLabel)
        
        // Description label
        let descLabel = UILabel()
        descLabel.text = "Description:"
        descLabel.font = .systemFont(ofSize: 13, weight: .bold)  // Reduced from 15
        descLabel.textColor = .label
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(descLabel)
        
        // Description text
        let descText = UILabel()
        descText.text = feedback.description
        descText.font = .systemFont(ofSize: 13)  // Reduced from 15
        descText.textColor = .label
        descText.numberOfLines = 2  // Limit to 2 lines to keep card smaller
        descText.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(descText)
        
        // Status row
        let statusStack = UIStackView()
        statusStack.axis = .horizontal
        statusStack.spacing = 6  // Reduced from 8
        statusStack.alignment = .center
        statusStack.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(statusStack)
        
        let statusIcon = UIImageView(image: UIImage(systemName: "gearshape"))
        statusIcon.tintColor = .label
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        statusIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true  // Reduced from 18
        statusIcon.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        let statusLabel = UILabel()
        statusLabel.text = "Status: \(feedback.status)"
        statusLabel.font = .systemFont(ofSize: 13)  // Reduced from 15
        statusLabel.textColor = .label
        
        statusStack.addArrangedSubview(statusIcon)
        statusStack.addArrangedSubview(statusLabel)
        
        // Campus row
        let campusStack = UIStackView()
        campusStack.axis = .horizontal
        campusStack.spacing = 6  // Reduced from 8
        campusStack.alignment = .center
        campusStack.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(campusStack)
        
        let campusIcon = UIImageView(image: UIImage(systemName: "mappin.circle"))
        campusIcon.tintColor = .label
        campusIcon.translatesAutoresizingMaskIntoConstraints = false
        campusIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true  // Reduced from 18
        campusIcon.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        let campusLabel = UILabel()
        campusLabel.text = feedback.campus ?? "Not specified"
        campusLabel.font = .systemFont(ofSize: 13)  // Reduced from 15
        campusLabel.textColor = .label
        
        campusStack.addArrangedSubview(campusIcon)
        campusStack.addArrangedSubview(campusLabel)
        
        // Technician row
        let techStack = UIStackView()
        techStack.axis = .horizontal
        techStack.spacing = 6  // Reduced from 8
        techStack.alignment = .center
        techStack.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(techStack)
        
        let techIcon = UIImageView(image: UIImage(systemName: "wrench.and.screwdriver"))
        techIcon.tintColor = .label
        techIcon.translatesAutoresizingMaskIntoConstraints = false
        techIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true  // Reduced from 18
        techIcon.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        let techLabel = UILabel()
        techLabel.text = "Technician: \(feedback.user_name)"
        techLabel.font = .systemFont(ofSize: 13)  // Reduced from 15
        techLabel.textColor = .label
        
        techStack.addArrangedSubview(techIcon)
        techStack.addArrangedSubview(techLabel)
        
        // Star rating
        let starStack = UIStackView()
        starStack.axis = .horizontal
        starStack.spacing = 3  // Reduced from 4
        starStack.alignment = .center
        starStack.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(starStack)
        
        for i in 1...5 {
            let starImageView = UIImageView()
            starImageView.contentMode = .scaleAspectFit
            starImageView.tintColor = UIColor(red: 255/255, green: 193/255, blue: 7/255, alpha: 1)
            
            if i <= feedback.safeRating {
                starImageView.image = UIImage(systemName: "star.fill")
            } else {
                starImageView.image = UIImage(systemName: "star")
                starImageView.tintColor = UIColor.systemGray4
            }
            
            starImageView.translatesAutoresizingMaskIntoConstraints = false
            starImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true  // Reduced from 24
            starImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
            
            starStack.addArrangedSubview(starImageView)
        }
        
        // Comment
        let commentLabel = UILabel()
        commentLabel.text = feedback.title
        commentLabel.font = .systemFont(ofSize: 12)  // Reduced from 14
        commentLabel.textColor = .secondaryLabel
        commentLabel.numberOfLines = 1  // Limit to 1 line to keep card smaller
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(commentLabel)
        
        // Priority circle
        let priorityCircle = UIView()
        priorityCircle.backgroundColor = feedback.categoryColor
        priorityCircle.layer.cornerRadius = 24  // Reduced from 30
        priorityCircle.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(priorityCircle)
        
        let exclamationLabel = UILabel()
        exclamationLabel.text = "!"
        exclamationLabel.font = .systemFont(ofSize: 28, weight: .bold)  // Reduced from 32
        exclamationLabel.textColor = .white
        exclamationLabel.textAlignment = .center
        exclamationLabel.translatesAutoresizingMaskIntoConstraints = false
        priorityCircle.addSubview(exclamationLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            leftStripe.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            leftStripe.topAnchor.constraint(equalTo: containerView.topAnchor),
            leftStripe.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            leftStripe.widthAnchor.constraint(equalToConstant: 50),  // Reduced from 60
            
            contentContainer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),  // Reduced from 8
            contentContainer.leadingAnchor.constraint(equalTo: leftStripe.trailingAnchor, constant: 6),  // Reduced from 8
            contentContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),  // Reduced from -8
            contentContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -6),  // Reduced from -8
            
            ticketIDLabel.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 12),  // Reduced from 16
            ticketIDLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 12),  // Reduced from 16
            
            dateLabel.centerYAnchor.constraint(equalTo: ticketIDLabel.centerYAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -12),  // Reduced from -16
            
            descLabel.topAnchor.constraint(equalTo: ticketIDLabel.bottomAnchor, constant: 10),  // Reduced from 12
            descLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 12),  // Reduced from 16
            
            descText.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 3),  // Reduced from 4
            descText.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 12),  // Reduced from 16
            descText.trailingAnchor.constraint(equalTo: priorityCircle.leadingAnchor, constant: -10),  // Reduced from -12
            
            statusStack.topAnchor.constraint(equalTo: descText.bottomAnchor, constant: 8),  // Reduced from 12
            statusStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 12),  // Reduced from 16
            
            campusStack.topAnchor.constraint(equalTo: statusStack.bottomAnchor, constant: 6),  // Reduced from 8
            campusStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 12),  // Reduced from 16
            
            techStack.topAnchor.constraint(equalTo: campusStack.bottomAnchor, constant: 6),  // Reduced from 8
            techStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 12),  // Reduced from 16
            
            starStack.topAnchor.constraint(equalTo: techStack.bottomAnchor, constant: 8),  // Reduced from 12
            starStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 12),  // Reduced from 16
            
            commentLabel.topAnchor.constraint(equalTo: starStack.bottomAnchor, constant: 6),  // Reduced from 8
            commentLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 12),  // Reduced from 16
            commentLabel.trailingAnchor.constraint(equalTo: priorityCircle.leadingAnchor, constant: -10),  // Reduced from -12
            commentLabel.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -12),  // Reduced from -16
            
            priorityCircle.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor),
            priorityCircle.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -12),  // Reduced from -16
            priorityCircle.widthAnchor.constraint(equalToConstant: 48),  // Reduced from 60
            priorityCircle.heightAnchor.constraint(equalToConstant: 48),  // Reduced from 60
            
            exclamationLabel.centerXAnchor.constraint(equalTo: priorityCircle.centerXAnchor),
            exclamationLabel.centerYAnchor.constraint(equalTo: priorityCircle.centerYAnchor)
        ])
        
        stackView.addArrangedSubview(containerView)
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
