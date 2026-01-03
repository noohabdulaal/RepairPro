//
//  TicketViewList.swift (UPDATED)
//  Shows formatted deadline with urgency indicators on ticket cards
//  ✅ UPDATED: Uses new Ticket model with robust decoding
//  ✅ NEW: Shows "New Ticket" badge for unassigned tickets
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
            tickets.enumerated().forEach { index, ticket in
                createTicketView(for: ticket, displayIndex: index)
            }
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
    
    func applyCurrentFilters() {
        filteredTickets = ticketsArray
        
        // 1. STATUS FILTER
        if let statusFilter = currentStatusFilter, !statusFilter.isEmpty {
            print("   Applying status filter: \(statusFilter)")
            filteredTickets = filteredTickets.filter {
                $0.status.lowercased() == statusFilter.lowercased()
            }
            print("   → After status filter: \(filteredTickets.count) tickets")
        }
        
        // 2. PRIORITY FILTER
        if let priorityFilter = currentPriorityFilter, !priorityFilter.isEmpty {
            print("   Applying priority filter: \(priorityFilter)")
            filteredTickets = filteredTickets.filter {
                $0.priority.lowercased() == priorityFilter.lowercased()
            }
            print("   → After priority filter: \(filteredTickets.count) tickets")
        }
        
        // 3. DEADLINE FILTER
        if let deadlineFilter = currentDeadlineFilter, !deadlineFilter.isEmpty {
            print("   Applying deadline filter: \(deadlineFilter)")
            let now = Date()
            
            filteredTickets = filteredTickets.filter { ticket in
                let formatter = ISO8601DateFormatter()
                guard let dueDate = formatter.date(from: ticket.due) else {
                    return false
                }
                
                let daysRemaining = Calendar.current.dateComponents([.day], from: now, to: dueDate).day ?? 0
                
                switch deadlineFilter.lowercased() {
                case "today":
                    return daysRemaining == 0
                case "this week":
                    return daysRemaining >= 0 && daysRemaining <= 7
                case "overdue":
                    return daysRemaining < 0
                default:
                    return true
                }
            }
            print("   → After deadline filter: \(filteredTickets.count) tickets")
        }
        
        print("✅ FINAL FILTERED COUNT: \(filteredTickets.count) tickets")
        
        displayTickets(filteredTickets)
    }

    // MARK: - Create Ticket View (with priority display + New Ticket badge)
    func createTicketView(for ticket: Ticket, displayIndex: Int) {
        let statusColor = ticket.accentColor  // Use the model's accent color
        
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // ⚡ ELECTRIC BORDER for unassigned tickets
        if ticket.displayTechnicianName == "Unassigned" {
            // Add bright electric border
            containerView.layer.borderWidth = 2
            containerView.layer.borderColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1).cgColor
            
            // Add electric glow
            containerView.layer.shadowColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1).cgColor
            containerView.layer.shadowOffset = .zero
            containerView.layer.shadowRadius = 6
            containerView.layer.shadowOpacity = 0.6
            
            // Fast pulsing like electricity (multiple animations)
            
            // 1. Border width pulse (quick)
            let widthPulse = CABasicAnimation(keyPath: "borderWidth")
            widthPulse.fromValue = 2
            widthPulse.toValue = 3.5
            widthPulse.duration = 0.3
            widthPulse.autoreverses = true
            widthPulse.repeatCount = .infinity
            containerView.layer.add(widthPulse, forKey: "electricWidth")
            
            // 2. Glow intensity pulse (medium speed)
            let glowPulse = CABasicAnimation(keyPath: "shadowOpacity")
            glowPulse.fromValue = 0.4
            glowPulse.toValue = 1.0
            glowPulse.duration = 0.6
            glowPulse.autoreverses = true
            glowPulse.repeatCount = .infinity
            containerView.layer.add(glowPulse, forKey: "electricGlow")
            
            // 3. Shadow radius pulse (creates zapping effect)
            let radiusPulse = CABasicAnimation(keyPath: "shadowRadius")
            radiusPulse.fromValue = 4
            radiusPulse.toValue = 10
            radiusPulse.duration = 0.6
            radiusPulse.autoreverses = true
            radiusPulse.repeatCount = .infinity
            radiusPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            containerView.layer.add(radiusPulse, forKey: "electricRadius")
        }
        
        let hasTechi = ticket.displayTechnicianName != "Unassigned"
        containerView.heightAnchor.constraint(equalToConstant: hasTechi ? 200 : 180).isActive = true
        
        containerView.tag = ticket.ticket_id
        let tap = UITapGestureRecognizer(target: self, action: #selector(ticketTapped(_:)))
        containerView.addGestureRecognizer(tap)
        containerView.isUserInteractionEnabled = true
        
        let sideBar = UIView()
        sideBar.backgroundColor = statusColor
        sideBar.layer.cornerRadius = 12
        sideBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner] // Only round left corners
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
        
        // ✅ Use display index to select image (ensures variety in the list)
        loadImageFromCloudinary(publicIDOrURL: ticket.image_url, into: ticketImageView, displayIndex: displayIndex)
        
        // ✅ NEW: "New Ticket" badge for unassigned tickets
        var newTicketBadge: UILabel?
        if ticket.displayTechnicianName == "Unassigned" {
            let badge = UILabel()
            badge.text = "New Ticket"
            badge.font = .systemFont(ofSize: 13, weight: .bold)
            badge.textColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1) // #007AFF (blue)
            badge.textAlignment = .right
            badge.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(badge)
            newTicketBadge = badge
        }
        
        var constraints = [
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
        
        // ✅ Add constraints for "New Ticket" badge
        if let badge = newTicketBadge {
            constraints.append(contentsOf: [
                badge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                badge.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
            ])
        }
        
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
    
    func loadImageFromCloudinary(publicIDOrURL: String?, into imageView: UIImageView, displayIndex: Int) {
        // ✅ Array of default images to select from (matching Edittickets.swift)
        let defaultImageURLs = [
            "https://wlefukllkrvgpjelkxav.supabase.co/storage/v1/object/public/images/Copilot_20251225_111257.png",
            "https://wlefukllkrvgpjelkxav.supabase.co/storage/v1/object/public/images/Copilot_20251225_112235.png",
            "https://wlefukllkrvgpjelkxav.supabase.co/storage/v1/object/public/images/Copilot_20251225_112136.png"
        ]
        
        // ✅ Use display index to rotate through images (ensures each ticket shows different image)
        let imageIndex = displayIndex % defaultImageURLs.count
        let selectedImageURL = defaultImageURLs[imageIndex]
        
        guard let path = publicIDOrURL, !path.isEmpty else {
            loadRemoteImage(from: selectedImageURL, into: imageView)
            return
        }
        
        // ✅ Always use the default images for now to ensure variety
        loadRemoteImage(from: selectedImageURL, into: imageView)
        
        // Original logic (commented out - uncomment if you want to use custom images when available)
        /*
        if path.starts(with: "http") {
            loadRemoteImage(from: path, into: imageView)
        } else {
            if let url = cloudinary.createUrl().generate(path) {
                loadRemoteImage(from: url, into: imageView)
            } else {
                loadRemoteImage(from: selectedImageURL, into: imageView)
            }
        }
        */
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
