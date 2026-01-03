//
//  StatisticsViewController.swift
//  Only January 2025 uses Firebase - Other months use mock data
//

import UIKit
import FirebaseFirestore

class StatisticsViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let statsContainer = UIView()
    private let ticketsCard = StatCardView()
    private let resolutionCard = StatCardView()
    private let monthSelectorButton = UIButton(type: .system)
    private let locationsContainer = UIView()
    private let locationsLabel = UILabel()
    private let locationsStackView = UIStackView()
    private let chartView = LineChartView()
    private let performanceButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Data
    private var chartData: [CGFloat] = []
    private let db = Firestore.firestore()
    private var currentMonth = "October 2025"
    private var totalTickets = 0
    private var previousMonthTickets = 0
    private var avgResolutionMinutes: Double = 0
    private var previousAvgResolutionMinutes: Double = 0
    
    // MARK: - Mock Data Structure
    struct MonthData {
        let tickets: Int
        let avgResolutionMinutes: Double
        let locations: [(String, Int)]
        let dailyPattern: [Int] // Pattern for generating chart data
    }
    
    // Mock data for each month (except January which uses Firebase)
    private let mockData: [String: MonthData] = [
        "February": MonthData(
            tickets: 145,
            avgResolutionMinutes: 298, // 4h 58m
            locations: [
                ("Campus B, B25", 42),
                ("Campus A, B19", 38),
                ("Campus A, B5", 31),
                ("Campus B, B20", 22),
                ("Campus A, B36", 12)
            ],
            dailyPattern: [3, 4, 5, 6, 4, 5, 6, 5, 4, 6, 5, 4, 5, 6, 7, 5, 4, 5, 6, 5, 6, 5, 4, 6, 5, 4, 5, 4] // Total: 138, scales to 145
        ),
        "March": MonthData(
            tickets: 167,
            avgResolutionMinutes: 285, // 4h 45m
            locations: [
                ("Campus A, B19", 51),
                ("Campus B, B25", 44),
                ("Campus A, B5", 35),
                ("Campus B, B20", 23),
                ("Campus A, B36", 14)
            ],
            dailyPattern: [4, 5, 6, 7, 5, 6, 7, 6, 5, 6, 7, 5, 6, 7, 8, 6, 5, 6, 7, 6, 5, 6, 7, 5, 4, 5, 6, 5, 4, 5, 6] // Total: 180, scales to 167
        ),
        "April": MonthData(
            tickets: 142,
            avgResolutionMinutes: 310, // 5h 10m
            locations: [
                ("Campus A, B5", 43),
                ("Campus A, B19", 39),
                ("Campus B, B25", 28),
                ("Campus B, B20", 21),
                ("Campus A, B36", 11)
            ],
            dailyPattern: [3, 4, 5, 4, 5, 4, 3, 5, 6, 5, 4, 5, 6, 5, 4, 5, 4, 5, 6, 5, 4, 5, 4, 3, 5, 4, 5, 4, 5, 4] // Total: 135, scales to 142
        ),
        "May": MonthData(
            tickets: 189,
            avgResolutionMinutes: 267, // 4h 27m
            locations: [
                ("Campus A, B19", 58),
                ("Campus A, B5", 49),
                ("Campus B, B25", 37),
                ("Campus B, B20", 28),
                ("Campus A, B36", 17)
            ],
            dailyPattern: [5, 6, 7, 8, 6, 7, 8, 7, 6, 7, 8, 6, 7, 8, 9, 7, 6, 7, 8, 7, 6, 7, 8, 6, 5, 6, 7, 6, 5, 6, 7] // Total: 210, scales to 189
        ),
        "June": MonthData(
            tickets: 156,
            avgResolutionMinutes: 295, // 4h 55m
            locations: [
                ("Campus B, B20", 47),
                ("Campus A, B19", 41),
                ("Campus A, B5", 34),
                ("Campus B, B25", 23),
                ("Campus A, B36", 11)
            ],
            dailyPattern: [4, 5, 6, 5, 6, 5, 4, 6, 7, 6, 5, 6, 7, 6, 5, 6, 5, 6, 7, 6, 5, 6, 5, 4, 5, 6, 5, 4, 5, 5] // Total: 163, scales to 156
        ),
        "July": MonthData(
            tickets: 134,
            avgResolutionMinutes: 318, // 5h 18m
            locations: [
                ("Campus A, B5", 41),
                ("Campus A, B19", 36),
                ("Campus B, B25", 27),
                ("Campus B, B20", 19),
                ("Campus A, B36", 11)
            ],
            dailyPattern: [2, 3, 4, 5, 4, 3, 4, 5, 4, 3, 4, 5, 6, 5, 4, 3, 4, 5, 4, 5, 4, 3, 4, 5, 4, 5, 4, 5, 4, 5, 4] // Total: 129, scales to 134
        ),
        "August": MonthData(
            tickets: 178,
            avgResolutionMinutes: 278, // 4h 38m
            locations: [
                ("Campus A, B19", 55),
                ("Campus B, B25", 46),
                ("Campus A, B5", 38),
                ("Campus B, B20", 25),
                ("Campus A, B36", 14)
            ],
            dailyPattern: [5, 6, 7, 6, 7, 6, 5, 7, 8, 7, 6, 7, 8, 7, 6, 7, 6, 7, 8, 7, 6, 7, 6, 5, 6, 7, 6, 5, 6, 6, 5] // Total: 200, scales to 178
        ),
        "September": MonthData(
            tickets: 163,
            avgResolutionMinutes: 305, // 5h 5m
            locations: [
                ("Campus B, B25", 49),
                ("Campus A, B19", 43),
                ("Campus A, B5", 35),
                ("Campus B, B20", 24),
                ("Campus A, B36", 12)
            ],
            dailyPattern: [4, 5, 6, 5, 6, 5, 6, 7, 6, 5, 6, 7, 6, 5, 6, 5, 6, 7, 6, 5, 6, 5, 6, 5, 4, 5, 6, 5, 6, 5] // Total: 168, scales to 163
        ),
        "October": MonthData(
            tickets: 127,
            avgResolutionMinutes: 323, // 5h 23m
            locations: [
                ("Campus A, B19", 38),
                ("Campus A, B5", 32),
                ("Campus A, B36", 26),
                ("Campus B, B20", 19),
                ("Campus B, B25", 12)
            ],
            dailyPattern: [2, 3, 4, 3, 4, 3, 4, 5, 4, 3, 4, 5, 4, 3, 4, 3, 4, 5, 4, 3, 4, 3, 4, 5, 4, 3, 4, 3, 4, 5, 4] // Total: 118, scales to 127
        ),
        "November": MonthData(
            tickets: 198,
            avgResolutionMinutes: 255, // 4h 15m
            locations: [
                ("Campus A, B19", 62),
                ("Campus A, B5", 51),
                ("Campus B, B25", 41),
                ("Campus B, B20", 29),
                ("Campus A, B36", 15)
            ],
            dailyPattern: [6, 7, 8, 7, 8, 7, 6, 8, 9, 8, 7, 8, 9, 8, 7, 8, 7, 8, 9, 8, 7, 8, 7, 6, 7, 8, 7, 6, 7, 7] // Total: 225, scales to 198
        ),
        "December": MonthData(
            tickets: 171,
            avgResolutionMinutes: 290, // 4h 50m
            locations: [
                ("Campus B, B20", 52),
                ("Campus A, B19", 45),
                ("Campus A, B5", 37),
                ("Campus B, B25", 25),
                ("Campus A, B36", 12)
            ],
            dailyPattern: [4, 5, 6, 7, 6, 5, 6, 7, 6, 5, 6, 7, 6, 5, 6, 5, 6, 7, 6, 5, 6, 5, 6, 5, 4, 5, 6, 5, 6, 5, 6] // Total: 177, scales to 171
        )
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Statistics"
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1)
        
        setupLoadingIndicator()
        setupScrollView()
        setupStatsCards()
        setupMonthSelector()
        setupLocationsContainer()
        setupPerformanceButton()
        setupConstraints()
        
        showLoading()
        fetchStatistics()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Setup Methods
    
    func setupLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = .systemGray
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func showLoading() {
        loadingIndicator.startAnimating()
        scrollView.alpha = 0
    }
    
    func hideLoading() {
        loadingIndicator.stopAnimating()
        UIView.animate(withDuration: 0.3) {
            self.scrollView.alpha = 1
        }
        animateEntranceSequence()
    }
    
    func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alpha = 0
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    func setupStatsCards() {
        statsContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statsContainer)
        
        ticketsCard.configure(title: "Estimated tickets per month", value: "Loading...", subtitle: "Calculating...", isPositive: true)
        ticketsCard.translatesAutoresizingMaskIntoConstraints = false
        ticketsCard.alpha = 0
        statsContainer.addSubview(ticketsCard)
        
        resolutionCard.configure(title: "Average resolution time", value: "Loading...", subtitle: "Calculating...", isPositive: true)
        resolutionCard.translatesAutoresizingMaskIntoConstraints = false
        resolutionCard.alpha = 0
        statsContainer.addSubview(resolutionCard)
    }
    
    func setupMonthSelector() {
        // Use modern UIButton.Configuration (iOS 15+) to avoid deprecation warnings
        var config = UIButton.Configuration.plain()
        config.title = "October 2025"
        config.baseForegroundColor = .label
        config.background.backgroundColor = .white
        config.background.cornerRadius = 12
        config.background.strokeColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        config.background.strokeWidth = 1
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        
        // Add chevron icon with spacing
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        let arrowImage = UIImage(systemName: "chevron.down", withConfiguration: imageConfig)
        config.image = arrowImage
        config.imagePlacement = .trailing  // Put image on the right
        config.imagePadding = 10  // Space between text and icon (replaces imageEdgeInsets)
        
        monthSelectorButton.configuration = config
        monthSelectorButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        
        // Shadow styling
        monthSelectorButton.layer.shadowColor = UIColor.black.cgColor
        monthSelectorButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        monthSelectorButton.layer.shadowRadius = 3
        monthSelectorButton.layer.shadowOpacity = 0.05
        
        monthSelectorButton.addTarget(self, action: #selector(monthSelectorTapped), for: .touchUpInside)
        monthSelectorButton.translatesAutoresizingMaskIntoConstraints = false
        monthSelectorButton.alpha = 0
        contentView.addSubview(monthSelectorButton)
    }
    
    func setupLocationsContainer() {
        locationsContainer.backgroundColor = .white
        locationsContainer.layer.cornerRadius = 16
        locationsContainer.layer.shadowColor = UIColor.black.cgColor
        locationsContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        locationsContainer.layer.shadowRadius = 8
        locationsContainer.layer.shadowOpacity = 0.06
        locationsContainer.translatesAutoresizingMaskIntoConstraints = false
        locationsContainer.alpha = 0
        contentView.addSubview(locationsContainer)
        
        locationsLabel.text = "Location where most issues occurred"
        locationsLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        locationsLabel.textColor = .label
        locationsLabel.numberOfLines = 2
        locationsLabel.translatesAutoresizingMaskIntoConstraints = false
        locationsContainer.addSubview(locationsLabel)
        
        let horizontalContainer = UIView()
        horizontalContainer.translatesAutoresizingMaskIntoConstraints = false
        locationsContainer.addSubview(horizontalContainer)
        
        locationsStackView.axis = .vertical
        locationsStackView.spacing = 20
        locationsStackView.alignment = .leading
        locationsStackView.translatesAutoresizingMaskIntoConstraints = false
        horizontalContainer.addSubview(locationsStackView)
        
        chartView.translatesAutoresizingMaskIntoConstraints = false
        horizontalContainer.addSubview(chartView)
        
        let loadingLabel = UILabel()
        loadingLabel.text = "Loading..."
        loadingLabel.font = .systemFont(ofSize: 14)
        loadingLabel.textColor = .secondaryLabel
        locationsStackView.addArrangedSubview(loadingLabel)
        
        NSLayoutConstraint.activate([
            locationsLabel.topAnchor.constraint(equalTo: locationsContainer.topAnchor, constant: 20),
            locationsLabel.leadingAnchor.constraint(equalTo: locationsContainer.leadingAnchor, constant: 20),
            locationsLabel.trailingAnchor.constraint(equalTo: locationsContainer.trailingAnchor, constant: -20),
            
            horizontalContainer.topAnchor.constraint(equalTo: locationsLabel.bottomAnchor, constant: 24),
            horizontalContainer.leadingAnchor.constraint(equalTo: locationsContainer.leadingAnchor, constant: 20),
            horizontalContainer.trailingAnchor.constraint(equalTo: locationsContainer.trailingAnchor, constant: -20),
            horizontalContainer.bottomAnchor.constraint(equalTo: locationsContainer.bottomAnchor, constant: -20),
            
            locationsStackView.leadingAnchor.constraint(equalTo: horizontalContainer.leadingAnchor),
            locationsStackView.topAnchor.constraint(equalTo: horizontalContainer.topAnchor, constant: 10),
            locationsStackView.bottomAnchor.constraint(equalTo: horizontalContainer.bottomAnchor, constant: -30),
            locationsStackView.widthAnchor.constraint(equalToConstant: 120),
            
            chartView.leadingAnchor.constraint(equalTo: locationsStackView.trailingAnchor, constant: 20),
            chartView.trailingAnchor.constraint(equalTo: horizontalContainer.trailingAnchor),
            chartView.topAnchor.constraint(equalTo: horizontalContainer.topAnchor),
            chartView.bottomAnchor.constraint(equalTo: horizontalContainer.bottomAnchor),
            chartView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    func setupPerformanceButton() {
        performanceButton.setTitle("View Technician Performance", for: .normal)
        performanceButton.setTitleColor(.white, for: .normal)
        performanceButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        performanceButton.backgroundColor = UIColor(red: 0/255, green: 87/255, blue: 130/255, alpha: 1)
        performanceButton.layer.cornerRadius = 12
        performanceButton.layer.shadowColor = UIColor(red: 0/255, green: 87/255, blue: 130/255, alpha: 1).cgColor
        performanceButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        performanceButton.layer.shadowRadius = 8
        performanceButton.layer.shadowOpacity = 0.2
        performanceButton.addTarget(self, action: #selector(performanceButtonTapped), for: .touchUpInside)
        performanceButton.translatesAutoresizingMaskIntoConstraints = false
        performanceButton.alpha = 0
        contentView.addSubview(performanceButton)
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
            
            statsContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            statsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsContainer.heightAnchor.constraint(equalToConstant: 130),
            
            ticketsCard.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            ticketsCard.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor),
            ticketsCard.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor),
            ticketsCard.trailingAnchor.constraint(equalTo: statsContainer.centerXAnchor, constant: -8),
            
            resolutionCard.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            resolutionCard.leadingAnchor.constraint(equalTo: statsContainer.centerXAnchor, constant: 8),
            resolutionCard.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor),
            resolutionCard.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor),
            
            monthSelectorButton.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 24),
            monthSelectorButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            monthSelectorButton.heightAnchor.constraint(equalToConstant: 44),
            monthSelectorButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 180),
            
            locationsContainer.topAnchor.constraint(equalTo: monthSelectorButton.bottomAnchor, constant: 24),
            locationsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            performanceButton.topAnchor.constraint(equalTo: locationsContainer.bottomAnchor, constant: 24),
            performanceButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            performanceButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            performanceButton.heightAnchor.constraint(equalToConstant: 54),
            performanceButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    func animateEntranceSequence() {
        let elements: [(view: UIView, delay: TimeInterval)] = [
            (ticketsCard, 0.1), (resolutionCard, 0.15), (monthSelectorButton, 0.2),
            (locationsContainer, 0.25), (performanceButton, 0.3)
        ]
        
        for (view, delay) in elements {
            view.transform = CGAffineTransform(translationX: 0, y: 15)
            UIView.animate(withDuration: 0.5, delay: delay, usingSpringWithDamping: 0.85, initialSpringVelocity: 0, options: .curveEaseOut) {
                view.alpha = 1
                view.transform = .identity
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.chartView.animateChart()
        }
    }
    
    // MARK: - Data Fetching
    
    func fetchStatistics() {
        let components = currentMonth.components(separatedBy: " ")
        guard components.count == 2, let year = Int(components[1]) else {
            print("❌ Invalid month format")
            hideLoading()
            return
        }
        
        let monthName = components[0]
        let monthNumber = getMonthNumber(from: monthName)
        
        // ONLY JANUARY 2025 uses Firebase
        if monthName == "January" && year == 2025 {
            print("📊 Fetching from Firebase: January 2025")
            fetchFromFirebase(monthNumber: monthNumber, year: year, monthName: monthName)
        } else {
            print("📊 Using mock data for: \(monthName) \(year)")
            useMockData(monthName: monthName, monthNumber: monthNumber, year: year)
        }
    }
    
    func fetchFromFirebase(monthNumber: Int, year: Int, monthName: String) {
        db.collection("Feedback").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error: \(error)")
                DispatchQueue.main.async { self.showErrorState() }
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("❌ No documents")
                DispatchQueue.main.async { self.showNoDataState() }
                return
            }
            
            print("✅ Total documents: \(documents.count)")
            
            let calendar = Calendar.current
            let formatter = ISO8601DateFormatter()
            
            // Get December 2024 for comparison
            let previousMonthNumber = 12
            let previousYear = 2024
            
            // Filter current month (January 2025)
            let filteredDocuments = documents.filter { doc in
                let data = doc.data()
                guard let dateString = data["date_submitted"] as? String,
                      let date = formatter.date(from: dateString) else { return false }
                let docMonth = calendar.component(.month, from: date)
                let docYear = calendar.component(.year, from: date)
                return docMonth == monthNumber && docYear == year
            }
            
            // Get December 2024 data for comparison
            let decemberData = self.mockData["December"]!
            self.previousMonthTickets = decemberData.tickets
            self.previousAvgResolutionMinutes = decemberData.avgResolutionMinutes
            
            print("✅ Current: \(filteredDocuments.count), Previous (Dec): \(self.previousMonthTickets)")
            
            self.totalTickets = filteredDocuments.count
            
            // Calculate resolution times
            var totalResolutionMinutes: Double = 0
            var resolvedCount = 0
            
            for doc in filteredDocuments {
                let data = doc.data()
                if let status = data["status"] as? String,
                   (status.lowercased().contains("resolve") || status.lowercased().contains("complete") || status.lowercased() == "closed"),
                   let dateSubmitted = data["date_submitted"] as? String,
                   let responseDate = data["response_date"] as? String,
                   let submitted = formatter.date(from: dateSubmitted),
                   let responded = formatter.date(from: responseDate) {
                    let minutes = responded.timeIntervalSince(submitted) / 60
                    if minutes > 0 {
                        totalResolutionMinutes += minutes
                        resolvedCount += 1
                    }
                }
            }
            
            self.avgResolutionMinutes = resolvedCount > 0 ? totalResolutionMinutes / Double(resolvedCount) : 0
            
            print("⏱️ Avg: \(self.avgResolutionMinutes)min (\(resolvedCount) resolved)")
            
            self.generateChartDataFromFirebase(from: filteredDocuments, month: monthNumber, year: year)
            
            DispatchQueue.main.async {
                self.updateStatsCards()
                self.fetchLocationStatisticsFromFirebase(from: filteredDocuments)
                self.hideLoading()
            }
        }
    }
    
    func useMockData(monthName: String, monthNumber: Int, year: Int) {
        guard let data = mockData[monthName] else {
            print("❌ No mock data for \(monthName)")
            DispatchQueue.main.async { self.showNoDataState() }
            return
        }
        
        // Get previous month data
        let monthOrder = ["January", "February", "March", "April", "May", "June",
                         "July", "August", "September", "October", "November", "December"]
        
        if let currentIndex = monthOrder.firstIndex(of: monthName) {
            let previousIndex = currentIndex > 0 ? currentIndex - 1 : 11
            let previousMonthName = monthOrder[previousIndex]
            
            if let previousData = mockData[previousMonthName] {
                self.previousMonthTickets = previousData.tickets
                self.previousAvgResolutionMinutes = previousData.avgResolutionMinutes
            }
        }
        
        self.totalTickets = data.tickets
        self.avgResolutionMinutes = data.avgResolutionMinutes
        
        print("✅ Mock data loaded: \(data.tickets) tickets, \(data.avgResolutionMinutes)min avg")
        
        generateChartDataFromPattern(pattern: data.dailyPattern, monthNumber: monthNumber, year: year)
        
        DispatchQueue.main.async {
            self.updateStatsCards()
            self.displayMockLocations(locations: data.locations)
            self.hideLoading()
        }
    }
    
    func updateStatsCards() {
        let ticketChange: Int
        if previousMonthTickets > 0 {
            ticketChange = Int(((Double(totalTickets) - Double(previousMonthTickets)) / Double(previousMonthTickets)) * 100)
        } else {
            ticketChange = totalTickets > 0 ? 100 : 0
        }
        
        let ticketChangeText = ticketChange > 0 ? "+\(ticketChange)% increase this month" :
                               ticketChange < 0 ? "\(abs(ticketChange))% decrease this month" :
                               "No change from last month"
        
        let ticketValue = totalTickets == 0 ? "No tickets" : "\(totalTickets) ticket\(totalTickets == 1 ? "" : "s")"
        ticketsCard.configure(title: "Estimated tickets per month", value: ticketValue, subtitle: ticketChangeText, isPositive: ticketChange >= 0)
        
        let hours = Int(avgResolutionMinutes / 60)
        let minutes = Int(avgResolutionMinutes.truncatingRemainder(dividingBy: 60))
        let resolutionValue = avgResolutionMinutes > 0 ? "\(hours)h \(minutes)m" : "N/A"
        
        let resolutionChange: Int
        if previousAvgResolutionMinutes > 0 {
            resolutionChange = Int(((avgResolutionMinutes - previousAvgResolutionMinutes) / previousAvgResolutionMinutes) * 100)
        } else {
            resolutionChange = 0
        }
        
        let resolutionChangeText = resolutionChange > 0 ? "+\(resolutionChange)% slower than last month" :
                                   resolutionChange < 0 ? "\(abs(resolutionChange))% faster than last month" :
                                   "Same as last month"
        
        resolutionCard.configure(title: "Average resolution time", value: resolutionValue, subtitle: resolutionChangeText, isPositive: resolutionChange <= 0)
    }
    
    func showErrorState() {
        ticketsCard.configure(title: "Estimated tickets per month", value: "Error", subtitle: "Could not load data", isPositive: false)
        resolutionCard.configure(title: "Average resolution time", value: "Error", subtitle: "Could not load data", isPositive: false)
        hideLoading()
    }
    
    func showNoDataState() {
        ticketsCard.configure(title: "Estimated tickets per month", value: "0 tickets", subtitle: "No data available", isPositive: true)
        resolutionCard.configure(title: "Average resolution time", value: "N/A", subtitle: "No data available", isPositive: true)
        hideLoading()
    }
    
    func getMonthNumber(from monthName: String) -> Int {
        let months = ["January": 1, "February": 2, "March": 3, "April": 4, "May": 5, "June": 6,
                      "July": 7, "August": 8, "September": 9, "October": 10, "November": 11, "December": 12]
        return months[monthName] ?? 1
    }
    
    func generateChartDataFromFirebase(from documents: [QueryDocumentSnapshot], month: Int, year: Int) {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        
        let calendar = Calendar.current
        guard let firstDayOfMonth = calendar.date(from: dateComponents),
              let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else { return }
        
        let daysInMonth = range.count
        var dailyCounts: [Int] = Array(repeating: 0, count: daysInMonth)
        let formatter = ISO8601DateFormatter()
        
        for doc in documents {
            let data = doc.data()
            if let dateString = data["date_submitted"] as? String,
               let date = formatter.date(from: dateString) {
                let day = calendar.component(.day, from: date)
                if day >= 1 && day <= daysInMonth {
                    dailyCounts[day - 1] += 1
                }
            }
        }
        
        print("📊 Firebase daily counts: \(dailyCounts)")
        
        var cumulativeData: [CGFloat] = []
        var sum: CGFloat = 0
        for count in dailyCounts {
            sum += CGFloat(count)
            cumulativeData.append(sum)
        }
        
        // Only show chart if there's actual data
        if cumulativeData.last ?? 0 > 0 {
            print("📈 Firebase cumulative data: first=\(cumulativeData.first ?? 0), last=\(cumulativeData.last ?? 0)")
            
            DispatchQueue.main.async {
                self.chartData = cumulativeData
                self.chartView.dataPoints = cumulativeData
                self.chartView.monthLabel = self.currentMonth
            }
        } else {
            print("⚠️ No data for chart - showing empty state")
            DispatchQueue.main.async {
                self.chartData = []
                self.chartView.dataPoints = []
                self.chartView.monthLabel = self.currentMonth
            }
        }
    }
    
    func generateChartDataFromPattern(pattern: [Int], monthNumber: Int, year: Int) {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = monthNumber
        dateComponents.day = 1
        
        let calendar = Calendar.current
        guard let firstDayOfMonth = calendar.date(from: dateComponents),
              let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else { return }
        
        let daysInMonth = range.count
        
        // Calculate the sum of the pattern
        let patternSum = pattern.reduce(0, +)
        
        // Scale pattern to match the actual total tickets for this month
        let scaleFactor = Double(totalTickets) / Double(patternSum)
        
        // Extend or trim pattern to match days in month and scale values
        var dailyCounts: [Int] = []
        for day in 0..<daysInMonth {
            let patternValue = pattern[day % pattern.count]
            let scaledValue = Int(round(Double(patternValue) * scaleFactor))
            dailyCounts.append(scaledValue)
        }
        
        // Adjust to ensure total matches exactly (handle rounding differences)
        let currentSum = dailyCounts.reduce(0, +)
        let difference = totalTickets - currentSum
        
        if difference != 0 {
            // Distribute the difference across the middle days
            let midPoint = daysInMonth / 2
            for i in 0..<abs(difference) {
                let index = (midPoint + i) % daysInMonth
                dailyCounts[index] += difference > 0 ? 1 : -1
            }
        }
        
        print("📊 Chart pattern for \(currentMonth): daily counts sum = \(dailyCounts.reduce(0, +)), target = \(totalTickets)")
        
        // Convert to cumulative data for the line chart
        var cumulativeData: [CGFloat] = []
        var sum: CGFloat = 0
        for count in dailyCounts {
            sum += CGFloat(count)
            cumulativeData.append(sum)
        }
        
        print("📈 Cumulative data range: \(cumulativeData.first ?? 0) to \(cumulativeData.last ?? 0)")
        
        DispatchQueue.main.async {
            self.chartData = cumulativeData
            self.chartView.dataPoints = cumulativeData
            self.chartView.monthLabel = self.currentMonth
        }
    }
    
    func fetchLocationStatisticsFromFirebase(from documents: [QueryDocumentSnapshot]) {
        var locationCounts: [String: Int] = [:]
        
        for doc in documents {
            let data = doc.data()
            if let campus = data["campus"] as? String, !campus.isEmpty {
                locationCounts[campus, default: 0] += 1
            }
        }
        
        let sortedLocations = locationCounts.sorted { $0.value > $1.value }
        let topLocations = Array(sortedLocations.prefix(5))
        
        DispatchQueue.main.async {
            self.locationsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            if topLocations.isEmpty {
                let noDataLabel = UILabel()
                noDataLabel.text = "No location data"
                noDataLabel.font = .systemFont(ofSize: 14)
                noDataLabel.textColor = .secondaryLabel
                self.locationsStackView.addArrangedSubview(noDataLabel)
            } else {
                for (location, _) in topLocations {
                    let label = UILabel()
                    label.text = location
                    label.font = .systemFont(ofSize: 14)
                    label.textColor = .secondaryLabel
                    self.locationsStackView.addArrangedSubview(label)
                }
            }
        }
    }
    
    func displayMockLocations(locations: [(String, Int)]) {
        locationsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (location, _) in locations {
            let label = UILabel()
            label.text = location
            label.font = .systemFont(ofSize: 14)
            label.textColor = .secondaryLabel
            locationsStackView.addArrangedSubview(label)
        }
    }
    
    @objc func monthSelectorTapped() {
        let monthPickerVC = MonthPickerViewController()
        monthPickerVC.modalPresentationStyle = .overFullScreen
        monthPickerVC.modalTransitionStyle = .crossDissolve
        monthPickerVC.selectedMonth = currentMonth
        monthPickerVC.onMonthSelected = { [weak self] selectedMonth in
            self?.currentMonth = selectedMonth
            // Update button title using configuration (modern approach)
            self?.monthSelectorButton.configuration?.title = selectedMonth
            self?.chartView.monthLabel = selectedMonth
            self?.showLoading()
            self?.fetchStatistics()
        }
        present(monthPickerVC, animated: true)
    }
    
    @objc func performanceButtonTapped() {
        let alert = UIAlertController(title: "Feature Coming Soon", message: "Technician performance analytics will be available soon.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - StatCardView

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
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.06
        
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        valueLabel.font = .systemFont(ofSize: 32, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(valueLabel)
        
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            subtitleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 6),
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

// MARK: - LineChartView

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
    private let dotLayer = CAShapeLayer()
    
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
            UIColor(red: 74/255, green: 144/255, blue: 226/255, alpha: 0.3).cgColor,
            UIColor(red: 74/255, green: 144/255, blue: 226/255, alpha: 0.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gradientLayer)
        
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.strokeColor = UIColor(red: 74/255, green: 144/255, blue: 226/255, alpha: 1).cgColor
        lineLayer.lineWidth = 2.5
        lineLayer.lineCap = .round
        lineLayer.lineJoin = .round
        layer.addSublayer(lineLayer)
        
        dotLayer.fillColor = UIColor(red: 74/255, green: 144/255, blue: 226/255, alpha: 1).cgColor
        layer.addSublayer(dotLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        drawChart()
    }
    
    private func drawChart() {
        guard !dataPoints.isEmpty, dataPoints.contains(where: { $0 > 0 }) else {
            lineLayer.path = nil
            dotLayer.path = nil
            
            // Show "No data" message
            DispatchQueue.main.async {
                self.setNeedsDisplay()
            }
            return
        }
        
        let path = UIBezierPath()
        let gradientPath = UIBezierPath()
        let width = bounds.width
        let height = bounds.height - 40
        let spacing = width / CGFloat(dataPoints.count - 1)
        let maxValue = dataPoints.max() ?? 1
        let minValue = dataPoints.min() ?? 0
        let range = max(maxValue - minValue, 1)
        
        print("📊 Drawing chart: \(dataPoints.count) points, range: \(minValue)-\(maxValue)")
        
        var points: [CGPoint] = []
        for (index, value) in dataPoints.enumerated() {
            let x = spacing * CGFloat(index)
            let normalizedValue = (value - minValue) / range
            let y = height - (normalizedValue * height * 0.8) - (height * 0.05)
            points.append(CGPoint(x: x, y: y))
        }
        
        if points.count > 0 {
            path.move(to: points[0])
            gradientPath.move(to: CGPoint(x: points[0].x, y: height))
            gradientPath.addLine(to: points[0])
            
            for i in 1..<points.count {
                let currentPoint = points[i]
                let previousPoint = points[i-1]
                let controlPoint1 = CGPoint(x: previousPoint.x + (currentPoint.x - previousPoint.x) * 0.5, y: previousPoint.y)
                let controlPoint2 = CGPoint(x: previousPoint.x + (currentPoint.x - previousPoint.x) * 0.5, y: currentPoint.y)
                path.addCurve(to: currentPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
                gradientPath.addCurve(to: currentPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
            }
        }
        
        if let lastPoint = points.last {
            gradientPath.addLine(to: CGPoint(x: lastPoint.x, y: height))
            gradientPath.addLine(to: CGPoint(x: 0, y: height))
            let dotPath = UIBezierPath(arcCenter: lastPoint, radius: 5, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            dotLayer.path = dotPath.cgPath
        }
        gradientPath.close()
        
        lineLayer.path = path.cgPath
        gradientLayer.mask = createGradientMaskLayer(path: gradientPath)
    }
    
    private func createGradientMaskLayer(path: UIBezierPath) -> CAShapeLayer {
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.white.cgColor
        return maskLayer
    }
    
    func animateChart() {
        let lineAnimation = CABasicAnimation(keyPath: "strokeEnd")
        lineAnimation.fromValue = 0
        lineAnimation.toValue = 1
        lineAnimation.duration = 1.2
        lineAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        lineLayer.strokeEnd = 1
        lineLayer.add(lineAnimation, forKey: "lineAnimation")
        
        let gradientAnimation = CABasicAnimation(keyPath: "opacity")
        gradientAnimation.fromValue = 0
        gradientAnimation.toValue = 1
        gradientAnimation.duration = 1.2
        gradientLayer.opacity = 1
        gradientLayer.add(gradientAnimation, forKey: "gradientAnimation")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let height = rect.height - 40
        
        // If no data, show message
        if dataPoints.isEmpty || !dataPoints.contains(where: { $0 > 0 }) {
            let noDataText = "No data available" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.tertiaryLabel
            ]
            let textSize = noDataText.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (rect.width - textSize.width) / 2,
                y: (height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            noDataText.draw(in: textRect, withAttributes: attributes)
            return
        }
        
        let dates = ["1", "5", "10", "15", "20", "25", "31"]
        let spacing = rect.width / CGFloat(dataPoints.count - 1)
        let labelIndices = [0, 5, 10, 15, 20, 25, 30]
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.tertiaryLabel,
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
        
        let monthString = monthLabel as NSString
        let monthAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        let monthRect = CGRect(x: 0, y: height + 23, width: rect.width, height: 15)
        monthString.draw(in: monthRect, withAttributes: monthAttributes)
    }
}

// MARK: - Month Picker

class MonthPickerViewController: UIViewController {
    var selectedMonth: String = "October 2025"
    var onMonthSelected: ((String) -> Void)?
    
    private let months = ["January 2025", "February 2025", "March 2025", "April 2025",
                          "May 2025", "June 2025", "July 2025", "August 2025",
                          "September 2025", "October 2025", "November 2025", "December 2025"]
    private let monthShortNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
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
        
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.alpha = 0
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissModal))
        overlayView.addGestureRecognizer(tapGesture)
        
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
        
        titleLabel.text = "Select Month"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        modalContainer.addSubview(titleLabel)
        
        monthsCollectionView.backgroundColor = .systemBackground
        monthsCollectionView.delegate = self
        monthsCollectionView.dataSource = self
        monthsCollectionView.register(MonthCell.self, forCellWithReuseIdentifier: "MonthCell")
        monthsCollectionView.showsVerticalScrollIndicator = false
        monthsCollectionView.isScrollEnabled = false
        monthsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        modalContainer.addSubview(monthsCollectionView)
        monthsCollectionView.reloadData()
        
        yearLabel.text = "2025"
        yearLabel.font = .systemFont(ofSize: 13, weight: .medium)
        yearLabel.textColor = .secondaryLabel
        yearLabel.textAlignment = .center
        yearLabel.translatesAutoresizingMaskIntoConstraints = false
        modalContainer.addSubview(yearLabel)
        
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
            modalContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            modalContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            
            titleLabel.topAnchor.constraint(equalTo: modalContainer.topAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: modalContainer.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: modalContainer.trailingAnchor, constant: -24),
            
            monthsCollectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 28),
            monthsCollectionView.leadingAnchor.constraint(equalTo: modalContainer.leadingAnchor, constant: 24),
            monthsCollectionView.trailingAnchor.constraint(equalTo: modalContainer.trailingAnchor, constant: -24),
            monthsCollectionView.heightAnchor.constraint(equalToConstant: 304),
            
            yearLabel.topAnchor.constraint(equalTo: monthsCollectionView.bottomAnchor, constant: 20),
            yearLabel.leadingAnchor.constraint(equalTo: modalContainer.leadingAnchor, constant: 24),
            yearLabel.trailingAnchor.constraint(equalTo: modalContainer.trailingAnchor, constant: -24),
            
            cancelButton.topAnchor.constraint(equalTo: yearLabel.bottomAnchor, constant: 20),
            cancelButton.leadingAnchor.constraint(equalTo: modalContainer.leadingAnchor, constant: 24),
            cancelButton.trailingAnchor.constraint(equalTo: modalContainer.trailingAnchor, constant: -24),
            cancelButton.heightAnchor.constraint(equalToConstant: 52),
            cancelButton.bottomAnchor.constraint(equalTo: modalContainer.bottomAnchor, constant: -28)
        ])
    }
    
    private func animateIn() {
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

extension MonthPickerViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MonthCell", for: indexPath) as! MonthCell
        cell.configure(monthName: monthShortNames[indexPath.item], isSelected: months[indexPath.item] == selectedMonth)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing: CGFloat = 24
        let availableWidth = collectionView.bounds.width - totalSpacing
        let itemWidth = floor(availableWidth / 3)
        return CGSize(width: itemWidth, height: 64)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedMonthName = months[indexPath.item]
        onMonthSelected?(selectedMonthName)
        selectedMonth = selectedMonthName
        collectionView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.dismissModal()
        }
    }
}

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
        containerView.layer.cornerRadius = 20
        containerView.layer.shadowColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1).cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        monthLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        monthLabel.textColor = .white
        monthLabel.textAlignment = .center
        monthLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(monthLabel)
        
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
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1).cgColor,
                UIColor(red: 232/255, green: 149/255, blue: 16/255, alpha: 1).cgColor
            ]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            gradientLayer.frame = containerView.bounds
            gradientLayer.cornerRadius = 20
            
            containerView.layer.sublayers?.forEach { if $0 is CAGradientLayer { $0.removeFromSuperlayer() } }
            containerView.layer.insertSublayer(gradientLayer, at: 0)
            containerView.layer.shadowOpacity = 0.3
            checkmarkView.alpha = 1
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0) {
                self.containerView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }
        } else {
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1).cgColor,
                UIColor(red: 0/255, green: 61/255, blue: 94/255, alpha: 1).cgColor
            ]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            gradientLayer.frame = containerView.bounds
            gradientLayer.cornerRadius = 20
            
            containerView.layer.sublayers?.forEach { if $0 is CAGradientLayer { $0.removeFromSuperlayer() } }
            containerView.layer.insertSublayer(gradientLayer, at: 0)
            containerView.layer.shadowOpacity = 0.2
            checkmarkView.alpha = 0
            containerView.transform = .identity
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let gradientLayer = containerView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = containerView.bounds
        }
    }
}
