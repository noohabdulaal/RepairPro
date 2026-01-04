//
//  PreviousTicketsViewController.swift
//  RepairPro
//
//  Feature 4: View Previous Tickets
//  Developer: Noof Abdullah [202204310]
//

import UIKit

class PreviousTicketsViewController: UIViewController {

    @IBOutlet weak var ReferenceNo: UILabel!
    @IBOutlet weak var Date: UILabel!
    @IBOutlet weak var Status: UILabel!
    @IBOutlet weak var subject: UILabel!
    @IBOutlet weak var Campus: UILabel!
    @IBOutlet weak var RoomNo: UILabel!
    @IBOutlet weak var BuildingNo: UILabel!
    @IBOutlet weak var Description: UILabel!
    @IBOutlet weak var Image: UIImageView!
    
    @IBOutlet weak var RateTicketBtn: UIButton!
    @IBOutlet weak var EditTicketBtn: UIButton!
    @IBOutlet weak var CancelTicketBtn: UIButton!
    
    // Current ticket being displayed
    var currentTicket: Ticket?
    var previousTickets: [Ticket] = []
    var currentIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable buttons initially
        disableAllButtons()
        
        // Load previous tickets
        loadPreviousTickets()
    }
    
    // MARK: - Load Previous Tickets from Firebase
    func loadPreviousTickets() {
        print("📱 ===== LOADING PREVIOUS TICKETS VIEW =====")
        
        // Use mock user instead of Firebase Auth
        let userId = CurrentUser.getUserId()
        print("📝 Current User ID: \(userId)")
        
        // Fetch previous tickets (Done/Cancelled)
        Ticket.fetchPreviousTickets(userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let tickets):
                print("✅ Successfully loaded \(tickets.count) previous tickets")
                self.previousTickets = tickets
                
                if tickets.isEmpty {
                    print("⚠️ No previous tickets found - clearing fields")
                    // No previous tickets - clear fields and disable buttons
                    self.clearAllFields()
                    self.disableAllButtons()
                } else {
                    // Show the earliest (last) ticket
                    self.currentIndex = tickets.count - 1
                    print("📝 Displaying ticket at index \(self.currentIndex): #\(tickets[self.currentIndex].ticketNumber)")
                    self.displayTicket(tickets[self.currentIndex])
                }
                
            case .failure(let error):
                print("❌ Error loading previous tickets: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: "Failed to load previous tickets")
                self.clearAllFields()
            }
        }
    }
    
    // MARK: - Display Ticket
    func displayTicket(_ ticket: Ticket) {
        currentTicket = ticket
        
        // Set labels
        ReferenceNo.text = "#\(ticket.ticketNumber)"
        Date.text = ticket.formattedCreatedDate
        Status.text = ticket.status.rawValue
        subject.text = ticket.title
        Campus.text = ticket.campus
        RoomNo.text = ticket.roomNumber
        BuildingNo.text = ticket.building
        Description.text = ticket.description
        
        // Load image if exists
        if let imageUrl = ticket.imageUrl, let url = URL(string: imageUrl) {
            loadImage(from: url)
        } else {
            Image.image = UIImage(systemName: "photo")
        }
        
        // Enable/disable buttons based on ticket status
        updateButtons(for: ticket)
    }
    
    // MARK: - Update Buttons Based on Status
    func updateButtons(for ticket: Ticket) {
        // Rate button: Only for "Done" tickets that haven't been rated
        if ticket.status == .done {
            checkIfFeedbackExists(for: ticket) { [weak self] hasRated in
                self?.RateTicketBtn.isEnabled = !hasRated
                self?.RateTicketBtn.alpha = hasRated ? 0.5 : 1.0
            }
        } else {
            RateTicketBtn.isEnabled = false
            RateTicketBtn.alpha = 0.5
        }
        
        // Edit button: Only for "New" status
        EditTicketBtn.isEnabled = ticket.isEditable
        EditTicketBtn.alpha = ticket.isEditable ? 1.0 : 0.5
        
        // Cancel button: Only for "New" status
        CancelTicketBtn.isEnabled = ticket.isCancellable
        CancelTicketBtn.alpha = ticket.isCancellable ? 1.0 : 0.5
    }
    
    func checkIfFeedbackExists(for ticket: Ticket, completion: @escaping (Bool) -> Void) {
        // Use mock user instead of Firebase Auth
        let userId = CurrentUser.getUserId()
        
        Feedback.checkIfFeedbackExists(ticketId: ticket.id ?? "", userId: userId) { result in
            switch result {
            case .success(let exists):
                completion(exists)
            case .failure:
                completion(false)
            }
        }
    }
    
    // MARK: - Clear All Fields
    func clearAllFields() {
        ReferenceNo.text = "#0"
        Date.text = "-"
        Status.text = "-"
        subject.text = "-"
        Campus.text = "-"
        RoomNo.text = "-"
        BuildingNo.text = "-"
        Description.text = "No previous tickets"
        Image.image = UIImage(systemName: "photo")
    }
    
    func disableAllButtons() {
        RateTicketBtn.isEnabled = false
        RateTicketBtn.alpha = 0.5
        EditTicketBtn.isEnabled = false
        EditTicketBtn.alpha = 0.5
        CancelTicketBtn.isEnabled = false
        CancelTicketBtn.alpha = 0.5
    }
    
    // MARK: - Load Image
    func loadImage(from url: URL) {
        // Check if it's a Base64 string (starts with data:image)
        let urlString = url.absoluteString
        
        if urlString.hasPrefix("data:image") {
            // It's Base64 - decode it
            if let image = Ticket.convertBase64ToImage(urlString) {
                self.Image.image = image
            } else {
                self.Image.image = UIImage(systemName: "photo")
            }
        } else {
            // It's a URL - download it (for old tickets with Firebase Storage)
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.Image.image = image
                    }
                }
            }.resume()
        }
    }
    
    // MARK: - Rate Ticket Button
    @IBAction func RateTicketBtn(_ sender: Any) {
        guard let ticket = currentTicket else { return }
        
        // Navigate to Rate/Feedback page programmatically
        if let rateVC = storyboard?.instantiateViewController(withIdentifier: "rateFeedback") as? RateFeedbackViewController {
            rateVC.ticket = ticket
            navigationController?.pushViewController(rateVC, animated: true)
        }
    }
    
    // MARK: - Edit Ticket Button
    @IBAction func EditTicketBtn(_ sender: Any) {
        guard let ticket = currentTicket else { return }
        
        // Navigate to Edit page programmatically
        if let editVC = storyboard?.instantiateViewController(withIdentifier: "editTicket") as? EditTicketViewController {
            editVC.ticket = ticket
            navigationController?.pushViewController(editVC, animated: true)
        }
    }
    
    // MARK: - Cancel Ticket Button
    @IBAction func CancelTicketbtn(_ sender: Any) {
        guard let ticket = currentTicket else { return }
        
        // Show confirmation modal
        let alert = UIAlertController(
            title: "Cancel Ticket",
            message: "Are you sure you want to cancel ticket #\(ticket.ticketNumber)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Yes, Cancel", style: .destructive) { [weak self] _ in
            self?.cancelTicket(ticket)
        })
        
        present(alert, animated: true)
    }
    
    func cancelTicket(_ ticket: Ticket) {
        // Show loading
        let loadingAlert = UIAlertController(title: nil, message: "Cancelling ticket...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        present(loadingAlert, animated: true)
        
        ticket.cancel { [weak self] result in
            guard let self = self else { return }
            
            // Dismiss loading
            loadingAlert.dismiss(animated: true) {
                switch result {
                case .success:
                    self.showSuccessAndRedirect()
                    
                case .failure(let error):
                    self.showAlert(title: "Error", message: "Failed to cancel ticket: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func showSuccessAndRedirect() {
        let alert = UIAlertController(
            title: "Success",
            message: "Ticket has been cancelled successfully",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            // Navigate back to Dashboard
            self?.navigationController?.popToRootViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Helper
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
