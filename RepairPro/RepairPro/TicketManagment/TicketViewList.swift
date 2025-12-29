//
//  TicketViewList.swift (UPDATED)
//  Shows formatted deadline with urgency indicators on ticket cards
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
                print("--- Document Data for \(doc.documentID) ---")
                print(doc.data())
                print("---------------------------------------")
                
                do {
                    let ticket = try doc.data(as: Ticket.self)
                    tickets.append(ticket)
                    print("✅ Successfully decoded ticket ID: \(ticket.ticket_id)")
                } catch {
                    print("❌ DECODING ERROR: Failed to decode ticket for document \(doc.documentID):")
                    print(error)
                }
            }
            
            DispatchQueue.main.async {
                self.ticketsArray = tickets.filter { $0.status.lowercased() != "pending" }
                self.applyCurrentFilters()
                print("✅ Final ticketsArray count displayed: \(self.ticketsArray.count)")
            }
        }
    }
    
    func displayTickets(_ tickets: [Ticket]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        tickets.forEach { createTicketView(for: $0) }
    }
    
    func applyFilters(status: String?, priority: String?, deadline: String?) {
        currentStatusFilter = status
        currentPriorityFilter = priority
        currentDeadlineFilter = deadline
        applyCurrentFilters()
    }

    func applyCurrentFilters() {
        filteredTickets = ticketsArray
        
        if let status = currentStatusFilter {
            filteredTickets = filteredTickets.filter { $0.status.lowercased() == status.lowercased() }
        }
        
        if let priority = currentPriorityFilter {
            switch priority.lowercased() {
            case "high":
                filteredTickets = filteredTickets.filter { $0.status.lowercased() == "in progress" }
            case "medium":
                filteredTickets = filteredTickets.filter { $0.status.lowercased() == "assigned" }
            case "low":
                filteredTickets = filteredTickets.filter { $0.status.lowercased() == "complete" }
            default: break
            }
        }
        
        if let deadline = currentDeadlineFilter {
            filteredTickets.sort { first, second in
                guard let date1 = ISO8601DateFormatter().date(from: first.due),
                      let date2 = ISO8601DateFormatter().date(from: second.due) else { return false }
                return deadline.lowercased() == "nearest" ? date1 < date2 : date2 < date1
            }
        }
        
        displayTickets(filteredTickets)
    }

    // MARK: - Create Ticket View (UPDATED with formatted deadline)
    func createTicketView(for ticket: Ticket) {
        let statusColor = getStatusColor(for: ticket.status)
        
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let hasTechi = ticket.technician_name != nil
        containerView.heightAnchor.constraint(equalToConstant: hasTechi ? 180 : 160).isActive = true
        
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
        
        // ✅ UPDATED: Formatted due date with urgency
        let dueDateLabel = UILabel()
        let (formattedDate, urgencyEmoji, textColor) = formatDeadline(ticket.due)
        dueDateLabel.text = "\(urgencyEmoji) Due: \(formattedDate)"
        dueDateLabel.font = .systemFont(ofSize: 14, weight: .medium)
        dueDateLabel.textColor = textColor
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
        
        // Technician label
        var technicianLabel: UILabel?
        if let technicianName = ticket.technician_name {
            let label = UILabel()
            label.text = "🛠️ Technician: \(technicianName)"
            label.font = .systemFont(ofSize: 13)
            label.textColor = .label
            label.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(label)
            technicianLabel = label
        }
        
        // ✅ NEW: Time remaining label
        let timeRemainingLabel = UILabel()
        let timeRemaining = getTimeRemaining(from: ticket.due)
        timeRemainingLabel.text = " \(timeRemaining)"
        timeRemainingLabel.font = .systemFont(ofSize: 12, weight: .medium)
        timeRemainingLabel.textColor = isOverdue(ticket.due) ? .systemRed : .systemGray
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
        
        var constraints = [
            sideBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            sideBar.topAnchor.constraint(equalTo: containerView.topAnchor),
            sideBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            sideBar.widthAnchor.constraint(equalToConstant: 20),
            
            ticketIDLabel.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            ticketIDLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            
            dueDateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            dueDateLabel.centerYAnchor.constraint(equalTo: ticketIDLabel.centerYAnchor),
            
            descriptionTitle.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            descriptionTitle.topAnchor.constraint(equalTo: ticketIDLabel.bottomAnchor, constant: 8),
            
            descriptionText.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            descriptionText.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -160),
            descriptionText.topAnchor.constraint(equalTo: descriptionTitle.bottomAnchor, constant: 2),
            
            statusLabel.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            statusLabel.topAnchor.constraint(equalTo: descriptionText.bottomAnchor, constant: 6),
            
            campusLabel.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            
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
        
        if let techLabel = technicianLabel {
            constraints.append(contentsOf: [
                techLabel.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
                techLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4),
                campusLabel.topAnchor.constraint(equalTo: techLabel.bottomAnchor, constant: 4)
            ])
        } else {
            constraints.append(
                campusLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4)
            )
        }
        
        NSLayoutConstraint.activate(constraints)
        stackView.addArrangedSubview(containerView)
    }
    
    // ✅ NEW: Format Deadline with Urgency
    func formatDeadline(_ dueString: String) -> (String, String, UIColor) {
        // Parse ISO8601 date
        let formatter = ISO8601DateFormatter()
        guard let deadline = formatter.date(from: dueString) else {
            return (dueString, "📅", .label)
        }
        
        // Format for display
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM dd, HH:mm"
        let formattedDate = displayFormatter.string(from: deadline)
        
        // Get urgency level
        let urgency = getUrgencyLevel(for: deadline)
        
        return (formattedDate, urgency.emoji, urgency.textColor)
    }
    
    // ✅ NEW: Get Urgency Level
    func getUrgencyLevel(for deadline: Date) -> (emoji: String, textColor: UIColor) {
        let hoursRemaining = Calendar.current.dateComponents(
            [.hour],
            from: Date(),
            to: deadline
        ).hour ?? 0
        
        if hoursRemaining < 0 {
            return ("", .systemRed)      // Overdue
        } else if hoursRemaining < 4 {
            return ("", .systemOrange)   // Urgent
        } else if hoursRemaining < 24 {
            return ("", .systemYellow)   // Soon
        } else {
            return ("", .label)          // Normal
        }
    }
    
    // ✅ NEW: Get Time Remaining
    func getTimeRemaining(from dueString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let deadline = formatter.date(from: dueString) else {
            return "N/A"
        }
        
        let now = Date()
        let components = Calendar.current.dateComponents(
            [.day, .hour, .minute],
            from: now,
            to: deadline
        )
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") left"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") left"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") left"
        } else {
            return "Overdue"
        }
    }
    
    // ✅ NEW: Check if Overdue
    func isOverdue(_ dueString: String) -> Bool {
        let formatter = ISO8601DateFormatter()
        guard let deadline = formatter.date(from: dueString) else {
            return false
        }
        return Date() > deadline
    }
    
    @objc func ticketTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view,
              let ticket = ticketsArray.first(where: { $0.ticket_id == view.tag }) else { return }

        let storyboard = UIStoryboard(name: "Hatem", bundle: nil)
        let editVC = storyboard.instantiateViewController(withIdentifier: "Edittickets") as! Edittickets
        editVC.ticket = ticket
        navigationController?.pushViewController(editVC, animated: true)
    }
    
    func getStatusColor(for status: String) -> UIColor {
        switch status.lowercased() {
        case "complete":
            return UIColor(red: 0/255, green: 72/255, blue: 111/255, alpha: 1)
        case "assigned":
            return UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1)
        case "in progress":
            return UIColor.systemGray
        default:
            return .systemGray
        }
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
