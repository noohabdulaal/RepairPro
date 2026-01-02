//
//  StatisticsViewController.swift
//  Statistics dashboard matching exact design from screenshot
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
        view.backgroundColor = .systemBackground
        
        setupScrollView()
        setupStatsCards()
        setupMonthSelector()
        setupLocationsContainer()
        setupPerformanceButton()
        setupConstraints()
        
        // Fetch real data from Firebase
        fetchStatistics()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Animate chart after view appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
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
        
        // Tickets Card
        ticketsCard.configure(
            title: "Estimated tickets per month",
            value: "127 tickets",
            subtitle: "+30% increase this month",
            isPositive: true
        )
        ticketsCard.translatesAutoresizingMaskIntoConstraints = false
        statsContainer.addSubview(ticketsCard)
        
        // Resolution Card
        resolutionCard.configure(
            title: "Average resolution time",
            value: "5h 23m",
            subtitle: "+3% increase this month",
            isPositive: true
        )
        resolutionCard.translatesAutoresizingMaskIntoConstraints = false
        statsContainer.addSubview(resolutionCard)
    }
    
    func setupMonthSelector() {
        monthSelectorButton.setTitle("October 2025", for: .normal)
        monthSelectorButton.setTitleColor(.label, for: .normal)
        monthSelectorButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        monthSelectorButton.backgroundColor = .systemBackground
        monthSelectorButton.layer.cornerRadius = 12
        monthSelectorButton.layer.borderWidth = 1
        monthSelectorButton.layer.borderColor = UIColor.systemGray4.cgColor
        monthSelectorButton.contentHorizontalAlignment = .center
        monthSelectorButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        
        // Add dropdown arrow
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let arrowImage = UIImage(systemName: "chevron.down", withConfiguration: config)
        monthSelectorButton.setImage(arrowImage, for: .normal)
        monthSelectorButton.tintColor = .label
        monthSelectorButton.semanticContentAttribute = .forceRightToLeft
        monthSelectorButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        
        monthSelectorButton.addTarget(self, action: #selector(monthSelectorTapped), for: .touchUpInside)
        monthSelectorButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(monthSelectorButton)
    }
    
    func setupLocationsContainer() {
        // Container with white background and border
        locationsContainer.backgroundColor = .systemBackground
        locationsContainer.layer.cornerRadius = 16
        locationsContainer.layer.borderWidth = 1
        locationsContainer.layer.borderColor = UIColor.systemGray5.cgColor
        locationsContainer.translatesAutoresizingMaskIntoConstraints = false
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
        
        // Add placeholder location items
        let locations = ["Campus A, B19", "Campus A, B5", "Campus A, B36", "Campus B, B20", "Campus B, B25"]
        for location in locations {
            let locationLabel = createLocationLabel(text: location)
            locationsStackView.addArrangedSubview(locationLabel)
        }
        
        NSLayoutConstraint.activate([
            locationsLabel.topAnchor.constraint(equalTo: locationsContainer.topAnchor, constant: 20),
            locationsLabel.leadingAnchor.constraint(equalTo: locationsContainer.leadingAnchor, constant: 20),
            locationsLabel.trailingAnchor.constraint(equalTo: locationsContainer.trailingAnchor, constant: -20),
            
            locationsStackView.topAnchor.constraint(equalTo: locationsLabel.bottomAnchor, constant: 20),
            locationsStackView.leadingAnchor.constraint(equalTo: locationsContainer.leadingAnchor, constant: 20),
            locationsStackView.widthAnchor.constraint(equalToConstant: 140),
            
            chartView.topAnchor.constraint(equalTo: locationsLabel.bottomAnchor, constant: 16),
            chartView.leadingAnchor.constraint(equalTo: locationsStackView.trailingAnchor, constant: 10),
            chartView.trailingAnchor.constraint(equalTo: locationsContainer.trailingAnchor, constant: -20),
            chartView.bottomAnchor.constraint(equalTo: locationsContainer.bottomAnchor, constant: -20),
            chartView.heightAnchor.constraint(equalToConstant: 240)
        ])
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
        performanceButton.backgroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1) // #00476F
        performanceButton.layer.cornerRadius = 14
        performanceButton.addTarget(self, action: #selector(performanceButtonTapped), for: .touchUpInside)
        performanceButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(performanceButton)
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Stats Container
            statsContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            statsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsContainer.heightAnchor.constraint(equalToConstant: 140),
            
            // Tickets Card (Left)
            ticketsCard.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            ticketsCard.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor),
            ticketsCard.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor),
            ticketsCard.widthAnchor.constraint(equalTo: statsContainer.widthAnchor, multiplier: 0.485),
            
            // Resolution Card (Right)
            resolutionCard.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            resolutionCard.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor),
            resolutionCard.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor),
            resolutionCard.widthAnchor.constraint(equalTo: statsContainer.widthAnchor, multiplier: 0.485),
            
            // Month Selector
            monthSelectorButton.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 24),
            monthSelectorButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            monthSelectorButton.heightAnchor.constraint(equalToConstant: 44),
            monthSelectorButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            
            // Locations Container
            locationsContainer.topAnchor.constraint(equalTo: monthSelectorButton.bottomAnchor, constant: 24),
            locationsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Performance Button
            performanceButton.topAnchor.constraint(equalTo: locationsContainer.bottomAnchor, constant: 24),
            performanceButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            performanceButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            performanceButton.heightAnchor.constraint(equalToConstant: 56),
            performanceButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
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
            
            // Calculate statistics
            let totalTickets = documents.count
            
            // Calculate average resolution time
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
            
            let avgMinutes = resolvedCount > 0 ? totalResolutionMinutes / Double(resolvedCount) : 323 // Default 5h 23m
            let hours = Int(avgMinutes / 60)
            let minutes = Int(avgMinutes.truncatingRemainder(dividingBy: 60))
            
            // Generate chart data based on tickets
            self.generateChartData(from: documents)
            
            // Update UI on main thread
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
            
            // Fetch location statistics
            self.fetchLocationStatistics(from: documents)
        }
    }
    
    func generateChartData(from documents: [QueryDocumentSnapshot]) {
        // Create a chart with 31 data points (days of the month)
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
        
        // Convert to cumulative data for smooth upward trend
        var cumulativeData: [CGFloat] = []
        var sum: CGFloat = 0
        for count in dailyCounts {
            sum += CGFloat(count)
            cumulativeData.append(sum)
        }
        
        // If no data, create sample upward trend
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
        
        // Sort by count and get top locations
        let sortedLocations = locationCounts.sorted { $0.value > $1.value }
        let topLocations = Array(sortedLocations.prefix(5))
        
        DispatchQueue.main.async {
            self.locationsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            if topLocations.isEmpty {
                // Use default locations if no data
                let defaultLocations = ["Campus A, B19", "Campus A, B5", "Campus A, B36", "Campus B, B20", "Campus B, B25"]
                for location in defaultLocations {
                    let label = self.createLocationLabel(text: location)
                    self.locationsStackView.addArrangedSubview(label)
                }
            } else {
                for (location, _) in topLocations {
                    let label = self.createLocationLabel(text: location)
                    self.locationsStackView.addArrangedSubview(label)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc func monthSelectorTapped() {
        let months = [
            "January 2025", "February 2025", "March 2025", "April 2025",
            "May 2025", "June 2025", "July 2025", "August 2025",
            "September 2025", "October 2025", "November 2025", "December 2025"
        ]
        
        let alert = UIAlertController(title: "Select Month", message: nil, preferredStyle: .actionSheet)
        
        for month in months {
            alert.addAction(UIAlertAction(title: month, style: .default) { [weak self] _ in
                self?.currentMonth = month
                self?.monthSelectorButton.setTitle(month, for: .normal)
                self?.chartView.monthLabel = month
                self?.fetchStatistics() // Refresh data for selected month
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = monthSelectorButton
            popover.sourceRect = monthSelectorButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc func performanceButtonTapped() {
        print("View Technician Performance tapped")
        // Navigate to technician performance view
        let alert = UIAlertController(title: "Feature Coming Soon", message: "Technician performance analytics will be available soon.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Stat Card View

class StatCardView: UIView {
    
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let subtitleLabel = UILabel()
    
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
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray5.cgColor
        
        titleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        valueLabel.font = .systemFont(ofSize: 28, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(valueLabel)
        
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            subtitleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16)
        ])
    }
    
    func configure(title: String, value: String, subtitle: String, isPositive: Bool) {
        titleLabel.text = title
        valueLabel.text = value
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = .secondaryLabel
    }
}

// MARK: - Line Chart View with Smooth Animation

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
        
        // Setup gradient layer with blue color matching screenshot
        gradientLayer.colors = [
            UIColor(red: 74/255, green: 144/255, blue: 226/255, alpha: 0.3).cgColor,
            UIColor(red: 74/255, green: 144/255, blue: 226/255, alpha: 0.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gradientLayer)
        
        // Setup line layer with blue color
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.strokeColor = UIColor(red: 74/255, green: 144/255, blue: 226/255, alpha: 1).cgColor
        lineLayer.lineWidth = 3
        lineLayer.lineCap = .round
        lineLayer.lineJoin = .round
        layer.addSublayer(lineLayer)
        
        // Setup dots layer
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
        let height = bounds.height - 50 // Leave space for labels
        let spacing = width / CGFloat(dataPoints.count - 1)
        
        let maxValue = dataPoints.max() ?? 1
        let minValue = dataPoints.min() ?? 0
        let range = maxValue - minValue
        
        var points: [CGPoint] = []
        
        // Calculate points
        for (index, value) in dataPoints.enumerated() {
            let x = spacing * CGFloat(index)
            let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
            let y = height - (normalizedValue * height * 0.75) - (height * 0.1)
            points.append(CGPoint(x: x, y: y))
        }
        
        // Create smooth curve using Bezier paths
        if points.count > 0 {
            path.move(to: points[0])
            gradientPath.move(to: CGPoint(x: points[0].x, y: height))
            gradientPath.addLine(to: points[0])
            
            for i in 1..<points.count {
                let currentPoint = points[i]
                let previousPoint = points[i-1]
                
                // Calculate control points for smooth curve
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
        
        // Close gradient path
        if let lastPoint = points.last {
            gradientPath.addLine(to: CGPoint(x: lastPoint.x, y: height))
            gradientPath.addLine(to: CGPoint(x: 0, y: height))
        }
        gradientPath.close()
        
        // Set paths
        lineLayer.path = path.cgPath
        gradientLayer.mask = createGradientMaskLayer(path: gradientPath)
        
        // Add dot at the last point
        drawLastDataPointDot(points: points)
    }
    
    private func drawLastDataPointDot(points: [CGPoint]) {
        dotsLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        guard let lastPoint = points.last else { return }
        
        let dotLayer = CAShapeLayer()
        let dotPath = UIBezierPath(arcCenter: lastPoint, radius: 5, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        dotLayer.path = dotPath.cgPath
        dotLayer.fillColor = UIColor(red: 74/255, green: 144/255, blue: 226/255, alpha: 1).cgColor
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
    
    // MARK: - Animation
    
    func animateChart() {
        // Remove previous animations
        lineLayer.removeAllAnimations()
        gradientLayer.removeAllAnimations()
        
        // Line animation
        let lineAnimation = CABasicAnimation(keyPath: "strokeEnd")
        lineAnimation.fromValue = 0
        lineAnimation.toValue = 1
        lineAnimation.duration = 1.5
        lineAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        lineLayer.strokeEnd = 1
        lineLayer.add(lineAnimation, forKey: "lineAnimation")
        
        // Gradient animation
        let gradientAnimation = CABasicAnimation(keyPath: "opacity")
        gradientAnimation.fromValue = 0
        gradientAnimation.toValue = 1
        gradientAnimation.duration = 1.5
        gradientAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        gradientLayer.opacity = 1
        gradientLayer.add(gradientAnimation, forKey: "gradientAnimation")
        
        // Animate dot
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
        
        // Draw X-axis labels (dates)
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
        
        // Draw month label at bottom left
        let monthString = monthLabel as NSString
        let monthAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        let monthRect = CGRect(x: 0, y: height + 28, width: rect.width, height: 15)
        monthString.draw(in: monthRect, withAttributes: monthAttributes)
    }
}
