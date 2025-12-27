//
//  TicketViewList.swift
//  RepairPro
//

import UIKit

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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ticketView.isHidden = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        setupScrollViewAndStackView()
        setupFilterButton() // ✅ filter icon button
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
        // Filter icon button in navigation bar
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "slider.horizontal.3"), // icon
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
        Task {
            do {
                let tickets: [Ticket] = try await SupabaseClientManager.shared.client
                    .from("tickets")
                    .select()
                    .execute()
                    .value
                
                // Remove pending tickets
                ticketsArray = tickets.filter { $0.status.lowercased() != "pending" }
                filteredTickets = ticketsArray
                
                await MainActor.run {
                    displayTickets(filteredTickets)
                }
            } catch {
                await MainActor.run {
                    showErrorAlert(message: "Failed to load tickets: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func displayTickets(_ tickets: [Ticket]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        tickets.forEach { createTicketView(for: $0) }
    }
    
    func applyFilters(status: String?, priority: String?, deadline: String?) {
        filteredTickets = ticketsArray
        
        // Filter by status
        if let status = status {
            filteredTickets = filteredTickets.filter { $0.status.lowercased() == status.lowercased() }
        }
        
        // Filter by priority
        if let priority = priority {
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
        
        // Filter by deadline
        if let deadline = deadline {
            filteredTickets.sort { first, second in
                guard let date1 = ISO8601DateFormatter().date(from: first.due),
                      let date2 = ISO8601DateFormatter().date(from: second.due) else { return false }
                return deadline.lowercased() == "nearest" ? date2 < date1 : date1 < date2
            }
        }
        
        displayTickets(filteredTickets)
    }
    
    func createTicketView(for ticket: Ticket) {
        let statusColor = getStatusColor(for: ticket.status)
        
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.heightAnchor.constraint(equalToConstant: 140).isActive = true
        
        containerView.tag = ticket.ticket_id
        let tap = UITapGestureRecognizer(target: self, action: #selector(ticketTapped(_:)))
        containerView.addGestureRecognizer(tap)
        containerView.isUserInteractionEnabled = true
        
        // Sidebar
        let sideBar = UIView()
        sideBar.backgroundColor = statusColor
        sideBar.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(sideBar)
        
        // Ticket ID
        let ticketIDLabel = UILabel()
        ticketIDLabel.text = "Ticket ID: \(ticket.ticket_id)"
        ticketIDLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        ticketIDLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(ticketIDLabel)
        
        // Due date
        let dueDateLabel = UILabel()
        dueDateLabel.text = "Due: \(ticket.due)"
        dueDateLabel.font = .systemFont(ofSize: 14)
        dueDateLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dueDateLabel)
        
        // Description
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
        
        // Status label
        let statusLabel = UILabel()
        statusLabel.text = "Status: \(ticket.status)"
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusLabel)
        
        // Campus label
        let campusLabel = UILabel()
        campusLabel.text = "Campus \(ticket.campus)"
        campusLabel.font = .systemFont(ofSize: 13)
        campusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(campusLabel)
        
        // Status circle
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
        
        // Ticket Image
        let ticketImageView = UIImageView()
        ticketImageView.contentMode = .scaleAspectFill
        ticketImageView.clipsToBounds = true
        ticketImageView.layer.cornerRadius = 8
        ticketImageView.backgroundColor = .systemGray4
        ticketImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(ticketImageView)
        
        loadImageWithDefault(from: ticket.image_url, into: ticketImageView)
        
        NSLayoutConstraint.activate([
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
            descriptionText.trailingAnchor.constraint(equalTo: ticketImageView.leadingAnchor, constant: -12),
            descriptionText.topAnchor.constraint(equalTo: descriptionTitle.bottomAnchor, constant: 2),
            
            statusLabel.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            statusLabel.topAnchor.constraint(equalTo: descriptionText.bottomAnchor, constant: 6),
            
            campusLabel.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            campusLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4),
            
            statusCircle.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            statusCircle.topAnchor.constraint(equalTo: dueDateLabel.bottomAnchor, constant: 12),
            statusCircle.widthAnchor.constraint(equalToConstant: 50),
            statusCircle.heightAnchor.constraint(equalToConstant: 50),
            
            tickLabel.centerXAnchor.constraint(equalTo: statusCircle.centerXAnchor),
            tickLabel.centerYAnchor.constraint(equalTo: statusCircle.centerYAnchor),
            
            ticketImageView.trailingAnchor.constraint(equalTo: statusCircle.leadingAnchor, constant: -12),
            ticketImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            ticketImageView.widthAnchor.constraint(equalToConstant: 60),
            ticketImageView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
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
    
    func loadImageWithDefault(from urlString: String?, into imageView: UIImageView) {
        let defaultImages = [
            "https://wlefukllkrvgpjelkxav.supabase.co/storage/v1/object/public/images/Copilot_20251225_111257.png",
            "https://wlefukllkrvgpjelkxav.supabase.co/storage/v1/object/public/images/Copilot_20251225_112235.png",
            "https://wlefukllkrvgpjelkxav.supabase.co/storage/v1/object/public/images/Copilot_20251225_112136.png"
        ]
        
        let imageURL = urlString ?? defaultImages.randomElement()!
        guard let url = URL(string: imageURL) else { return }
        
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

// MARK: - Ticket model
struct Ticket: Codable {
    let ticket_id: Int
    let due: String
    let description: String
    var status: String
    let campus: String
    let image_url: String?
    let priority: String?
}

