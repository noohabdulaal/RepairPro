//
//  Edittickets.swift
//  RepairPro
//

import UIKit

class Edittickets: UIViewController {
    
    // MARK: - Ticket property (passed from TicketViewList)
    var ticket: Ticket?
    
    // MARK: - IBOutlets for labels/textfields
    @IBOutlet weak var ticketIDLabel: UITextField!
    @IBOutlet weak var descriptionLabel: UITextField!
    @IBOutlet weak var statusLabel: UITextField!
    @IBOutlet weak var campusLabel: UITextField!
    @IBOutlet weak var dueDateLabel: UITextField!
    @IBOutlet weak var subjectLabel: UITextField!      // <-- NEW

    // MARK: - Priority Segmented Control
    @IBOutlet weak var prioritySegment: UISegmentedControl!
    
    // MARK: - Save Button
    @IBOutlet weak var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        displayTicketDetails()
        setupPrioritySegment()
    }
    
    // MARK: - Display ticket info
    func displayTicketDetails() {
        guard let ticket = ticket else { return }
        ticketIDLabel.text = "Ticket ID: \(ticket.ticket_id)"
        descriptionLabel.text = ticket.description
        statusLabel.text = ticket.status
        campusLabel.text = ticket.campus
        dueDateLabel.text = ticket.due
                     // <-- NEW

    }
    
    // MARK: - Setup priority segmented control
    func setupPrioritySegment() {
        guard let status = ticket?.status.lowercased() else { return }
        switch status {
        case "high":
            prioritySegment.selectedSegmentIndex = 0
        case "medium":
            prioritySegment.selectedSegmentIndex = 1
        case "low":
            prioritySegment.selectedSegmentIndex = 2
        default:
            prioritySegment.selectedSegmentIndex = UISegmentedControl.noSegment
        }
    }
    
    // MARK: - Priority changed
    @IBAction func priorityChanged(_ sender: UISegmentedControl) {
        guard var ticket = ticket else { return }
        
        switch sender.selectedSegmentIndex {
        case 0:
            ticket.status = "High"
        case 1:
            ticket.status = "Medium"
        case 2:
            ticket.status = "Low"
        default:
            break
        }
        
        statusLabel.text = ticket.status
        self.ticket = ticket  // update the ticket property
    }
    
    // MARK: - Save Button Action
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let ticket = ticket else { return }
        
        // TODO: Add your database update logic here
        /*
        Task {
            do {
                try await SupabaseClientManager.shared.client
                    .from("tickets")
                    .update(values: ["status": ticket.status])
                    .eq(column: "ticket_id", value: ticket.ticket_id)
                    .execute()
            } catch {
                showAlert(title: "Error", message: "Failed to update ticket: \(error.localizedDescription)")
                return
            }
        }
        */
        
        print("Ticket #\(ticket.ticket_id) saved with status: \(ticket.status)")
        
        // Show small confirmation message
        let alert = UIAlertController(title: nil,
                                      message: "Ticket has been assigned",
                                      preferredStyle: .alert)
        present(alert, animated: true)
        
        // Dismiss alert automatically after 1.2 seconds and go back
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            alert.dismiss(animated: true) {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // MARK: - Helper Alert
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

