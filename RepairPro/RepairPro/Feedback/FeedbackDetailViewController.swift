//
//  FeedbackDetailViewController.swift
//  Fully programmatic - NO STORYBOARD NEEDED
//  Just tap a feedback card and this opens automatically!
//

import UIKit
import FirebaseFirestore
import Cloudinary

class FeedbackDetailViewController: UIViewController {
    
    // MARK: - Properties
    var feedback: Feedback?
    let db = Firestore.firestore()
    let cloudinary = CLDCloudinary(configuration: CLDConfiguration(cloudName: "dtthzideh"))
    
    private var imageURLs: [String] = []
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .white
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Placeholder images from Supabase
    private let placeholderImageURLs = [
        "https://wlefukllkrvgpjelkxav.supabase.co/storage/v1/object/public/images/Copilot_20251225_111257.png",
        "https://wlefukllkrvgpjelkxav.supabase.co/storage/v1/object/public/images/Copilot_20251225_112235.png",
        "https://wlefukllkrvgpjelkxav.supabase.co/storage/v1/object/public/images/Copilot_20251225_112136.png"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Ticket Details"
        view.backgroundColor = .white
        
        setupUI()
        displayFeedbackDetails()
    }
    
    func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    func displayFeedbackDetails() {
        guard let feedback = feedback else { return }
        
        // Clear existing views
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // MARK: - Ticket ID Header with Priority Badge
        let headerView = createTicketIDHeader(feedback: feedback)
        contentStackView.addArrangedSubview(headerView)
        
        // MARK: - Deadline
        let deadlineView = createInfoRow(title: "Deadline:", value: feedback.formattedDate, valueColor: .label)
        contentStackView.addArrangedSubview(deadlineView)
        
        // MARK: - Subject
        let subjectView = createInfoRow(title: "Subject:", value: feedback.title, valueColor: UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1))
        contentStackView.addArrangedSubview(subjectView)
        
        // MARK: - Description
        let descriptionView = createMultiLineSection(title: "Description", content: feedback.description)
        contentStackView.addArrangedSubview(descriptionView)
        
        // MARK: - Location
        let locationValue = feedback.campus ?? "Not specified"
        let locationView = createInfoRow(title: "Location:", value: locationValue, valueColor: UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1))
        contentStackView.addArrangedSubview(locationView)
        
        // MARK: - First Image
        if let imageUrls = feedback.image_urls, !imageUrls.isEmpty {
            imageURLs = imageUrls
            let imageView1 = createImageSection(imageUrl: imageUrls[0], index: 0)
            contentStackView.addArrangedSubview(imageView1)
        } else {
            // Use random placeholder image
            let randomPlaceholder = placeholderImageURLs.randomElement() ?? placeholderImageURLs[0]
            let placeholderView1 = createImageSection(imageUrl: randomPlaceholder, index: -1, isPlaceholder: true)
            contentStackView.addArrangedSubview(placeholderView1)
        }
        
        // MARK: - Technician
        let technicianView = createInfoRow(title: "Technician:", value: feedback.user_name, valueColor: .label)
        contentStackView.addArrangedSubview(technicianView)
        
        // MARK: - Status
        let statusView = createStatusSection(status: feedback.status)
        contentStackView.addArrangedSubview(statusView)
        
        // MARK: - Notes
        let notesContent = feedback.admin_response ?? "Switch changed."
        let notesView = createMultiLineSection(title: "Notes", content: notesContent)
        contentStackView.addArrangedSubview(notesView)
        
        // MARK: - Second Image
        if let imageUrls = feedback.image_urls, imageUrls.count > 1 {
            let imageView2 = createImageSection(imageUrl: imageUrls[1], index: 1, showLabel: false)
            contentStackView.addArrangedSubview(imageView2)
        } else {
            // Use random placeholder image
            let randomPlaceholder = placeholderImageURLs.randomElement() ?? placeholderImageURLs[1]
            let placeholderView2 = createImageSection(imageUrl: randomPlaceholder, index: -1, showLabel: false, isPlaceholder: true)
            contentStackView.addArrangedSubview(placeholderView2)
        }
        
        // MARK: - Feedback/Rating
        let feedbackText = "Happy with the result. The light flickering stopped."
        let ratingView = createRatingSection(rating: feedback.safeRating, feedbackText: feedbackText)
        contentStackView.addArrangedSubview(ratingView)
    }
    
    // MARK: - Create UI Components
    
    func createTicketIDHeader(feedback: Feedback) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Ticket ID:"
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        // Create text field box
        let textFieldBox = UIView()
        textFieldBox.backgroundColor = .white
        textFieldBox.layer.cornerRadius = 8
        textFieldBox.layer.borderWidth = 1
        textFieldBox.layer.borderColor = UIColor.systemGray4.cgColor
        textFieldBox.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textFieldBox)
        
        let ticketIDLabel = UILabel()
        ticketIDLabel.text = "\(feedback.feedback_id)"
        ticketIDLabel.font = .systemFont(ofSize: 14)
        ticketIDLabel.textColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1)
        ticketIDLabel.translatesAutoresizingMaskIntoConstraints = false
        textFieldBox.addSubview(ticketIDLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            textFieldBox.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            textFieldBox.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textFieldBox.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textFieldBox.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            ticketIDLabel.topAnchor.constraint(equalTo: textFieldBox.topAnchor, constant: 12),
            ticketIDLabel.leadingAnchor.constraint(equalTo: textFieldBox.leadingAnchor, constant: 12),
            ticketIDLabel.bottomAnchor.constraint(equalTo: textFieldBox.bottomAnchor, constant: -12)
        ])
        
        if let priority = feedback.priority {
            let priorityBadge = createPriorityBadge(priority: priority)
            priorityBadge.translatesAutoresizingMaskIntoConstraints = false
            textFieldBox.addSubview(priorityBadge)
            
            NSLayoutConstraint.activate([
                priorityBadge.trailingAnchor.constraint(equalTo: textFieldBox.trailingAnchor, constant: -12),
                priorityBadge.centerYAnchor.constraint(equalTo: ticketIDLabel.centerYAnchor),
                ticketIDLabel.trailingAnchor.constraint(lessThanOrEqualTo: priorityBadge.leadingAnchor, constant: -12)
            ])
        } else {
            ticketIDLabel.trailingAnchor.constraint(equalTo: textFieldBox.trailingAnchor, constant: -12).isActive = true
        }
        
        return container
    }
    
    func createInfoRow(title: String, value: String, valueColor: UIColor) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        // Create text field box
        let textFieldBox = UIView()
        textFieldBox.backgroundColor = .white
        textFieldBox.layer.cornerRadius = 8
        textFieldBox.layer.borderWidth = 1
        textFieldBox.layer.borderColor = UIColor.systemGray4.cgColor
        textFieldBox.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textFieldBox)
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textColor = valueColor
        valueLabel.numberOfLines = 0
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        textFieldBox.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            textFieldBox.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            textFieldBox.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textFieldBox.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textFieldBox.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            valueLabel.topAnchor.constraint(equalTo: textFieldBox.topAnchor, constant: 12),
            valueLabel.leadingAnchor.constraint(equalTo: textFieldBox.leadingAnchor, constant: 12),
            valueLabel.trailingAnchor.constraint(equalTo: textFieldBox.trailingAnchor, constant: -12),
            valueLabel.bottomAnchor.constraint(equalTo: textFieldBox.bottomAnchor, constant: -12)
        ])
        
        return container
    }
    
    func createMultiLineSection(title: String, content: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        // Create text field box
        let textFieldBox = UIView()
        textFieldBox.backgroundColor = .white
        textFieldBox.layer.cornerRadius = 8
        textFieldBox.layer.borderWidth = 1
        textFieldBox.layer.borderColor = UIColor.systemGray4.cgColor
        textFieldBox.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textFieldBox)
        
        let contentLabel = UILabel()
        contentLabel.text = content
        contentLabel.font = .systemFont(ofSize: 14)
        contentLabel.textColor = .secondaryLabel
        contentLabel.numberOfLines = 0
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        textFieldBox.addSubview(contentLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            textFieldBox.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            textFieldBox.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textFieldBox.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textFieldBox.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            contentLabel.topAnchor.constraint(equalTo: textFieldBox.topAnchor, constant: 12),
            contentLabel.leadingAnchor.constraint(equalTo: textFieldBox.leadingAnchor, constant: 12),
            contentLabel.trailingAnchor.constraint(equalTo: textFieldBox.trailingAnchor, constant: -12),
            contentLabel.bottomAnchor.constraint(equalTo: textFieldBox.bottomAnchor, constant: -12)
        ])
        
        return container
    }
    
    func createImageSection(imageUrl: String, index: Int, showLabel: Bool = true, isPlaceholder: Bool = false) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        var topAnchor: NSLayoutYAxisAnchor = container.topAnchor
        var topOffset: CGFloat = 0
        
        if showLabel {
            let titleLabel = UILabel()
            titleLabel.text = "Image attached:"
            titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
            titleLabel.textColor = .label
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(titleLabel)
            
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
                titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor)
            ])
            
            topAnchor = titleLabel.bottomAnchor
            topOffset = 8
        }
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = !isPlaceholder // Only allow tap on real images
        imageView.tag = index
        container.addSubview(imageView)
        
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.startAnimating()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
        
        // Only add tap gesture for real images, not placeholders
        if !isPlaceholder {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
            imageView.addGestureRecognizer(tapGesture)
        }
        
        loadImage(from: imageUrl, into: imageView) {
            loadingIndicator.stopAnimating()
            loadingIndicator.removeFromSuperview()
        }
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: topOffset),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    func createStatusSection(status: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Status:"
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        let statusBadge = createStatusBadge(status: status)
        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statusBadge)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            statusBadge.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            statusBadge.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            statusBadge.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    func createRatingSection(rating: Int, feedbackText: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Feedback:"
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        // Create text field box for feedback text
        let textFieldBox = UIView()
        textFieldBox.backgroundColor = .white
        textFieldBox.layer.cornerRadius = 8
        textFieldBox.layer.borderWidth = 1
        textFieldBox.layer.borderColor = UIColor.systemGray4.cgColor
        textFieldBox.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textFieldBox)
        
        let feedbackLabel = UILabel()
        feedbackLabel.text = feedbackText
        feedbackLabel.font = .systemFont(ofSize: 13)
        feedbackLabel.textColor = .secondaryLabel
        feedbackLabel.numberOfLines = 0
        feedbackLabel.translatesAutoresizingMaskIntoConstraints = false
        textFieldBox.addSubview(feedbackLabel)
        
        let starStack = UIStackView()
        starStack.axis = .horizontal
        starStack.spacing = 8
        starStack.distribution = .fillEqually
        starStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(starStack)
        
        for i in 1...5 {
            let starImageView = UIImageView()
            starImageView.contentMode = .scaleAspectFit
            starImageView.tintColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1)
            
            if i <= rating {
                starImageView.image = UIImage(systemName: "star.fill")
            } else {
                starImageView.image = UIImage(systemName: "star")
            }
            
            starImageView.translatesAutoresizingMaskIntoConstraints = false
            starImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
            starImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
            
            starStack.addArrangedSubview(starImageView)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            textFieldBox.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            textFieldBox.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textFieldBox.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            feedbackLabel.topAnchor.constraint(equalTo: textFieldBox.topAnchor, constant: 12),
            feedbackLabel.leadingAnchor.constraint(equalTo: textFieldBox.leadingAnchor, constant: 12),
            feedbackLabel.trailingAnchor.constraint(equalTo: textFieldBox.trailingAnchor, constant: -12),
            feedbackLabel.bottomAnchor.constraint(equalTo: textFieldBox.bottomAnchor, constant: -12),
            
            starStack.topAnchor.constraint(equalTo: textFieldBox.bottomAnchor, constant: 12),
            starStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            starStack.widthAnchor.constraint(equalToConstant: 200),
            starStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    func createPriorityBadge(priority: String) -> UIView {
        let container = UIView()
        
        // Set color based on priority: High = #00476F, Medium = #FEA214, Low = grey
        switch priority.lowercased() {
        case "high":
            container.backgroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1) // #00476F
        case "medium":
            container.backgroundColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1) // #FEA214
        case "low":
            container.backgroundColor = .systemGray
        default:
            container.backgroundColor = .systemGray
        }
        
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let iconLabel = UILabel()
        iconLabel.text = "!"
        iconLabel.font = .systemFont(ofSize: 14, weight: .bold)
        iconLabel.textColor = .white
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconLabel)
        
        let priorityLabel = UILabel()
        priorityLabel.text = "\(priority)-Priority"
        priorityLabel.font = .systemFont(ofSize: 11, weight: .bold)
        priorityLabel.textColor = .white
        priorityLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(priorityLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            iconLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            iconLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
            
            priorityLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 4),
            priorityLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            priorityLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    func createStatusBadge(status: String) -> UIView {
        let badge = UIView()
        
        var bgColor: UIColor
        var textColor: UIColor
        
        let lowercased = status.lowercased()
        if lowercased.contains("complete") || lowercased.contains("resolve") {
            bgColor = UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 0.15)
            textColor = UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1)
        } else if lowercased.contains("progress") {
            bgColor = UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 0.15)
            textColor = UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1)
        } else {
            bgColor = UIColor.systemGray.withAlphaComponent(0.15)
            textColor = .systemGray
        }
        
        badge.backgroundColor = bgColor
        badge.layer.cornerRadius = 4
        badge.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = status
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = textColor
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
    
    // MARK: - Image Loading
    
    func loadImage(from urlString: String, into imageView: UIImageView, completion: @escaping () -> Void) {
        if urlString.starts(with: "http") {
            loadRemoteImage(from: urlString, into: imageView, completion: completion)
        } else {
            if let url = cloudinary.createUrl().generate(urlString) {
                loadRemoteImage(from: url, into: imageView, completion: completion)
            } else {
                completion()
            }
        }
    }
    
    func loadRemoteImage(from urlString: String, into imageView: UIImageView, completion: @escaping () -> Void) {
        guard let url = URL(string: urlString) else {
            completion()
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            DispatchQueue.main.async {
                imageView.image = image
                completion()
            }
        }.resume()
    }
    
    @objc func imageTapped(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView else { return }
        
        if imageView.image != nil, imageView.tag < imageURLs.count {
            let imageUrl = imageURLs[imageView.tag]
            showFullScreenImage(imageUrl)
        }
    }
    
    func showFullScreenImage(_ urlString: String) {
        let imageVC = FullScreenImageViewController()
        imageVC.imageURL = urlString
        imageVC.cloudinary = cloudinary
        imageVC.modalPresentationStyle = .fullScreen
        present(imageVC, animated: true)
    }
}

// MARK: - Full Screen Image Viewer
class FullScreenImageViewController: UIViewController {
    var imageURL: String?
    var cloudinary: CLDCloudinary?
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let closeButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
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
        
        loadingIndicator.color = .white
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 22
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
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        loadImage()
    }
    
    func loadImage() {
        guard let urlString = imageURL else { return }
        
        loadingIndicator.startAnimating()
        
        if urlString.starts(with: "http") {
            loadRemoteImage(from: urlString)
        } else if let cloudinary = cloudinary {
            if let url = cloudinary.createUrl().generate(urlString) {
                loadRemoteImage(from: url)
            }
        }
    }
    
    func loadRemoteImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            loadingIndicator.stopAnimating()
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                }
                return
            }
            DispatchQueue.main.async {
                self?.imageView.image = image
                self?.loadingIndicator.stopAnimating()
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
