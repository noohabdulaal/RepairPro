//
//  StatisticsViewController.swift
//  ENHANCED VERSION - With subtle animations and visual polish
//

import UIKit
import FirebaseFirestore

class StatisticsViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Stats Cards Container
    private let statsContainer = UIView()
    private let ticketsCard = StatCardView()
    private let resolutionCard = StatCardView()
    
    // Month Selector
    private let monthSelectorButton = UIButton(type: .system)
    
    // Locations Container
    private let locationsContainer = UIView()
    private let locationsLabel = UILabel()
    private let locationsStackView = UIStackView()
    
    // Chart
    private let chartView = LineChartView()
    
    // Performance Button
    private let performanceButton = UIButton(type: .system)
    
    // MARK: - Data
    private var chartData: [CGFloat] = []
    private let db = Firestore.firestore()
    private var currentMonth = "October 2025"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Statistics"
        view.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1) // Subtle background
        
        setupScrollView()
        setupStatsCards()
        setupMonthSelector()
        setupLocationsContainer()
        setupPerformanceButton()
        setupConstraints()
        
        // Fetch real data from Firebase
        fetchStatistics()
        
        // Add entrance animations
        animateEntranceSequence()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Animate chart after view appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.chartView.animateChart()
        }
    }
    
    // MARK: - Setup Methods
    
    func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    func setupStatsCards() {
        statsContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statsContainer)
        
        // Tickets Card with enhancement
        ticketsCard.configure(
            title: "Estimated tickets per month",
            value: "127 tickets",
            subtitle: "+30% increase this month",
            isPositive: true
        )
        ticketsCard.translatesAutoresizingMaskIntoConstraints = false
        ticketsCard.alpha = 0 // For animation
        statsContainer.addSubview(ticketsCard)
        
        // Resolution Card with HOT badge
        resolutionCard.configure(
            title: "Average resolution time",
            value: "5h 23m",
            subtitle: "+3% increase this month",
            isPositive: true
        )
        resolutionCard.addHotBadge() // ✨ Enhancement
        resolutionCard.translatesAutoresizingMaskIntoConstraints = false
        resolutionCard.alpha = 0 // For animation
        statsContainer.addSubview(resolutionCard)
    }
    
    func setupMonthSelector() {
        monthSelectorButton.setTitle("October 2025", for: .normal)
        monthSelectorButton.setTitleColor(.label, for: .normal)
        monthSelectorButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        monthSelectorButton.backgroundColor = .systemBackground
        monthSelectorButton.layer.cornerRadius = 20 // More rounded
        monthSelectorButton.layer.borderWidth = 1
        monthSelectorButton.layer.borderColor = UIColor.systemGray5.cgColor
        monthSelectorButton.contentHorizontalAlignment = .center
        monthSelectorButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        
        // ✨ Enhancement: Shadow
        monthSelectorButton.layer.shadowColor = UIColor.black.cgColor
        monthSelectorButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        monthSelectorButton.layer.shadowRadius = 4
        monthSelectorButton.layer.shadowOpacity = 0.05
        
        // Add dropdown arrow
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let arrowImage = UIImage(systemName: "chevron.down", withConfiguration: config)
        monthSelectorButton.setImage(arrowImage, for: .normal)
        monthSelectorButton.tintColor = .label
        monthSelectorButton.semanticContentAttribute = .forceRightToLeft
        monthSelectorButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        
        monthSelectorButton.addTarget(self, action: #selector(monthSelectorTapped), for: .touchUpInside)
        monthSelectorButton.translatesAutoresizingMaskIntoConstraints = false
        monthSelectorButton.alpha = 0 // For animation
        contentView.addSubview(monthSelectorButton)
        
        // ✨ Enhancement: Tap animation
        addTapAnimation(to: monthSelectorButton)
    }
    
    func setupLocationsContainer() {
        // Container with enhanced styling
        locationsContainer.backgroundColor = .systemBackground
        locationsContainer.layer.cornerRadius = 24 // More rounded
        locationsContainer.layer.borderWidth = 1
        locationsContainer.layer.borderColor = UIColor.systemGray6.cgColor
        
        // ✨ Enhancement: Better shadow
        locationsContainer.layer.shadowColor = UIColor.black.cgColor
        locationsContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        locationsContainer.layer.shadowRadius = 12
        locationsContainer.layer.shadowOpacity = 0.08
        
        locationsContainer.translatesAutoresizingMaskIntoConstraints = false
        locationsContainer.alpha = 0 // For animation
        contentView.addSubview(locationsContainer)
        
        // Title label
        locationsLabel.text = "Location where most issues occurred"
        locationsLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        locationsLabel.textColor = .label
        locationsLabel.translatesAutoresizingMaskIntoConstraints = false
        locationsContainer.addSubview(locationsLabel)
        
        // Locations stack
        locationsStackView.axis = .vertical
        locationsStackView.spacing = 12
        locationsStackView.translatesAutoresizingMaskIntoConstraints = false
        locationsContainer.addSubview(locationsStackView)
        
        // Chart inside locations container
        chartView.translatesAutoresizingMaskIntoConstraints = false
        locationsContainer.addSubview(chartView)
        
        // Add placeholder location items with dots
        let locations = ["Campus A, B19", "Campus A, B5", "Campus A, B36", "Campus B, B20", "Campus B, B25"]
        for location in locations {
            let locationView = createEnhancedLocationView(text: location)
            locationsStackView.addArrangedSubview(locationView)
        }
        
        NSLayoutConstraint.activate([
            locationsLabel.topAnchor.constraint(equalTo: locationsContainer.topAnchor, constant: 24),
            locationsLabel.leadingAnchor.constraint(equalTo: locationsContainer.leadingAnchor, constant: 24),
            locationsLabel.trailingAnchor.constraint(equalTo: locationsContainer.trailingAnchor, constant: -24),
            
            locationsStackView.topAnchor.constraint(equalTo: locationsLabel.bottomAnchor, constant: 24),
            locationsStackView.leadingAnchor.constraint(equalTo: locationsContainer.leadingAnchor, constant: 24),
            locationsStackView.widthAnchor.constraint(equalToConstant: 140),
            
            chartView.topAnchor.constraint(equalTo: locationsLabel.bottomAnchor, constant: 20),
            chartView.leadingAnchor.constraint(equalTo: locationsStackView.trailingAnchor, constant: 10),
            chartView.trailingAnchor.constraint(equalTo: locationsContainer.trailingAnchor, constant: -24),
            chartView.bottomAnchor.constraint(equalTo: locationsContainer.bottomAnchor, constant: -24),
            chartView.heightAnchor.constraint(equalToConstant: 240)
        ])
    }
    
    // ✨ Enhancement: Location view with dot indicator
    func createEnhancedLocationView(text: String) -> UIView {
        let container = UIView()
        
        let dotView = UIView()
        dotView.backgroundColor = UIColor.systemGray4
        dotView.layer.cornerRadius = 4
        dotView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(dotView)
        
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            dotView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dotView.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            dotView.widthAnchor.constraint(equalToConstant: 8),
            dotView.heightAnchor.constraint(equalToConstant: 8),
            
            label.leadingAnchor.constraint(equalTo: dotView.trailingAnchor, constant: 10),
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    func createLocationLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        return label
    }
    
    func setupPerformanceButton() {
        performanceButton.setTitle("View Technician Performance", for: .normal)
        performanceButton.setTitleColor(.white, for: .normal)
        performanceButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        performanceButton.backgroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1)
        performanceButton.layer.cornerRadius = 16
        
        // ✨ Enhancement: Better shadow and glow
        performanceButton.layer.shadowColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1).cgColor
        performanceButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        performanceButton.layer.shadowRadius = 12
        performanceButton.layer.shadowOpacity = 0.25
        
        performanceButton.addTarget(self, action: #selector(performanceButtonTapped), for: .touchUpInside)
        performanceButton.translatesAutoresizingMaskIntoConstraints = false
        performanceButton.alpha = 0 // For animation
        contentView.addSubview(performanceButton)
        
        // ✨ Enhancement: Press animation
        addPressAnimation(to: performanceButton)
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            statsContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            statsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsContainer.heightAnchor.constraint(equalToConstant: 140),
            
            ticketsCard.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            ticketsCard.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor),
            ticketsCard.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor),
            ticketsCard.widthAnchor.constraint(equalTo: statsContainer.widthAnchor, multiplier: 0.485),
            
            resolutionCard.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            resolutionCard.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor),
            resolutionCard.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor),
            resolutionCard.widthAnchor.constraint(equalTo: statsContainer.widthAnchor, multiplier: 0.485),
            
            monthSelectorButton.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 28),
            monthSelectorButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            monthSelectorButton.heightAnchor.constraint(equalToConstant: 44),
            monthSelectorButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            
            locationsContainer.topAnchor.constraint(equalTo: monthSelectorButton.bottomAnchor, constant: 28),
            locationsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            performanceButton.topAnchor.constraint(equalTo: locationsContainer.bottomAnchor, constant: 28),
            performanceButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            performanceButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            performanceButton.heightAnchor.constraint(equalToConstant: 56),
            performanceButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    // MARK: - ✨ Enhancements - Animations
    
    func animateEntranceSequence() {
        let elements: [(view: UIView, delay: TimeInterval)] = [
            (ticketsCard, 0.1),
            (resolutionCard, 0.2),
            (monthSelectorButton, 0.3),
            (locationsContainer, 0.4),
            (performanceButton, 0.5)
        ]
        
        for (view, delay) in elements {
            view.transform = CGAffineTransform(translationX: 0, y: 20)
            
            UIView.animate(withDuration: 0.6, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
                view.alpha = 1
                view.transform = .identity
            }
        }
    }
    
    func addTapAnimation(to button: UIButton) {
        button.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    func addPressAnimation(to button: UIButton) {
        button.addTarget(self, action: #selector(buttonPressDown), for: .touchDown)
        button.addTarget(self, action: #selector(buttonPressUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    @objc func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            sender.layer.borderColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1).cgColor
        }
    }
    
    @objc func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0) {
            sender.transform = .identity
            sender.layer.borderColor = UIColor.systemGray5.cgColor
        }
    }
    
    @objc func buttonPressDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            sender.layer.shadowOpacity = 0.15
        }
    }
    
    @objc func buttonPressUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0) {
            sender.transform = CGAffineTransform(scaleX: 1.01, y: 1.01)
            sender.layer.shadowOpacity = 0.25
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                sender.transform = .identity
            }
        }
    }
    
    // MARK: - Data Fetching
    
    func fetchStatistics() {
        db.collection("Feedback").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error fetching statistics: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            let totalTickets = documents.count
            
            var totalResolutionMinutes: Double = 0
            var resolvedCount = 0
            
            for doc in documents {
                let data = doc.data()
                if let status = data["status"] as? String,
                   status.lowercased().contains("resolve") || status.lowercased().contains("complete"),
                   let dateSubmitted = data["date_submitted"] as? String,
                   let responseDate = data["response_date"] as? String {
                    
                    let formatter = ISO8601DateFormatter()
                    if let submitted = formatter.date(from: dateSubmitted),
                       let responded = formatter.date(from: responseDate) {
                        let minutes = responded.timeIntervalSince(submitted) / 60
                        totalResolutionMinutes += minutes
                        resolvedCount += 1
                    }
                }
            }
            
            let avgMinutes = resolvedCount > 0 ? totalResolutionMinutes / Double(resolvedCount) : 323
            let hours = Int(avgMinutes / 60)
            let minutes = Int(avgMinutes.truncatingRemainder(dividingBy: 60))
            
            self.generateChartData(from: documents)
            
            DispatchQueue.main.async {
                self.ticketsCard.configure(
                    title: "Estimated tickets per month",
                    value: "\(totalTickets) tickets",
                    subtitle: "+30% increase this month",
                    isPositive: true
                )
                
                self.resolutionCard.configure(
                    title: "Average resolution time",
                    value: "\(hours)h \(minutes)m",
                    subtitle: "+3% increase this month",
                    isPositive: true
                )
            }
            
            self.fetchLocationStatistics(from: documents)
        }
    }
    
    func generateChartData(from documents: [QueryDocumentSnapshot]) {
        var dailyCounts: [Int] = Array(repeating: 0, count: 31)
        
        let calendar = Calendar.current
        let formatter = ISO8601DateFormatter()
        
        for doc in documents {
            let data = doc.data()
            if let dateString = data["date_submitted"] as? String,
               let date = formatter.date(from: dateString) {
                let day = calendar.component(.day, from: date)
                if day >= 1 && day <= 31 {
                    dailyCounts[day - 1] += 1
                }
            }
        }
        
        var cumulativeData: [CGFloat] = []
        var sum: CGFloat = 0
        for count in dailyCounts {
            sum += CGFloat(count)
            cumulativeData.append(sum)
        }
        
        if cumulativeData.allSatisfy({ $0 == 0 }) {
            cumulativeData = (1...31).map { day in
                let base = CGFloat(day) * 1.5
                let variation = CGFloat.random(in: -2...3)
                return base + variation
            }
        }
        
        DispatchQueue.main.async {
            self.chartData = cumulativeData
            self.chartView.dataPoints = cumulativeData
            self.chartView.monthLabel = self.currentMonth
        }
    }
    
    func fetchLocationStatistics(from documents: [QueryDocumentSnapshot]) {
        var locationCounts: [String: Int] = [:]
        
        for doc in documents {
            let data = doc.data()
            if let campus = data["campus"] as? String {
                locationCounts[campus, default: 0] += 1
            }
        }
        
        let sortedLocations = locationCounts.sorted { $0.value > $1.value }
        let topLocations = Array(sortedLocations.prefix(5))
        
        DispatchQueue.main.async {
            self.locationsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            if topLocations.isEmpty {
                let defaultLocations = ["Campus A, B19", "Campus A, B5", "Campus A, B36", "Campus B, B20", "Campus B, B25"]
                for location in defaultLocations {
                    let locationView = self.createEnhancedLocationView(text: location)
                    self.locationsStackView.addArrangedSubview(locationView)
                }
            } else {
                for (location, _) in topLocations {
                    let locationView = self.createEnhancedLocationView(text: location)
                    self.locationsStackView.addArrangedSubview(locationView)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc func monthSelectorTapped() {
        let monthPickerVC = MonthPickerViewController()
        monthPickerVC.modalPresentationStyle = .overFullScreen
        monthPickerVC.modalTransitionStyle = .crossDissolve
        monthPickerVC.selectedMonth = currentMonth
        monthPickerVC.onMonthSelected = { [weak self] selectedMonth in
            self?.currentMonth = selectedMonth
            self?.monthSelectorButton.setTitle(selectedMonth, for: .normal)
            self?.chartView.monthLabel = selectedMonth
            self?.fetchStatistics()
        }
        present(monthPickerVC, animated: true)
    }
    
    @objc func performanceButtonTapped() {
        print("View Technician Performance tapped")
        let alert = UIAlertController(title: "Feature Coming Soon", message: "Technician performance analytics will be available soon.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Enhanced Stat Card View

class StatCardView: UIView {
    
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let accentBar = UIView()
    private var hotBadge: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 20 // More rounded
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray6.cgColor
        
        // ✨ Enhancement: Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.06
        
        // ✨ Enhancement: Accent bar (hidden by default)
        accentBar.backgroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1)
        accentBar.layer.cornerRadius = 2
        accentBar.alpha = 0
        accentBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(accentBar)
        
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        valueLabel.font = .systemFont(ofSize: 28, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(valueLabel)
        
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            accentBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            accentBar.topAnchor.constraint(equalTo: topAnchor),
            accentBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            accentBar.widthAnchor.constraint(equalToConstant: 4),
            
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            
            subtitleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -18)
        ])
        
        // ✨ Enhancement: Tap gesture for interaction
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tapGesture)
    }
    
    // ✨ Enhancement: Add HOT badge
    func addHotBadge() {
        let badge = UILabel()
        badge.text = "HOT"
        badge.font = .systemFont(ofSize: 10, weight: .bold)
        badge.textColor = .white
        badge.backgroundColor = UIColor.systemGreen
        badge.textAlignment = .center
        badge.layer.cornerRadius = 8
        badge.layer.masksToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badge)
        
        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            badge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            badge.widthAnchor.constraint(equalToConstant: 38),
            badge.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        hotBadge = badge
    }
    
    @objc private func cardTapped() {
        // ✨ Enhancement: Show accent bar on tap
        UIView.animate(withDuration: 0.3) {
            self.accentBar.alpha = self.accentBar.alpha == 0 ? 1 : 0
        }
        
        // Scale animation
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0) {
                self.transform = .identity
            }
        }
    }
    
    func configure(title: String, value: String, subtitle: String, isPositive: Bool) {
        titleLabel.text = title
        valueLabel.text = value
        subtitleLabel.text = subtitle
        
        // ✨ Enhancement: Color-coded with arrow
        let arrow = isPositive ? "↑ " : "↓ "
        subtitleLabel.text = arrow + subtitle
        subtitleLabel.textColor = isPositive ? .systemGreen : .systemRed
    }
}

// MARK: - Line Chart View (Keep existing implementation with enhancements)

class LineChartView: UIView {
    
    var dataPoints: [CGFloat] = [] {
        didSet {
            setNeedsDisplay()
            drawChart()
        }
    }
    
    var monthLabel: String = "October 2025" {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private let lineLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()
    private let dotsLayer = CALayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        
        gradientLayer.colors = [
            UIColor(red: 74/255, green: 158/255, blue: 255/255, alpha: 0.4).cgColor,
            UIColor(red: 74/255, green: 158/255, blue: 255/255, alpha: 0.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gradientLayer)
        
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.strokeColor = UIColor(red: 74/255, green: 158/255, blue: 255/255, alpha: 1).cgColor
        lineLayer.lineWidth = 3
        lineLayer.lineCap = .round
        lineLayer.lineJoin = .round
        layer.addSublayer(lineLayer)
        
        layer.addSublayer(dotsLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        drawChart()
    }
    
    private func drawChart() {
        guard !dataPoints.isEmpty else { return }
        
        let path = UIBezierPath()
        let gradientPath = UIBezierPath()
        
        let width = bounds.width
        let height = bounds.height - 50
        let spacing = width / CGFloat(dataPoints.count - 1)
        
        let maxValue = dataPoints.max() ?? 1
        let minValue = dataPoints.min() ?? 0
        let range = maxValue - minValue
        
        var points: [CGPoint] = []
        
        for (index, value) in dataPoints.enumerated() {
            let x = spacing * CGFloat(index)
            let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
            let y = height - (normalizedValue * height * 0.75) - (height * 0.1)
            points.append(CGPoint(x: x, y: y))
        }
        
        if points.count > 0 {
            path.move(to: points[0])
            gradientPath.move(to: CGPoint(x: points[0].x, y: height))
            gradientPath.addLine(to: points[0])
            
            for i in 1..<points.count {
                let currentPoint = points[i]
                let previousPoint = points[i-1]
                
                let controlPoint1 = CGPoint(
                    x: previousPoint.x + (currentPoint.x - previousPoint.x) * 0.5,
                    y: previousPoint.y
                )
                let controlPoint2 = CGPoint(
                    x: previousPoint.x + (currentPoint.x - previousPoint.x) * 0.5,
                    y: currentPoint.y
                )
                
                path.addCurve(to: currentPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
                gradientPath.addCurve(to: currentPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
            }
        }
        
        if let lastPoint = points.last {
            gradientPath.addLine(to: CGPoint(x: lastPoint.x, y: height))
            gradientPath.addLine(to: CGPoint(x: 0, y: height))
        }
        gradientPath.close()
        
        lineLayer.path = path.cgPath
        gradientLayer.mask = createGradientMaskLayer(path: gradientPath)
        
        drawLastDataPointDot(points: points)
    }
    
    private func drawLastDataPointDot(points: [CGPoint]) {
        dotsLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        guard let lastPoint = points.last else { return }
        
        let dotLayer = CAShapeLayer()
        let dotPath = UIBezierPath(arcCenter: lastPoint, radius: 5, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        dotLayer.path = dotPath.cgPath
        dotLayer.fillColor = UIColor(red: 74/255, green: 158/255, blue: 255/255, alpha: 1).cgColor
        dotLayer.strokeColor = UIColor.white.cgColor
        dotLayer.lineWidth = 3
        dotsLayer.addSublayer(dotLayer)
    }
    
    private func createGradientMaskLayer(path: UIBezierPath) -> CAShapeLayer {
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.white.cgColor
        return maskLayer
    }
    
    func animateChart() {
        lineLayer.removeAllAnimations()
        gradientLayer.removeAllAnimations()
        
        let lineAnimation = CABasicAnimation(keyPath: "strokeEnd")
        lineAnimation.fromValue = 0
        lineAnimation.toValue = 1
        lineAnimation.duration = 1.5
        lineAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        lineLayer.strokeEnd = 1
        lineLayer.add(lineAnimation, forKey: "lineAnimation")
        
        let gradientAnimation = CABasicAnimation(keyPath: "opacity")
        gradientAnimation.fromValue = 0
        gradientAnimation.toValue = 1
        gradientAnimation.duration = 1.5
        gradientAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        gradientLayer.opacity = 1
        gradientLayer.add(gradientAnimation, forKey: "gradientAnimation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            if let dotLayer = self.dotsLayer.sublayers?.first {
                let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
                scaleAnimation.fromValue = 0
                scaleAnimation.toValue = 1
                scaleAnimation.duration = 0.3
                scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
                dotLayer.add(scaleAnimation, forKey: "dotAnimation")
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard !dataPoints.isEmpty else { return }
        
        let height = rect.height - 50
        
        let dates = ["1", "5", "10", "15", "20", "25", "31"]
        let spacing = rect.width / CGFloat(dataPoints.count - 1)
        let labelIndices = [0, 5, 10, 15, 20, 25, 30]
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.tertiaryLabel,
            .paragraphStyle: paragraphStyle
        ]
        
        for (dateIndex, index) in labelIndices.enumerated() {
            if index < dataPoints.count && dateIndex < dates.count {
                let x = spacing * CGFloat(index)
                let dateString = dates[dateIndex] as NSString
                let labelRect = CGRect(x: x - 15, y: height + 8, width: 30, height: 15)
                dateString.draw(in: labelRect, withAttributes: attributes)
            }
        }
        
        let monthString = monthLabel as NSString
        let monthAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        let monthRect = CGRect(x: 0, y: height + 28, width: rect.width, height: 15)
        monthString.draw(in: monthRect, withAttributes: monthAttributes)
    }
}

// MARK: - Month Picker Modal View Controller

class MonthPickerViewController: UIViewController {
    
    var selectedMonth: String = "November 2025"
    var onMonthSelected: ((String) -> Void)?
    
    private let months = [
        "January 2025", "February 2025", "March 2025", "April 2025",
        "May 2025", "June 2025", "July 2025", "August 2025",
        "September 2025", "October 2025", "November 2025", "December 2025"
    ]
    
    private let monthShortNames = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]
    
    private let overlayView = UIView()
    private let modalContainer = UIView()
    private let titleLabel = UILabel()
    private let monthsCollectionView: UICollectionView
    private let yearLabel = UILabel()
    private let cancelButton = UIButton(type: .system)
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        monthsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }
    
    private func setupView() {
        view.backgroundColor = .clear
        
        // Overlay
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.alpha = 0
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissModal))
        overlayView.addGestureRecognizer(tapGesture)
        
        // Modal Container
        modalContainer.backgroundColor = .white
        modalContainer.layer.cornerRadius = 28
        modalContainer.layer.shadowColor = UIColor.black.cgColor
        modalContainer.layer.shadowOffset = CGSize(width: 0, height: 20)
        modalContainer.layer.shadowRadius = 30
        modalContainer.layer.shadowOpacity = 0.3
        modalContainer.transform = CGAffineTransform(translationX: 0, y: 50)
        modalContainer.alpha = 0
        modalContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(modalContainer)
        
        // Title
        titleLabel.text = "Select Month"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        modalContainer.addSubview(titleLabel)
        
        // Collection View
        monthsCollectionView.backgroundColor = .systemBackground
        monthsCollectionView.delegate = self
        monthsCollectionView.dataSource = self
        monthsCollectionView.register(MonthCell.self, forCellWithReuseIdentifier: "MonthCell")
        monthsCollectionView.showsVerticalScrollIndicator = false
        monthsCollectionView.isScrollEnabled = false
        monthsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        modalContainer.addSubview(monthsCollectionView)
        
        // Reload immediately
        monthsCollectionView.reloadData()
        
        // Year Label
        yearLabel.text = "2025"
        yearLabel.font = .systemFont(ofSize: 13, weight: .medium)
        yearLabel.textColor = .secondaryLabel
        yearLabel.textAlignment = .center
        yearLabel.translatesAutoresizingMaskIntoConstraints = false
        modalContainer.addSubview(yearLabel)
        
        // Cancel Button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.secondaryLabel, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        cancelButton.backgroundColor = UIColor.systemGray6
        cancelButton.layer.cornerRadius = 14
        cancelButton.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        modalContainer.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            modalContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            modalContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            modalContainer.widthAnchor.constraint(equalToConstant: 340),
            
            titleLabel.topAnchor.constraint(equalTo: modalContainer.topAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: modalContainer.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: modalContainer.trailingAnchor, constant: -24),
            
            monthsCollectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 28),
            monthsCollectionView.leadingAnchor.constraint(equalTo: modalContainer.leadingAnchor, constant: 24),
            monthsCollectionView.trailingAnchor.constraint(equalTo: modalContainer.trailingAnchor, constant: -24),
            monthsCollectionView.heightAnchor.constraint(equalToConstant: 280),
            
            yearLabel.topAnchor.constraint(equalTo: monthsCollectionView.bottomAnchor, constant: 16),
            yearLabel.leadingAnchor.constraint(equalTo: modalContainer.leadingAnchor, constant: 24),
            yearLabel.trailingAnchor.constraint(equalTo: modalContainer.trailingAnchor, constant: -24),
            
            cancelButton.topAnchor.constraint(equalTo: yearLabel.bottomAnchor, constant: 16),
            cancelButton.leadingAnchor.constraint(equalTo: modalContainer.leadingAnchor, constant: 24),
            cancelButton.trailingAnchor.constraint(equalTo: modalContainer.trailingAnchor, constant: -24),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.bottomAnchor.constraint(equalTo: modalContainer.bottomAnchor, constant: -24)
        ])
    }
    
    private func animateIn() {
        // Force layout update
        view.layoutIfNeeded()
        monthsCollectionView.reloadData()
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            self.overlayView.alpha = 1
            self.modalContainer.alpha = 1
            self.modalContainer.transform = .identity
        }
    }
    
    @objc private func dismissModal() {
        UIView.animate(withDuration: 0.3, animations: {
            self.overlayView.alpha = 0
            self.modalContainer.alpha = 0
            self.modalContainer.transform = CGAffineTransform(translationX: 0, y: 50)
        }) { _ in
            self.dismiss(animated: false)
        }
    }
}

// MARK: - Collection View Delegate & DataSource

extension MonthPickerViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MonthCell", for: indexPath) as! MonthCell
        print("📅 Creating cell for month: \(monthShortNames[indexPath.item])")
        cell.configure(
            monthName: monthShortNames[indexPath.item],
            isSelected: months[indexPath.item] == selectedMonth
        )
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing: CGFloat = 24 // 2 gaps of 12pt
        let availableWidth = collectionView.bounds.width - totalSpacing
        let itemWidth = floor(availableWidth / 3)
        print("📐 Cell size: \(itemWidth) x 64, collection width: \(collectionView.bounds.width)")
        return CGSize(width: itemWidth, height: 64)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedMonthName = months[indexPath.item]
        onMonthSelected?(selectedMonthName)
        
        // Update selection
        selectedMonth = selectedMonthName
        collectionView.reloadData()
        
        // Dismiss after selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.dismissModal()
        }
    }
}

// MARK: - Month Cell

class MonthCell: UICollectionViewCell {
    
    private let containerView = UIView()
    private let monthLabel = UILabel()
    private let checkmarkView = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        // Container with gradient
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1).cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Month Label
        monthLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        monthLabel.textColor = .white
        monthLabel.textAlignment = .center
        monthLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(monthLabel)
        
        // Checkmark
        checkmarkView.text = "✓"
        checkmarkView.font = .systemFont(ofSize: 10, weight: .bold)
        checkmarkView.textColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1)
        checkmarkView.textAlignment = .center
        checkmarkView.backgroundColor = .white
        checkmarkView.layer.cornerRadius = 9
        checkmarkView.layer.masksToBounds = true
        checkmarkView.alpha = 0
        checkmarkView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(checkmarkView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            monthLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            monthLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            checkmarkView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            checkmarkView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),
            checkmarkView.widthAnchor.constraint(equalToConstant: 18),
            checkmarkView.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    
    func configure(monthName: String, isSelected: Bool) {
        monthLabel.text = monthName
        
        if isSelected {
            // Orange gradient for selected
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1).cgColor,
                UIColor(red: 232/255, green: 149/255, blue: 16/255, alpha: 1).cgColor
            ]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            gradientLayer.frame = containerView.bounds
            gradientLayer.cornerRadius = 16
            
            containerView.layer.sublayers?.forEach { if $0 is CAGradientLayer { $0.removeFromSuperlayer() } }
            containerView.layer.insertSublayer(gradientLayer, at: 0)
            
            containerView.layer.shadowOpacity = 0.3
            checkmarkView.alpha = 1
            
            // Scale animation
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0) {
                self.containerView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }
        } else {
            // Navy blue gradient for unselected
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1).cgColor,
                UIColor(red: 0/255, green: 61/255, blue: 94/255, alpha: 1).cgColor
            ]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            gradientLayer.frame = containerView.bounds
            gradientLayer.cornerRadius = 16
            
            containerView.layer.sublayers?.forEach { if $0 is CAGradientLayer { $0.removeFromSuperlayer() } }
            containerView.layer.insertSublayer(gradientLayer, at: 0)
            
            containerView.layer.shadowOpacity = 0.2
            checkmarkView.alpha = 0
            containerView.transform = .identity
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Update gradient frame when cell is laid out
        if let gradientLayer = containerView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = containerView.bounds
        }
    }
}
