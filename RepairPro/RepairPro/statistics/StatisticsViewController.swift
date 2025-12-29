//
//  StatisticsViewController.swift
//  Statistics dashboard with animated line chart
//

import UIKit

class StatisticsViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Stats Cards
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
    private let chartData: [CGFloat] = [12, 15, 13, 18, 16, 20, 19, 22, 21, 25, 23, 27, 26, 30, 28, 32, 31, 35, 33, 37, 36, 40, 38, 42, 41, 45, 43, 47, 46, 50, 52]
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Animate chart after view appears
        chartView.animateChart()
    }
    
    // MARK: - Setup Methods
    
    func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    func setupStatsCards() {
        // Tickets Card
        ticketsCard.configure(
            title: "Estimated tickets per month",
            value: "127 tickets",
            subtitle: "1% increase this month",
            isPositive: true
        )
        ticketsCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ticketsCard)
        
        // Resolution Card
        resolutionCard.configure(
            title: "Average resolution time",
            value: "5h 23m",
            subtitle: "2% decrease this month",
            isPositive: true
        )
        resolutionCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(resolutionCard)
    }
    
    func setupMonthSelector() {
        monthSelectorButton.setTitle("October 2025", for: .normal)
        monthSelectorButton.setTitleColor(.label, for: .normal)
        monthSelectorButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        monthSelectorButton.backgroundColor = .secondarySystemBackground
        monthSelectorButton.layer.cornerRadius = 12
        monthSelectorButton.contentHorizontalAlignment = .center
        
        // Add dropdown arrow
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
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
        let locations = ["Campus A: B16", "Campus A: B5", "Campus A: B38", "Campus A: B20"]
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
        performanceButton.backgroundColor = UIColor(red: 0/255, green: 72/255, blue: 111/255, alpha: 1)
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
            
            // Tickets Card
            ticketsCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            ticketsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            ticketsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            ticketsCard.heightAnchor.constraint(equalToConstant: 80),
            
            // Resolution Card
            resolutionCard.topAnchor.constraint(equalTo: ticketsCard.bottomAnchor, constant: 16),
            resolutionCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            resolutionCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            resolutionCard.heightAnchor.constraint(equalToConstant: 80),
            
            // Month Selector
            monthSelectorButton.topAnchor.constraint(equalTo: resolutionCard.bottomAnchor, constant: 24),
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
            chartView.topAnchor.constraint(equalTo: locationsStackView.bottomAnchor, constant: 20),
            chartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            chartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chartView.heightAnchor.constraint(equalToConstant: 200),
            
            // Performance Button
            performanceButton.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 24),
            performanceButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            performanceButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            performanceButton.heightAnchor.constraint(equalToConstant: 50),
            performanceButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
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
        
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        valueLabel.font = .systemFont(ofSize: 24, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(valueLabel)
        
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            subtitleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }
    
    func configure(title: String, value: String, subtitle: String, isPositive: Bool) {
        titleLabel.text = title
        valueLabel.text = value
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = isPositive ? .systemGreen : .systemRed
    }
}

// MARK: - Line Chart View with Animation

class LineChartView: UIView {
    
    var dataPoints: [CGFloat] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private let lineLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()
    
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
            UIColor.systemBlue.withAlphaComponent(0.3).cgColor,
            UIColor.systemBlue.withAlphaComponent(0.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gradientLayer)
        
        // Setup line layer
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.strokeColor = UIColor.systemBlue.cgColor
        lineLayer.lineWidth = 3
        lineLayer.lineCap = .round
        lineLayer.lineJoin = .round
        layer.addSublayer(lineLayer)
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
        let height = bounds.height
        let spacing = width / CGFloat(dataPoints.count - 1)
        
        let maxValue = dataPoints.max() ?? 1
        let minValue = dataPoints.min() ?? 0
        let range = maxValue - minValue
        
        // Draw line and gradient path
        for (index, value) in dataPoints.enumerated() {
            let x = spacing * CGFloat(index)
            let normalizedValue = (value - minValue) / range
            let y = height - (normalizedValue * height * 0.8) - (height * 0.1)
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
                gradientPath.move(to: CGPoint(x: x, y: height))
                gradientPath.addLine(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
                gradientPath.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        // Close gradient path
        gradientPath.addLine(to: CGPoint(x: width, y: height))
        gradientPath.close()
        
        // Set paths
        lineLayer.path = path.cgPath
        gradientLayer.mask = createGradientMaskLayer(path: gradientPath)
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
        
        // Create animation
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 1.5
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        lineLayer.strokeEnd = 1
        lineLayer.add(animation, forKey: "lineAnimation")
        
        // Animate gradient
        let gradientAnimation = CABasicAnimation(keyPath: "opacity")
        gradientAnimation.fromValue = 0
        gradientAnimation.toValue = 1
        gradientAnimation.duration = 1.5
        gradientAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        gradientLayer.opacity = 1
        gradientLayer.add(gradientAnimation, forKey: "gradientAnimation")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard !dataPoints.isEmpty else { return }
        
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
                let labelRect = CGRect(x: x - 15, y: rect.height - 20, width: 30, height: 20)
                dateString.draw(in: labelRect, withAttributes: attributes)
            }
        }
        
        // Draw month label
        let monthString = "October 2025" as NSString
        let monthAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        let monthRect = CGRect(x: 0, y: rect.height - 35, width: rect.width, height: 15)
        monthString.draw(in: monthRect, withAttributes: monthAttributes)
    }
}
