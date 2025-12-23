//
//  TicketViewList.swift
//  RepairPro
//
//  Created by BP-36-201-17 on 23/12/2025.
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
    
    // Add a scroll view and stack view to hold multiple tickets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide the original ticketView
        ticketView.isHidden = true
        
        // CRITICAL: Remove all storyboard constraints
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup all constraints programmatically
        setupScrollViewAndStackView()
        
        // Fetch tickets from Supabase
        fetchTickets()
    }
    
    func setupScrollViewAndStackView() {
        // Remove any existing constraints
        scrollView.constraints.forEach { scrollView.removeConstraint($0) }
        stackView.constraints.forEach { stackView.removeConstraint($0) }
        
        // Configure scroll view constraints - pin to all edges of safe area
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // Configure stack view properties
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fill
        stackView.alignment = .fill
        
        // Configure stack view constraints
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            // CRITICAL: This width constraint prevents overlapping
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    func fetchTickets() {
        Task {
            do {
                let tickets: [Ticket] = try await SupabaseClientManager.shared.client
                    .from("tickets")
                    .select()
                    .execute()
                    .value
                
                print("Fetched \(tickets.count) tickets")
                
                // Create a view for each ticket on the main thread
                await MainActor.run {
                    // Clear existing views
                    stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                    
                    for ticket in tickets {
                        createTicketView(for: ticket)
                    }
                }
            } catch {
                print("Error fetching tickets: \(error)")
                // Optionally show an alert to the user
                await MainActor.run {
                    showErrorAlert(message: "Failed to load tickets: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func createTicketView(for ticket: Ticket) {
        // Get the status color first so we can use it for both circle and sidebar
        let statusColor = getStatusColor(for: ticket.status)
        
        // Main container view
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 12  // Added radius to the card
        containerView.clipsToBounds = true  // Important for the corner radius to show
        // Removed border width and color
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Side bar - now uses status color instead of orange
        let sideBar = UIView()
        sideBar.backgroundColor = statusColor  // Changed from .systemOrange to statusColor
        sideBar.translatesAutoresizingMaskIntoConstraints = false
        
        // Ticket ID label (same line)
        let ticketIDLabel = UILabel()
        ticketIDLabel.text = "Ticket ID: \(ticket.ticket_id)"
        ticketIDLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        ticketIDLabel.textColor = .label
        ticketIDLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Due date label (same line, right aligned)
        let dueDateLabel = UILabel()
        dueDateLabel.text = "Due: \(ticket.due)"
        dueDateLabel.font = .systemFont(ofSize: 14, weight: .regular)
        dueDateLabel.textColor = .label
        dueDateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description title
        let descriptionTitle = UILabel()
        descriptionTitle.text = "Description:"
        descriptionTitle.font = .systemFont(ofSize: 14, weight: .bold)
        descriptionTitle.textColor = .label
        descriptionTitle.translatesAutoresizingMaskIntoConstraints = false
        
        // Description text
        let descriptionText = UILabel()
        descriptionText.text = ticket.description
        descriptionText.font = .systemFont(ofSize: 13, weight: .regular)
        descriptionText.textColor = .label
        descriptionText.numberOfLines = 2
        descriptionText.lineBreakMode = .byTruncatingTail
        descriptionText.translatesAutoresizingMaskIntoConstraints = false
        
        // Status icon and label (same line with icon)
        let statusIcon = UIImageView()
        statusIcon.image = UIImage(systemName: "scope")
        statusIcon.tintColor = .label
        statusIcon.contentMode = .scaleAspectFit
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        
        let statusLabel = UILabel()
        statusLabel.text = "Status: \(ticket.status)"
        statusLabel.font = .systemFont(ofSize: 13, weight: .regular)
        statusLabel.textColor = .label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Campus icon and label (same line with icon)
        let campusIcon = UIImageView()
        campusIcon.image = UIImage(systemName: "location")
        campusIcon.tintColor = .label
        campusIcon.contentMode = .scaleAspectFit
        campusIcon.translatesAutoresizingMaskIntoConstraints = false
        
        let campusLabel = UILabel()
        campusLabel.text = "Campus \(ticket.campus)"
        campusLabel.font = .systemFont(ofSize: 13, weight: .regular)
        campusLabel.textColor = .label
        campusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Status circle icon (right side, under due date)
        let statusCircle = UIView()
        statusCircle.backgroundColor = statusColor  // Use the pre-calculated color
        statusCircle.layer.cornerRadius = 25
        statusCircle.translatesAutoresizingMaskIntoConstraints = false
        
        // Exclamation mark in circle
        let exclamationLabel = UILabel()
        exclamationLabel.text = "!"
        exclamationLabel.font = .systemFont(ofSize: 30, weight: .bold)
        exclamationLabel.textColor = .white
        exclamationLabel.textAlignment = .center
        exclamationLabel.translatesAutoresizingMaskIntoConstraints = false
        statusCircle.addSubview(exclamationLabel)
        
        // Add all subviews
        containerView.addSubview(sideBar)
        containerView.addSubview(ticketIDLabel)
        containerView.addSubview(dueDateLabel)
        containerView.addSubview(descriptionTitle)
        containerView.addSubview(descriptionText)
        containerView.addSubview(statusIcon)
        containerView.addSubview(statusLabel)
        containerView.addSubview(campusIcon)
        containerView.addSubview(campusLabel)
        containerView.addSubview(statusCircle)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Container fixed height
            containerView.heightAnchor.constraint(equalToConstant: 140),
            
            // Orange side bar (thicker)
            sideBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            sideBar.topAnchor.constraint(equalTo: containerView.topAnchor),
            sideBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            sideBar.widthAnchor.constraint(equalToConstant: 20),
            
            // Ticket ID label (left side)
            ticketIDLabel.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            ticketIDLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            
            // Due date label (right side, same line as ticket ID)
            dueDateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            dueDateLabel.centerYAnchor.constraint(equalTo: ticketIDLabel.centerYAnchor),
            
            // Description title
            descriptionTitle.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            descriptionTitle.topAnchor.constraint(equalTo: ticketIDLabel.bottomAnchor, constant: 8),
            
            // Description text
            descriptionText.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            descriptionText.trailingAnchor.constraint(equalTo: statusCircle.leadingAnchor, constant: -12),
            descriptionText.topAnchor.constraint(equalTo: descriptionTitle.bottomAnchor, constant: 2),
            
            // Status icon
            statusIcon.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            statusIcon.topAnchor.constraint(equalTo: descriptionText.bottomAnchor, constant: 8),
            statusIcon.widthAnchor.constraint(equalToConstant: 16),
            statusIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Status label
            statusLabel.leadingAnchor.constraint(equalTo: statusIcon.trailingAnchor, constant: 6),
            statusLabel.centerYAnchor.constraint(equalTo: statusIcon.centerYAnchor),
            
            // Campus icon
            campusIcon.leadingAnchor.constraint(equalTo: sideBar.trailingAnchor, constant: 12),
            campusIcon.topAnchor.constraint(equalTo: statusIcon.bottomAnchor, constant: 6),
            campusIcon.widthAnchor.constraint(equalToConstant: 16),
            campusIcon.heightAnchor.constraint(equalToConstant: 16),
            campusIcon.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12),
            
            // Campus label
            campusLabel.leadingAnchor.constraint(equalTo: campusIcon.trailingAnchor, constant: 6),
            campusLabel.centerYAnchor.constraint(equalTo: campusIcon.centerYAnchor),
            
            // Status circle (under due date, right side)
            statusCircle.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            statusCircle.topAnchor.constraint(equalTo: dueDateLabel.bottomAnchor, constant: 12),
            statusCircle.widthAnchor.constraint(equalToConstant: 50),
            statusCircle.heightAnchor.constraint(equalToConstant: 50),
            
            // Exclamation label inside circle
            exclamationLabel.centerXAnchor.constraint(equalTo: statusCircle.centerXAnchor),
            exclamationLabel.centerYAnchor.constraint(equalTo: statusCircle.centerYAnchor)
        ])
        
        // Add to stack view
        stackView.addArrangedSubview(containerView)
        
        // Make sure container view width matches stack view width
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])
        
        print("Created ticket view for ticket #\(ticket.ticket_id)")
    }
    
    func getStatusColor(for status: String) -> UIColor {
        switch status.lowercased() {
        case "pending":
            return .systemYellow
        case "in progress", "assigned":
            return .systemGreen
        case "complete", "completed":
            return .systemBlue
        default:
            return .systemGray
        }
    }
    
    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// Ticket model matching your database structure
struct Ticket: Codable {
    let ticket_id: Int
    let due: String
    let description: String
    let status: String
    let campus: String
}
