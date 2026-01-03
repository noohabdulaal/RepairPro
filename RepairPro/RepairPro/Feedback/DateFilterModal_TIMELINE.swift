//
//  DateFilterModal.swift
//  Timeline Style Date Filter Modal
//

//
//  DateFilterModal_TIMELINE.swift
//  Timeline-style date filter modal with preset date ranges
//
//  PURPOSE:
//  - Provides a visual timeline interface for selecting date ranges
//  - Offers preset options (Past 24 hours, Past 3 days, Past week, Past month, All Time)
//  - Returns selected date range to calling view controller via callback closure
//

import UIKit

class DateFilterModal: UIViewController {
    
    // MARK: - Properties
    var applyFilter: ((String) -> Void)?
    var selectedDate: String = "Past 3 days"
    
    let dateOptions = [
        ("All Time", "Show everything"),
        ("Past 24 hours", "Today's feedback"),
        ("Past 3 days", "This week so far"),
        ("Past week", "Last 7 days"),
        ("Past month", "Last 30 days")
    ]
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 24
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 10)
        view.layer.shadowRadius = 30
        view.layer.shadowOpacity = 0.3
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Filter by Date"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose a time period"
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timelineScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let timelineContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let timelineLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.backgroundColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 14
        button.layer.shadowColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1).cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 16
        button.layer.shadowOpacity = 0.3
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var timelineItems: [TimelineItemView] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        createTimelineItems()
        
        // Animate appearance
        containerView.alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Tap to dismiss background
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(timelineScrollView)
        timelineScrollView.addSubview(timelineContainer)
        containerView.addSubview(doneButton)
        
        // Add gradient timeline line
        timelineContainer.addSubview(timelineLine)
        
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.heightAnchor.constraint(equalToConstant: 520),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Scroll view
            timelineScrollView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            timelineScrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            timelineScrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            timelineScrollView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -24),
            
            // Timeline container inside scroll view
            timelineContainer.topAnchor.constraint(equalTo: timelineScrollView.topAnchor),
            timelineContainer.leadingAnchor.constraint(equalTo: timelineScrollView.leadingAnchor),
            timelineContainer.trailingAnchor.constraint(equalTo: timelineScrollView.trailingAnchor),
            timelineContainer.bottomAnchor.constraint(equalTo: timelineScrollView.bottomAnchor),
            timelineContainer.widthAnchor.constraint(equalTo: timelineScrollView.widthAnchor),
            
            doneButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            doneButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            doneButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            doneButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func createTimelineItems() {
        var previousItem: TimelineItemView?
        
        for (index, option) in dateOptions.enumerated() {
            let item = TimelineItemView()
            item.configure(title: option.0, description: option.1, isSelected: option.0 == selectedDate)
            item.translatesAutoresizingMaskIntoConstraints = false
            item.onTap = { [weak self] in
                self?.selectDate(option.0)
            }
            
            timelineContainer.addSubview(item)
            timelineItems.append(item)
            
            NSLayoutConstraint.activate([
                item.leadingAnchor.constraint(equalTo: timelineContainer.leadingAnchor, constant: 40),
                item.trailingAnchor.constraint(equalTo: timelineContainer.trailingAnchor)
            ])
            
            if let previous = previousItem {
                item.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 16).isActive = true
            } else {
                item.topAnchor.constraint(equalTo: timelineContainer.topAnchor).isActive = true
            }
            
            previousItem = item
        }
        
        // Set timeline container bottom to last item
        if let lastItem = previousItem {
            timelineContainer.bottomAnchor.constraint(equalTo: lastItem.bottomAnchor).isActive = true
        }
        
        // Add timeline line constraints
        timelineLine.leadingAnchor.constraint(equalTo: timelineContainer.leadingAnchor, constant: 14).isActive = true
        timelineLine.topAnchor.constraint(equalTo: timelineContainer.topAnchor, constant: 8).isActive = true
        timelineLine.widthAnchor.constraint(equalToConstant: 3).isActive = true
        
        // Line should only go to the last item
        if let lastItem = timelineItems.last {
            timelineLine.bottomAnchor.constraint(equalTo: lastItem.bottomAnchor, constant: -8).isActive = true
        }
        
        // Create gradient for timeline line after layout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let gradient = CAGradientLayer()
            gradient.colors = [
                UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1).cgColor,
                UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1).cgColor
            ]
            gradient.startPoint = CGPoint(x: 0.5, y: 0)
            gradient.endPoint = CGPoint(x: 0.5, y: 1)
            gradient.frame = self.timelineLine.bounds
            gradient.cornerRadius = 2
            self.timelineLine.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            self.timelineLine.layer.addSublayer(gradient)
        }
    }
    
    private func selectDate(_ date: String) {
        selectedDate = date
        
        // Update all items
        for (index, item) in timelineItems.enumerated() {
            item.setSelected(dateOptions[index].0 == selectedDate)
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    // MARK: - Actions
    @objc private func backgroundTapped() {
        dismissModal()
    }
    
    @objc private func doneTapped() {
        // Animate button
        UIView.animate(withDuration: 0.1, animations: {
            self.doneButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.doneButton.transform = .identity
            }
        }
        
        // Apply filter
        applyFilter?(selectedDate)
        
        // Dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.dismissModal()
        }
    }
    
    private func dismissModal() {
        UIView.animate(withDuration: 0.2, animations: {
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
        }) { _ in
            self.dismiss(animated: false)
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension DateFilterModal: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: view)
        return !containerView.frame.contains(location)
    }
}

// MARK: - Timeline Item View
class TimelineItemView: UIView {
    
    var onTap: (() -> Void)?
    
    private let dotView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderWidth = 3
        view.layer.borderColor = UIColor(red: 206/255, green: 212/255, blue: 218/255, alpha: 1).cgColor
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let contentContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 248/255, green: 249/255, blue: 250/255, alpha: 1)
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.clear.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(red: 108/255, green: 117/255, blue: 125/255, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(dotView)
        addSubview(contentContainer)
        contentContainer.addSubview(titleLabel)
        contentContainer.addSubview(descriptionLabel)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            dotView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -33),
            dotView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            dotView.widthAnchor.constraint(equalToConstant: 16),
            dotView.heightAnchor.constraint(equalToConstant: 16),
            
            contentContainer.topAnchor.constraint(equalTo: topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -14)
        ])
    }
    
    func configure(title: String, description: String, isSelected: Bool) {
        titleLabel.text = title
        descriptionLabel.text = description
        setSelected(isSelected, animated: false)
    }
    
    func setSelected(_ selected: Bool, animated: Bool = true) {
        let animations = {
            if selected {
                self.dotView.backgroundColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1)
                self.dotView.layer.borderColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1).cgColor
                self.dotView.layer.shadowColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1).cgColor
                self.dotView.layer.shadowOffset = CGSize(width: 0, height: 0)
                self.dotView.layer.shadowRadius = 6
                self.dotView.layer.shadowOpacity = 0.4
                
                self.contentContainer.backgroundColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 0.15)
                self.contentContainer.layer.borderColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1).cgColor
            } else {
                self.dotView.backgroundColor = .white
                self.dotView.layer.borderColor = UIColor(red: 206/255, green: 212/255, blue: 218/255, alpha: 1).cgColor
                self.dotView.layer.shadowOpacity = 0
                
                self.contentContainer.backgroundColor = UIColor(red: 248/255, green: 249/255, blue: 250/255, alpha: 1)
                self.contentContainer.layer.borderColor = UIColor.clear.cgColor
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: animations)
        } else {
            animations()
        }
    }
    
    @objc private func handleTap() {
        // Scale animation
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5) {
                self.transform = .identity
            }
        }
        
        onTap?()
    }
}
