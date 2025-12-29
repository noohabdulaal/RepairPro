//
//  FeedbackDetailViewController.swift
//  Detailed view of feedback with admin response capability
//

import UIKit
import FirebaseFirestore
import Cloudinary

class FeedbackDetailViewController: UIViewController {
    
    var feedback: Feedback!
    let db = Firestore.firestore()
    let cloudinary = CLDCloudinary(configuration: CLDConfiguration(cloudName: "dtthzideh"))
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let feedbackIDLabel = UILabel()
    private let categoryLabel = UILabel()
    private let statusBadge = UIView()
    private let statusLabel = UILabel()
    private let starStack = UIStackView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let userInfoView = UIView()
    private let userNameLabel = UILabel()
    private let userEmailLabel = UILabel()
    private let dateLabel = UILabel()
    private let campusLabel = UILabel()
    private let priorityLabel = UILabel()
    private let imagesCollectionView: UICollectionView
    private let responseSection = UIView()
    private let responseTitleLabel = UILabel()
    private let responseTextView = UITextView()
    private let responseButton = UIButton(type: .system)
    private let adminResponseView = UIView()
    private let adminResponseLabel = UILabel()
    private let responseDateLabel = UILabel()
    
    // Image data
    private var imageURLs: [String] = []
    
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 120, height: 120)
        layout.minimumLineSpacing = 12
        self.imagesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        self.imagesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Feedback Details"
        view.backgroundColor = .systemGroupedBackground
        
        setupScrollView()
        setupHeaderView()
        setupContentSections()
        setupImagesCollectionView()
        setupResponseSection()
        populateData()
        
        // Add edit/update button for admins
        let moreButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: #selector(showActionMenu)
        )
        navigationItem.rightBarButtonItem = moreButton
    }
    
    // MARK: - Setup UI
    func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    func setupHeaderView() {
        headerView.backgroundColor = .secondarySystemGroupedBackground
        headerView.layer.cornerRadius = 16
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)
        
        // Feedback ID
        feedbackIDLabel.font = .systemFont(ofSize: 24, weight: .bold)
        feedbackIDLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(feedbackIDLabel)
        
        // Category
        categoryLabel.font = .systemFont(ofSize: 16, weight: .medium)
        categoryLabel.textColor = .secondaryLabel
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(categoryLabel)
        
        // Status Badge
        statusBadge.layer.cornerRadius = 12
        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(statusBadge)
        
        statusLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusBadge.addSubview(statusLabel)
        
        // Star Rating
        starStack.axis = .horizontal
        starStack.spacing = 4
        starStack.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(starStack)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            feedbackIDLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            feedbackIDLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            statusBadge.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            statusBadge.centerYAnchor.constraint(equalTo: feedbackIDLabel.centerYAnchor),
            
            statusLabel.leadingAnchor.constraint(equalTo: statusBadge.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: statusBadge.trailingAnchor, constant: -12),
            statusLabel.topAnchor.constraint(equalTo: statusBadge.topAnchor, constant: 8),
            statusLabel.bottomAnchor.constraint(equalTo: statusBadge.bottomAnchor, constant: -8),
            
            categoryLabel.topAnchor.constraint(equalTo: feedbackIDLabel.bottomAnchor, constant: 8),
            categoryLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            starStack.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 12),
            starStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            starStack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -20)
        ])
    }
    
    func setupContentSections() {
        // Title Section
        let titleContainer = createSectionContainer()
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleContainer.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: titleContainer.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor, constant: -20),
            titleLabel.bottomAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: -16)
        ])
        
        contentView.addSubview(titleContainer)
        
        // Description Section
        let descContainer = createSectionContainer()
        let descTitle = UILabel()
        descTitle.text = "Description"
        descTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        descTitle.translatesAutoresizingMaskIntoConstraints = false
        descContainer.addSubview(descTitle)
        
        descriptionLabel.font = .systemFont(ofSize: 15)
        descriptionLabel.textColor = .label
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descContainer.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            descTitle.topAnchor.constraint(equalTo: descContainer.topAnchor, constant: 16),
            descTitle.leadingAnchor.constraint(equalTo: descContainer.leadingAnchor, constant: 20),
            descTitle.trailingAnchor.constraint(equalTo: descContainer.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: descTitle.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: descContainer.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: descContainer.trailingAnchor, constant: -20),
            descriptionLabel.bottomAnchor.constraint(equalTo: descContainer.bottomAnchor, constant: -16)
        ])
        
        contentView.addSubview(descContainer)
        
        // User Info Section
        userInfoView.backgroundColor = .secondarySystemGroupedBackground
        userInfoView.layer.cornerRadius = 16
        userInfoView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(userInfoView)
        
        let userIcon = UILabel()
        userIcon.text = "👤"
        userIcon.font = .systemFont(ofSize: 24)
        userIcon.translatesAutoresizingMaskIntoConstraints = false
        userInfoView.addSubview(userIcon)
        
        userNameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        userNameLabel.translatesAutoresizingMaskIntoConstraints = false
        userInfoView.addSubview(userNameLabel)
        
        userEmailLabel.font = .systemFont(ofSize: 14)
        userEmailLabel.textColor = .secondaryLabel
        userEmailLabel.translatesAutoresizingMaskIntoConstraints = false
        userInfoView.addSubview(userEmailLabel)
        
        dateLabel.font = .systemFont(ofSize: 13)
        dateLabel.textColor = .systemGray
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        userInfoView.addSubview(dateLabel)
        
        campusLabel.font = .systemFont(ofSize: 14)
        campusLabel.textColor = .secondaryLabel
        campusLabel.translatesAutoresizingMaskIntoConstraints = false
        userInfoView.addSubview(campusLabel)
        
        priorityLabel.font = .systemFont(ofSize: 14, weight: .medium)
        priorityLabel.translatesAutoresizingMaskIntoConstraints = false
        userInfoView.addSubview(priorityLabel)
        
        NSLayoutConstraint.activate([
            userIcon.leadingAnchor.constraint(equalTo: userInfoView.leadingAnchor, constant: 20),
            userIcon.topAnchor.constraint(equalTo: userInfoView.topAnchor, constant: 16),
            
            userNameLabel.leadingAnchor.constraint(equalTo: userIcon.trailingAnchor, constant: 12),
            userNameLabel.topAnchor.constraint(equalTo: userInfoView.topAnchor, constant: 16),
            userNameLabel.trailingAnchor.constraint(equalTo: userInfoView.trailingAnchor, constant: -20),
            
            userEmailLabel.leadingAnchor.constraint(equalTo: userIcon.trailingAnchor, constant: 12),
            userEmailLabel.topAnchor.constraint(equalTo: userNameLabel.bottomAnchor, constant: 4),
            userEmailLabel.trailingAnchor.constraint(equalTo: userInfoView.trailingAnchor, constant: -20),
            
            dateLabel.leadingAnchor.constraint(equalTo: userInfoView.leadingAnchor, constant: 20),
            dateLabel.topAnchor.constraint(equalTo: userEmailLabel.bottomAnchor, constant: 12),
            
            campusLabel.leadingAnchor.constraint(equalTo: userInfoView.leadingAnchor, constant: 20),
            campusLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            
            priorityLabel.leadingAnchor.constraint(equalTo: userInfoView.leadingAnchor, constant: 20),
            priorityLabel.topAnchor.constraint(equalTo: campusLabel.bottomAnchor, constant: 8),
            priorityLabel.bottomAnchor.constraint(equalTo: userInfoView.bottomAnchor, constant: -16)
        ])
        
        // Layout containers
        NSLayoutConstraint.activate([
            titleContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            titleContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            descContainer.topAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: 16),
            descContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            userInfoView.topAnchor.constraint(equalTo: descContainer.bottomAnchor, constant: 16),
            userInfoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            userInfoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func setupImagesCollectionView() {
        imagesCollectionView.backgroundColor = .clear
        imagesCollectionView.showsHorizontalScrollIndicator = false
        imagesCollectionView.delegate = self
        imagesCollectionView.dataSource = self
        imagesCollectionView.register(FeedbackImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        imagesCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(imagesCollectionView)
        
        NSLayoutConstraint.activate([
            imagesCollectionView.topAnchor.constraint(equalTo: userInfoView.bottomAnchor, constant: 16),
            imagesCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            imagesCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            imagesCollectionView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    func setupResponseSection() {
        // Admin Response Display (if exists)
        adminResponseView.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        adminResponseView.layer.cornerRadius = 16
        adminResponseView.layer.borderWidth = 1
        adminResponseView.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.3).cgColor
        adminResponseView.translatesAutoresizingMaskIntoConstraints = false
        adminResponseView.isHidden = true
        contentView.addSubview(adminResponseView)
        
        let responseTitle = UILabel()
        responseTitle.text = "✓ Admin Response"
        responseTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        responseTitle.textColor = .systemGreen
        responseTitle.translatesAutoresizingMaskIntoConstraints = false
        adminResponseView.addSubview(responseTitle)
        
        adminResponseLabel.font = .systemFont(ofSize: 15)
        adminResponseLabel.textColor = .label
        adminResponseLabel.numberOfLines = 0
        adminResponseLabel.translatesAutoresizingMaskIntoConstraints = false
        adminResponseView.addSubview(adminResponseLabel)
        
        responseDateLabel.font = .systemFont(ofSize: 12)
        responseDateLabel.textColor = .systemGray
        responseDateLabel.translatesAutoresizingMaskIntoConstraints = false
        adminResponseView.addSubview(responseDateLabel)
        
        NSLayoutConstraint.activate([
            responseTitle.topAnchor.constraint(equalTo: adminResponseView.topAnchor, constant: 16),
            responseTitle.leadingAnchor.constraint(equalTo: adminResponseView.leadingAnchor, constant: 20),
            responseTitle.trailingAnchor.constraint(equalTo: adminResponseView.trailingAnchor, constant: -20),
            
            adminResponseLabel.topAnchor.constraint(equalTo: responseTitle.bottomAnchor, constant: 12),
            adminResponseLabel.leadingAnchor.constraint(equalTo: adminResponseView.leadingAnchor, constant: 20),
            adminResponseLabel.trailingAnchor.constraint(equalTo: adminResponseView.trailingAnchor, constant: -20),
            
            responseDateLabel.topAnchor.constraint(equalTo: adminResponseLabel.bottomAnchor, constant: 12),
            responseDateLabel.leadingAnchor.constraint(equalTo: adminResponseView.leadingAnchor, constant: 20),
            responseDateLabel.bottomAnchor.constraint(equalTo: adminResponseView.bottomAnchor, constant: -16)
        ])
        
        // Response Input Section
        responseSection.backgroundColor = .secondarySystemGroupedBackground
        responseSection.layer.cornerRadius = 16
        responseSection.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(responseSection)
        
        responseTitleLabel.text = "Add Response"
        responseTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        responseTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        responseSection.addSubview(responseTitleLabel)
        
        responseTextView.font = .systemFont(ofSize: 15)
        responseTextView.layer.cornerRadius = 12
        responseTextView.layer.borderWidth = 1
        responseTextView.layer.borderColor = UIColor.systemGray4.cgColor
        responseTextView.backgroundColor = .tertiarySystemGroupedBackground
        responseTextView.translatesAutoresizingMaskIntoConstraints = false
        responseSection.addSubview(responseTextView)
        
        responseButton.setTitle("Submit Response", for: .normal)
        responseButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        responseButton.backgroundColor = .systemBlue
        responseButton.setTitleColor(.white, for: .normal)
        responseButton.layer.cornerRadius = 12
        responseButton.translatesAutoresizingMaskIntoConstraints = false
        responseButton.addTarget(self, action: #selector(submitResponse), for: .touchUpInside)
        responseSection.addSubview(responseButton)
        
        NSLayoutConstraint.activate([
            adminResponseView.topAnchor.constraint(equalTo: imagesCollectionView.bottomAnchor, constant: 16),
            adminResponseView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            adminResponseView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            responseSection.topAnchor.constraint(equalTo: adminResponseView.bottomAnchor, constant: 16),
            responseSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            responseSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            responseSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            responseTitleLabel.topAnchor.constraint(equalTo: responseSection.topAnchor, constant: 16),
            responseTitleLabel.leadingAnchor.constraint(equalTo: responseSection.leadingAnchor, constant: 20),
            responseTitleLabel.trailingAnchor.constraint(equalTo: responseSection.trailingAnchor, constant: -20),
            
            responseTextView.topAnchor.constraint(equalTo: responseTitleLabel.bottomAnchor, constant: 12),
            responseTextView.leadingAnchor.constraint(equalTo: responseSection.leadingAnchor, constant: 20),
            responseTextView.trailingAnchor.constraint(equalTo: responseSection.trailingAnchor, constant: -20),
            responseTextView.heightAnchor.constraint(equalToConstant: 120),
            
            responseButton.topAnchor.constraint(equalTo: responseTextView.bottomAnchor, constant: 16),
            responseButton.leadingAnchor.constraint(equalTo: responseSection.leadingAnchor, constant: 20),
            responseButton.trailingAnchor.constraint(equalTo: responseSection.trailingAnchor, constant: -20),
            responseButton.heightAnchor.constraint(equalToConstant: 50),
            responseButton.bottomAnchor.constraint(equalTo: responseSection.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Populate Data
    func populateData() {
        guard let feedback = feedback else { return }
        
        feedbackIDLabel.text = "Feedback #\(feedback.feedback_id)"
        categoryLabel.text = "\(feedback.categoryEmoji) \(feedback.category)"
        
        let statusColor = getStatusColor(for: feedback.status)
        statusBadge.backgroundColor = statusColor.withAlphaComponent(0.2)
        statusLabel.text = feedback.status
        statusLabel.textColor = statusColor
        
        // Star rating
        for i in 1...5 {
            let star = UILabel()
            star.text = i <= feedback.rating ? "⭐" : "☆"
            star.font = .systemFont(ofSize: 24)
            starStack.addArrangedSubview(star)
        }
        
        let ratingLabel = UILabel()
        ratingLabel.text = "(\(feedback.rating)/5)"
        ratingLabel.font = .systemFont(ofSize: 16, weight: .medium)
        ratingLabel.textColor = .secondaryLabel
        starStack.addArrangedSubview(ratingLabel)
        
        titleLabel.text = feedback.title
        descriptionLabel.text = feedback.description
        
        userNameLabel.text = feedback.user_name
        userEmailLabel.text = feedback.user_email ?? "No email provided"
        dateLabel.text = "📅 \(feedback.formattedDate)"
        
        if let campus = feedback.campus {
            campusLabel.text = "📍 Campus \(campus)"
            campusLabel.isHidden = false
        } else {
            campusLabel.isHidden = true
        }
        
        if let priority = feedback.priority {
            let color = feedback.priorityColor
            priorityLabel.text = "⚡ \(priority) Priority"
            priorityLabel.textColor = color
            priorityLabel.isHidden = false
        } else {
            priorityLabel.isHidden = true
        }
        
        // Images
        if let urls = feedback.image_urls, !urls.isEmpty {
            imageURLs = urls
            imagesCollectionView.isHidden = false
            imagesCollectionView.reloadData()
        } else {
            imagesCollectionView.isHidden = true
        }
        
        // Admin response
        if feedback.hasResponse {
            adminResponseView.isHidden = false
            adminResponseLabel.text = feedback.admin_response
            
            if let responseDate = feedback.response_date {
                let formatter = ISO8601DateFormatter()
                if let date = formatter.date(from: responseDate) {
                    let displayFormatter = DateFormatter()
                    displayFormatter.dateFormat = "MMM dd, yyyy 'at' HH:mm"
                    responseDateLabel.text = "Responded: \(displayFormatter.string(from: date))"
                }
            }
            
            responseSection.isHidden = true
        } else {
            adminResponseView.isHidden = true
            responseSection.isHidden = false
        }
    }
    
    // MARK: - Actions
    @objc func showActionMenu() {
        let alert = UIAlertController(title: "Actions", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Change Status", style: .default) { [weak self] _ in
            self?.showStatusPicker()
        })
        
        alert.addAction(UIAlertAction(title: "Set Priority", style: .default) { [weak self] _ in
            self?.showPriorityPicker()
        })
        
        if !feedback.hasResponse {
            alert.addAction(UIAlertAction(title: "Quick Responses", style: .default) { [weak self] _ in
                self?.showQuickResponses()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    func showStatusPicker() {
        let alert = UIAlertController(title: "Change Status", message: nil, preferredStyle: .actionSheet)
        
        let statuses = ["Pending", "Reviewed", "Resolved", "Closed"]
        for status in statuses {
            alert.addAction(UIAlertAction(title: status, style: .default) { [weak self] _ in
                self?.updateStatus(status)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func showPriorityPicker() {
        let alert = UIAlertController(title: "Set Priority", message: nil, preferredStyle: .actionSheet)
        
        let priorities = ["Low", "Medium", "High"]
        for priority in priorities {
            alert.addAction(UIAlertAction(title: priority, style: .default) { [weak self] _ in
                self?.updatePriority(priority)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func showQuickResponses() {
        let alert = UIAlertController(title: "Quick Responses", message: nil, preferredStyle: .actionSheet)
        
        let responses = [
            "Thank you for your feedback. We're looking into this.",
            "We appreciate your suggestion and will consider it.",
            "This issue has been resolved. Thank you for reporting.",
            "We're working on this and will update you soon."
        ]
        
        for response in responses {
            alert.addAction(UIAlertAction(title: response, style: .default) { [weak self] _ in
                self?.responseTextView.text = response
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc func submitResponse() {
        guard let responseText = responseTextView.text, !responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Error", message: "Please enter a response.")
            return
        }
        
        let formatter = ISO8601DateFormatter()
        let now = formatter.string(from: Date())
        
        guard let feedbackID = feedback.id else { return }
        
        db.collection("Feedback").document(feedbackID).updateData([
            "admin_response": responseText,
            "response_date": now,
            "status": "Reviewed"
        ]) { [weak self] error in
            if let error = error {
                self?.showAlert(title: "Error", message: "Failed to submit response: \(error.localizedDescription)")
            } else {
                self?.showAlert(title: "Success", message: "Response submitted successfully!")
                self?.responseTextView.text = ""
                // Refresh data
                self?.feedback.admin_response = responseText
                self?.feedback.response_date = now
                self?.feedback.status = "Reviewed"
                self?.populateData()
            }
        }
    }
    
    func updateStatus(_ status: String) {
        guard let feedbackID = feedback.id else { return }
        
        db.collection("Feedback").document(feedbackID).updateData([
            "status": status
        ]) { [weak self] error in
            if let error = error {
                self?.showAlert(title: "Error", message: error.localizedDescription)
            } else {
                self?.feedback.status = status
                self?.populateData()
                self?.showAlert(title: "Success", message: "Status updated to \(status)")
            }
        }
    }
    
    func updatePriority(_ priority: String) {
        guard let feedbackID = feedback.id else { return }
        
        db.collection("Feedback").document(feedbackID).updateData([
            "priority": priority
        ]) { [weak self] error in
            if let error = error {
                self?.showAlert(title: "Error", message: error.localizedDescription)
            } else {
                self?.feedback.priority = priority
                self?.populateData()
                self?.showAlert(title: "Success", message: "Priority set to \(priority)")
            }
        }
    }
    
    // MARK: - Helper Methods
    func createSectionContainer() -> UIView {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    func getStatusColor(for status: String) -> UIColor {
        switch status.lowercased() {
        case "resolved":
            return UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        case "reviewed":
            return UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1)
        case "pending":
            return UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1)
        case "closed":
            return UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)
        default:
            return .systemGray
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionView Delegate & DataSource
extension FeedbackDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! FeedbackImageCell
        let imageURL = imageURLs[indexPath.item]
        cell.configure(with: imageURL, cloudinary: cloudinary)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Show full-screen image viewer
        let imageURL = imageURLs[indexPath.item]
        showFullScreenImage(imageURL)
    }
    
    func showFullScreenImage(_ urlString: String) {
        let imageVC = FullScreenImageViewController()
        imageVC.imageURL = urlString
        imageVC.cloudinary = cloudinary
        imageVC.modalPresentationStyle = .fullScreen
        present(imageVC, animated: true)
    }
}

// MARK: - Image Cell
class FeedbackImageCell: UICollectionViewCell {
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with urlString: String, cloudinary: CLDCloudinary) {
        imageView.image = nil
        
        if urlString.starts(with: "http") {
            loadImage(from: urlString)
        } else {
            if let url = cloudinary.createUrl().generate(urlString) {
                loadImage(from: url)
            }
        }
    }
    
    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.imageView.image = image
            }
        }.resume()
    }
}

// MARK: - Full Screen Image Viewer
class FullScreenImageViewController: UIViewController {
    var imageURL: String?
    var cloudinary: CLDCloudinary?
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let closeButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        loadImage()
    }
    
    func loadImage() {
        guard let urlString = imageURL else { return }
        
        if urlString.starts(with: "http") {
            loadRemoteImage(from: urlString)
        } else if let cloudinary = cloudinary {
            if let url = cloudinary.createUrl().generate(urlString) {
                loadRemoteImage(from: url)
            }
        }
    }
    
    func loadRemoteImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.imageView.image = image
            }
        }.resume()
    }
    
    @objc func closeTapped() {
        dismiss(animated: true)
    }
}

extension FullScreenImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
