//
//  StatisticsViewController.swift
//  Statistics dashboard with animated line chart matching design
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
    
    // Locations Section
    private let locationsLabel = UILabel()
    private let locationsStackView = UIStackView()
    
    // Chart
    private let chartView = LineChartView()
    
    // Performance Button
    private let performanceButton = UIButton(type: .system)
    
    // MARK: - Data
    private var chartData: [CGFloat] = [12, 15, 13, 18, 16, 20, 19, 22, 21, 25, 23, 27, 26, 30, 28, 32, 31, 35, 33, 37, 36, 40, 38, 42, 41, 45, 43, 47, 46, 50, 52]
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Statistics"
        view.backgroundColor = .systemBackground
        
        setupScrollView()
        setupStatsCards()
        setupMonthSelector()
        setupLocationsSection()
        setupChart()
        setupPerformanceButton()
        setupConstraints()
        
        // Fetch real data from Firebase
        fetchStatistics()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Animate chart after view appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
            subtitle: "1% increase this month",
            isPositive: true
        )
        ticketsCard.translatesAutoresizingMaskIntoConstraints = false
        statsContainer.addSubview(ticketsCard)
        
        // Resolution Card
        resolutionCard.configure(
            title: "Average resolution time",
            value: "5h 23m",
            subtitle: "2% decrease this month",
            isPositive: true
        )
        resolutionCard.translatesAutoresizingMaskIntoConstraints = false
        statsContainer.addSubview(resolutionCard)
    }
    
    func setupMonthSelector() {
        monthSelectorButton.setTitle("October 2025", for: .normal)
        monthSelectorButton.setTitleColor(.label, for: .normal)
        monthSelectorButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        monthSelectorButton.backgroundColor = .secondarySystemBackground
        monthSelectorButton.layer.cornerRadius = 12
        monthSelectorButton.contentHorizontalAlignment = .center
        monthSelectorButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        
        // Add dropdown arrow
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        let arrowImage = UIImage(systemName: "chevron.down", withConfiguration: config)
        monthSelectorButton.setImage(arrowImage, for: .normal)
        monthSelectorButton.tintColor = .label
        monthSelectorButton.semanticContentAttribute = .forceRightToLeft
        monthSelectorButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        
        monthSelectorButton.addTarget(self, action: #selector(monthSelectorTapped), for: .touchUpInside)
        monthSelectorButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(monthSelectorButton)
    }
    
    func setupLocationsSection() {
        locationsLabel.text = "Location where most issues occurred"
        locationsLabel.font = .systemFont(ofSize: 14, weight: .medium)
        locationsLabel.textColor = .secondaryLabel
        locationsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(locationsLabel)
        
        locationsStackView.axis = .vertical
        locationsStackView.spacing = 8
        locationsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(locationsStackView)
        
        // Add location items
        let locations = ["Campus A: B16", "Campus A: B16", "Campus A: B38", "Campus A: B20"]
        for location in locations {
            let locationLabel = createLocationLabel(text: location)
            locationsStackView.addArrangedSubview(locationLabel)
        }
    }
    
    func createLocationLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }
    
    func setupChart() {
        chartView.dataPoints = chartData
        chartView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chartView)
    }
    
    func setupPerformanceButton() {
        performanceButton.setTitle("View Technician Performance", for: .normal)
        performanceButton.setTitleColor(.white, for: .normal)
        performanceButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        performanceButton.backgroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1) // #00476F
        performanceButton.layer.cornerRadius = 12
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
            statsContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            statsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsContainer.heightAnchor.constraint(equalToConstant: 90),
            
            // Tickets Card (Left)
            ticketsCard.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            ticketsCard.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor),
            ticketsCard.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor),
            ticketsCard.widthAnchor.constraint(equalTo: statsContainer.widthAnchor, multiplier: 0.48),
            
            // Resolution Card (Right)
            resolutionCard.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            resolutionCard.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor),
            resolutionCard.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor),
            resolutionCard.widthAnchor.constraint(equalTo: statsContainer.widthAnchor, multiplier: 0.48),
            
            // Month Selector
            monthSelectorButton.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 24),
            monthSelectorButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            monthSelectorButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            monthSelectorButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Locations Label
            locationsLabel.topAnchor.constraint(equalTo: monthSelectorButton.bottomAnchor, constant: 24),
            locationsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Locations Stack
            locationsStackView.topAnchor.constraint(equalTo: locationsLabel.bottomAnchor, constant: 12),
            locationsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Chart
            chartView.topAnchor.constraint(equalTo: locationsStackView.bottomAnchor, constant: 24),
            chartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            chartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chartView.heightAnchor.constraint(equalToConstant: 220),
            
            // Performance Button
            performanceButton.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 24),
            performanceButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            performanceButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            performanceButton.heightAnchor.constraint(equalToConstant: 50),
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
            
            let avgMinutes = resolvedCount > 0 ? totalResolutionMinutes / Double(resolvedCount) : 0
            let hours = Int(avgMinutes / 60)
            let minutes = Int(avgMinutes.truncatingRemainder(dividingBy: 60))
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.ticketsCard.configure(
                    title: "Estimated tickets per month",
                    value: "\(totalTickets) tickets",
                    subtitle: "Based on current data",
                    isPositive: true
                )
                
                self.resolutionCard.configure(
                    title: "Average resolution time",
                    value: "\(hours)h \(minutes)m",
                    subtitle: "Average response time",
                    isPositive: true
                )
            }
            
            // Fetch location statistics
            self.fetchLocationStatistics(from: documents)
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
        let topLocations = Array(sortedLocations.prefix(4))
        
        DispatchQueue.main.async {
            self.locationsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            for (location, count) in topLocations {
                let label = self.createLocationLabel(text: "\(location): \(count) issues")
                self.locationsStackView.addArrangedSubview(label)
            }
            
            if topLocations.isEmpty {
                let label = self.createLocationLabel(text: "No location data available")
                self.locationsStackView.addArrangedSubview(label)
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
                self?.monthSelectorButton.setTitle(month, for: .normal)
                // You can add logic here to filter data by month
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
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        
        titleLabel.font = .systemFont(ofSize: 11)
        titleLabel.textColor = .secondaryLabel
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        valueLabel.font = .systemFont(ofSize: 20, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(valueLabel)
        
        subtitleLabel.font = .systemFont(ofSize: 10)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            
            subtitleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
    }
    
    func configure(title: String, value: String, subtitle: String, isPositive: Bool) {
        titleLabel.text = title
        valueLabel.text = value
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = isPositive ? .systemGreen : .systemRed
    }
}

// MARK: - Line Chart View with Smooth Animation

class LineChartView: UIView {
    
    var dataPoints: [CGFloat] = [] {
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
        
        // Setup gradient layer
        gradientLayer.colors = [
            UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 0.3).cgColor,
            UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 0.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gradientLayer)
        
        // Setup line layer
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.strokeColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1).cgColor
        lineLayer.lineWidth = 2.5
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
        let height = bounds.height - 40 // Leave space for labels
        let spacing = width / CGFloat(dataPoints.count - 1)
        
        let maxValue = dataPoints.max() ?? 1
        let minValue = dataPoints.min() ?? 0
        let range = maxValue - minValue
        
        var points: [CGPoint] = []
        
        // Calculate points
        for (index, value) in dataPoints.enumerated() {
            let x = spacing * CGFloat(index)
            let normalizedValue = (value - minValue) / range
            let y = height - (normalizedValue * height * 0.75) - (height * 0.15)
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
        
        // Add dots at data points (optional - remove if you don't want dots)
        drawDataPointDots(points: points)
    }
    
    private func drawDataPointDots(points: [CGPoint]) {
        dotsLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        // Only show dots at specific intervals
        let showDotInterval = 5
        for (index, point) in points.enumerated() where index % showDotInterval == 0 {
            let dotLayer = CAShapeLayer()
            let dotPath = UIBezierPath(arcCenter: point, radius: 3, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            dotLayer.path = dotPath.cgPath
            dotLayer.fillColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1).cgColor
            dotLayer.strokeColor = UIColor.white.cgColor
            dotLayer.lineWidth = 2
            dotsLayer.addSublayer(dotLayer)
        }
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
        
        // Animate dots
        dotsLayer.sublayers?.enumerated().forEach { index, layer in
            let delay = Double(index) * 0.05
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
                scaleAnimation.fromValue = 0
                scaleAnimation.toValue = 1
                scaleAnimation.duration = 0.3
                scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
                layer.add(scaleAnimation, forKey: "dotAnimation")
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard !dataPoints.isEmpty else { return }
        
        let height = rect.height - 40
        
        // Draw X-axis labels (dates)
        let dates = ["1", "5", "10", "15", "20", "25", "31"]
        let spacing = rect.width / CGFloat(dataPoints.count - 1)
        let labelIndices = [0, 5, 10, 15, 20, 25, 30]
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.secondaryLabel,
            .paragraphStyle: paragraphStyle
        ]
        
        for (dateIndex, index) in labelIndices.enumerated() {
            if index < dataPoints.count && dateIndex < dates.count {
                let x = spacing * CGFloat(index)
                let dateString = dates[dateIndex] as NSString
                let labelRect = CGRect(x: x - 15, y: height + 5, width: 30, height: 15)
                dateString.draw(in: labelRect, withAttributes: attributes)
            }
        }
        
        // Draw month label at bottom
        let monthString = "October 2025" as NSString
        let monthAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.tertiaryLabel,
            .paragraphStyle: paragraphStyle
        ]
        let monthRect = CGRect(x: 0, y: height + 22, width: rect.width, height: 15)
        monthString.draw(in: monthRect, withAttributes: monthAttributes)
    }
}
