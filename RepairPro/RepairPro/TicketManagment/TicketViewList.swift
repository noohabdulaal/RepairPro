//
//  TicketViewList.swift (UPDATED)
//  Shows formatted deadline with urgency indicators on ticket cards
//  ✅ UPDATED: Uses new Ticket model with robust decoding
//

import UIKit
import FirebaseFirestore
import Cloudinary

class TicketViewList: UIViewController {

    @IBOutlet weak var ticketView: UIView!
    @IBOutlet weak var statusIcon: UIImageView!
    @IBOutlet weak var campus: UILabel!
    @IBOutlet weak var statusText: UILabel!
    @IBOutlet weak var ticketID: UILabel!
    @IBOutlet weak var dueDate: UILabel!
    @IBOutlet weak var ticketDescreption: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    var ticketsArray: [Ticket] = []
    var filteredTickets: [Ticket] = []
    
    var currentStatusFilter: String? = nil
    var currentPriorityFilter: String? = nil
    var currentDeadlineFilter: String? = nil
    
    let db = Firestore.firestore()
    let cloudinary = CLDCloudinary(configuration: CLDConfiguration(cloudName: "dtthzideh"))

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ticketView.isHidden = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        setupScrollViewAndStackView()
        setupFilterButton()
        fetchTickets()
    }
    
    func setupScrollViewAndStackView() {
        scrollView.constraints.forEach { scrollView.removeConstraint($0) }
        stackView.constraints.forEach { stackView.removeConstraint($0) }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
    
    func setupFilterButton() {
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "slider.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(filterButtonTapped)
        )
        filterButton.tintColor = .systemBlue
        navigationItem.rightBarButtonItem = filterButton
    }
    
    @objc func filterButtonTapped() {
        let filterVC = FilterModalViewController()
        filterVC.modalPresentationStyle = .overFullScreen
        filterVC.applyFilters = { [weak self] status, priority, deadline in
            self?.applyFilters(status: status, priority: priority, deadline: deadline)
        }
        present(filterVC, animated: true)
    }
    
    func fetchTickets() {
        print("🔍 Fetching tickets from Firestore...")
        
        db.collection("Tickets").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ FIREBASE ERROR: Error listening for tickets: \(error.localizedDescription)")
                self.showErrorAlert(message: "Failed to connect to ticket updates.")
                return
            }
            
            guard let snapshot = snapshot else {
                print("❌ SNAPSHOT ERROR: No snapshot data received.")
                return
            }
            
            print("✅ Received \(snapshot.documents.count) documents from Firestore.")
            
            var tickets: [Ticket] = []
            
            for doc in snapshot.documents {
                print("\n📄 Processing document: \(doc.documentID)")
                let data = doc.data()
                print("   Raw data: \(data)")
                
                do {
                    let ticket = try doc.data(as: Ticket.self)
                    tickets.append(ticket)
                    print("✅ Successfully decoded ticket:")
                    print("   - ID: \(ticket.ticket_id)")
                    print("   - Status: \(ticket.status)")
                    print("   - Priority: \(ticket.priority)")
                    print("   - Campus: \(ticket.campus)")
                    print("   - Technician: \(ticket.displayTechnicianName)")
                    print("   - Description: \(ticket.description)")
                } catch {
                    print("❌ DECODING ERROR for document \(doc.documentID):")
                    print("   Error: \(error)")
                    print("   Local description: \(error.localizedDescription)")
                }
            }
            
            print("\n📊 SUMMARY: Successfully decoded \(tickets.count) out of \(snapshot.documents.count) tickets")
            
            DispatchQueue.main.async {
                self.ticketsArray = tickets.filter { $0.status.lowercased() != "pending" }
                print("✅ Loaded \(self.ticketsArray.count) non-pending tickets")
                
                // Debug: Log all tickets with their priorities
                print("\n📊 Ticket breakdown:")
                for ticket in self.ticketsArray {
                    print("   Ticket \(ticket.ticket_id): priority=\(ticket.priority), status=\(ticket.status)")
                }
                
                self.applyCurrentFilters()
            }
        }
    }
    
    func displayTickets(_ tickets: [Ticket]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if tickets.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No tickets match the current filters"
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .systemGray
            emptyLabel.font = .systemFont(ofSize: 16)
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(emptyLabel)
        } else {
            tickets.forEach { createTicketView(for: $0) }
        }
    }
    
    // Apply Filters Method
    func applyFilters(status: String?, priority: String?, deadline: String?) {
        print("\n🔍 NEW FILTERS APPLIED:")
        print("   Status: \(status ?? "none")")
        print("   Priority: \(priority ?? "none")")
        print("   Deadline: \(deadline ?? "none")")
        
        currentStatusFilter = status
        currentPriorityFilter = priority
        currentDeadlineFilter = deadline
        applyCurrentFilters()
    }

    // Apply Current Filters Method
    func applyCurrentFilters() {
        print("\n🔍 ========== APPLYING FILTERS ==========")
        print("Starting with \(ticketsArray.count) tickets")
        
        // Start with all tickets (excluding pending)
        filteredTickets = ticketsArray
        
        // FILTER BY STATUS (if selected)
        if let status = currentStatusFilter {
            let beforeCount = filteredTickets.count
            filteredTickets = filteredTickets.filter {
                $0.status.lowercased() == status.lowercased()
            }
            print("📌 Status filter '\(status)': \(beforeCount) → \(filteredTickets.count) tickets")
        } else {
            print("📌 No status filter applied")
        }
        
        // FILTER BY PRIORITY (if selected)
        if let priority = currentPriorityFilter {
            let beforeCount = filteredTickets.count
            print("📌 Filtering by priority: '\(priority)'")
            
            filteredTickets = filteredTickets.filter { ticket in
                let matches = ticket.priority.lowercased() == priority.lowercased()
                print("   Ticket \(ticket.ticket_id): '\(ticket.priority)' \(matches ? "✓ MATCHES" : "✗ doesn't match") '\(priority)'")
                return matches
            }
            
            print("📌 Priority filter '\(priority)': \(beforeCount) → \(filteredTickets.count) tickets")
        } else {
            print("📌 No priority filter applied")
        }
        
        // SORT BY DEADLINE (if selected)
        if let deadline = currentDeadlineFilter {
            let formatter = ISO8601DateFormatter()
            
            filteredTickets.sort { first, second in
                guard let date1 = formatter.date(from: first.due),
                      let date2 = formatter.date(from: second.due) else {
                    return false
                }
                
                // "nearest" = earliest first (ascending)
                // "furthest" = latest first (descending)
                if deadline.lowercased() == "nearest" {
                    return date1 < date2
                } else {
                    return date1 > date2
                }
            }
            print("📌 Sorted by deadline '\(deadline)': \(filteredTickets.count) tickets")
        } else {
            print("📌 No deadline sorting applied")
        }
        
        print("✅ FINAL RESULT: Displaying \(filteredTickets.count) tickets")
        print("========================================\n")
        
        displayTickets(filteredTickets)
    }

    // MARK: - Create Ticket View (with priority display)
    func createTicketView(for ticket: Ticket) {
        let statusColor = ticket.accentColor  // Use the model's accent color
        
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let hasTechi = ticket.displayTechnicianName != "Unassigned"
        containerView.heightAnchor.constraint(equalToConstant: hasTechi ? 200 : 180).isActive = true
        
        containerView.tag = ticket.ticket_id
        let tap = UITapGestureRecognizer(target: self, action: #selector(ticketTapped(_:)))
        containerView.addGestureRecognizer(tap)
        containerView.isUserInteractionEnabled = true
        
        let sideBar = UIView()
        sideBar.backgroundColor = statusColor
        sideBar.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(sideBar)
        
        let ticketIDLabel = UILabel()
        ticketIDLabel.text = "Ticket ID: \(ticket.ticket_id)"
        ticketIDLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        ticketIDLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(ticketIDLabel)
        
        // Priority badge with custom colors
        let priorityBadge = UILabel()
        priorityBadge.text = ticket.priority
        priorityBadge.font = .systemFont(ofSize: 11, weight: .bold)
        priorityBadge.textAlignment = .center
        priorityBadge.textColor = .white
        
        // Set color based on priority: High = #00476F, Medium = #FEA214, Low = grey
        switch ticket.priority.lowercased() {
        case "high":
            priorityBadge.backgroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1) // #00476F
        case "medium":
            priorityBadge.backgroundColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1) // #FEA214
        case "low":
            priorityBadge.backgroundColor = .systemGray
        default:
            priorityBadge.backgroundColor = .systemGray
        }
        
        priorityBadge.layer.cornerRadius = 4
        priorityBadge.clipsToBounds = true
        priorityBadge.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(priorityBadge)
        
        // Due date label using model's formatted date
        let dueDateLabel = UILabel()
        dueDateLabel.text = "Due: \(ticket.formattedDueDate)"
        dueDateLabel.font = .systemFont(ofSize: 14, weight: .medium)
        dueDateLabel.textColor = ticket.isOverdue ? .systemRed : .label
        dueDateLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dueDateLabel)
        
        let descriptionTitle = UILabel()
        descriptionTitle.text = "Description:"
        descriptionTitle.font = .systemFont(ofSize: 14, weight: .bold)
        descriptionTitle.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(descriptionTitle)
        
        let descriptionText = UILabel()
        descriptionText.text = ticket.description
        descriptionText.font = .systemFont(ofSize: 13)
        descriptionText.numberOfLines = 2
        descriptionText.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(descriptionText)
        
        let statusLabel = UILabel()
        statusLabel.text = "Status: \(ticket.status)"
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusLabel)
        
        let campusLabel = UILabel()
        campusLabel.text = "Campus \(ticket.campus)"
        campusLabel.font = .systemFont(ofSize: 13)
        campusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(campusLabel)
        
        // Technician label - always show, use displayTechnicianName
        let technicianLabel = UILabel()
        technicianLabel.text = "🛠️ Technician: \(ticket.displayTechnicianName)"
        technicianLabel.font = .systemFont(ofSize: 13)
        technicianLabel.textColor = ticket.displayTechnicianName == "Unassigned" ? .systemGray : .label
        technicianLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(technicianLabel)
        
        // Time remaining label using model's property
        let timeRemainingLabel = UILabel()
        timeRemainingLabel.text = "⏱ \(ticket.daysRemainingText)"
        timeRemainingLabel.font = .systemFont(ofSize: 12, weight: .medium)
        timeRemainingLabel.textColor = ticket.isOverdue ? .systemRed : .systemGray
        timeRemainingLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(timeRemainingLabel)
        
        let statusCircle = UIView()
        statusCircle.backgroundColor = statusColor
        statusCircle.layer.cornerRadius = 25
        statusCircle.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusCircle)
        
        let tickLabel = UILabel()
        tickLabel.text = "✓"
        tickLabel.font = .boldSystemFont(ofSize: 30)
        tickLabel.textColor = .white
        tickLabel.translatesAutoresizingMaskIntoConstraints = false
        statusCircle.addSubview(tickLabel)
        
        let ticketImageView = UIImageView()
        ticketImageView.contentMode = .scaleAspectFill
        ticketImageView.clipsToBounds = true
        ticketImageView.layer.cornerRadius = 8
        ticketImageView.backgroundColor = .systemGray4
        ticketImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(ticketImageView)
        
        loadImageFromCloudinary(publicIDOrURL: ticket.image_url, into: ticketImageView)
        
        let constraints = [
            sideBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            sideBar.topAnchor.constraint(equalTo: containerView.topAnchor),
            sideBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            sideBar.widthAnchor.constraint(equalToConstant: 20),
            
            ticketIDLabel.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            ticketIDLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            
            priorityBadge.leadingAnchor.constraint(equalTo: ticketIDLabel.trailingAnchor, constant: 8),
            priorityBadge.centerYAnchor.constraint(equalTo: ticketIDLabel.centerYAnchor),
            priorityBadge.widthAnchor.constraint(equalToConstant: 70),
            priorityBadge.heightAnchor.constraint(equalToConstant: 20),
            
            dueDateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            dueDateLabel.centerYAnchor.constraint(equalTo: ticketIDLabel.centerYAnchor),
            
            descriptionTitle.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            descriptionTitle.topAnchor.constraint(equalTo: ticketIDLabel.bottomAnchor, constant: 8),
            
            descriptionText.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            descriptionText.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -160),
            descriptionText.topAnchor.constraint(equalTo: descriptionTitle.bottomAnchor, constant: 2),
            
            statusLabel.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            statusLabel.topAnchor.constraint(equalTo: descriptionText.bottomAnchor, constant: 6),
            
            technicianLabel.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            technicianLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4),
            
            campusLabel.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            campusLabel.topAnchor.constraint(equalTo: technicianLabel.bottomAnchor, constant: 4),
            
            timeRemainingLabel.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            timeRemainingLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            statusCircle.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            statusCircle.topAnchor.constraint(equalTo: dueDateLabel.bottomAnchor, constant: 12),
            statusCircle.widthAnchor.constraint(equalToConstant: 50),
            statusCircle.heightAnchor.constraint(equalToConstant: 50),
            
            tickLabel.centerXAnchor.constraint(equalTo: statusCircle.centerXAnchor),
            tickLabel.centerYAnchor.constraint(equalTo: statusCircle.centerYAnchor),
            
            ticketImageView.trailingAnchor.constraint(equalTo: statusCircle.leadingAnchor, constant: -12),
            ticketImageView.centerYAnchor.constraint(equalTo: statusCircle.centerYAnchor),
            ticketImageView.widthAnchor.constraint(equalToConstant: 60),
            ticketImageView.heightAnchor.constraint(equalToConstant: 60)
        ]
        
        NSLayoutConstraint.activate(constraints)
        stackView.addArrangedSubview(containerView)
    }
    
    @objc func ticketTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view,
              let ticket = ticketsArray.first(where: { $0.ticket_id == view.tag }) else { return }

        let storyboard = UIStoryboard(name: "Hatem", bundle: nil)
        let editVC = storyboard.instantiateViewController(withIdentifier: "Edittickets") as! Edittickets
        editVC.ticket = ticket
        navigationController?.pushViewController(editVC, animated: true)
    }
    
    func loadImageFromCloudinary(publicIDOrURL: String?, into imageView: UIImageView) {
        let defaultImageURL = "https://res.cloudinary.com/dtthzideh/image/upload/v1766927687/Copilot_20251225_112235_zuxqkf.png"
        guard let path = publicIDOrURL, !path.isEmpty else {
            loadRemoteImage(from: defaultImageURL, into: imageView)
            return
        }
        
        if path.starts(with: "http") {
            loadRemoteImage(from: path, into: imageView)
        } else {
            if let url = cloudinary.createUrl().generate(path) {
                loadRemoteImage(from: url, into: imageView)
            }
        }
    }
    
    func loadRemoteImage(from urlString: String, into imageView: UIImageView) {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                imageView.image = image
            }
        }.resume()
    }
    
    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
