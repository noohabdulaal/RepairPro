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
    @IBOutlet weak var ticketImageView: UIImageView!

    // MARK: - Priority Segmented Control
    @IBOutlet weak var prioritySegment: UISegmentedControl!
    
    // MARK: - Save Button
    @IBOutlet weak var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        displayTicketDetails()
        setupPrioritySegment()
        loadTicketImage() // ✅ IMAGE FEATURE
    }
    
    // MARK: - Display ticket info
    func displayTicketDetails() {
        guard let ticket = ticket else { return }
        ticketIDLabel.text = "Ticket ID: \(ticket.ticket_id)"
        descriptionLabel.text = ticket.description
        statusLabel.text = ticket.status
        campusLabel.text = ticket.campus
        dueDateLabel.text = ticket.due
    }
    
    // MARK: - Load ticket image (updated to random default if none)
    func loadTicketImage() {
        let defaultImages = [
            "https://wlefukllkrvgpjelkxav.supabase.co/storage/v1/object/public/images/Copilot_20251225_111257.png",
            "https://wlefukllkrvgpjelkxav.supabase.co/storage/v1/object/public/images/Copilot_20251225_112235.png",
            "https://wlefukllkrvgpjelkxav.supabase.co/storage/v1/object/public/images/Copilot_20251225_112136.png"
        ]
        
        let finalURLString: String
        
        if let url = ticket?.image_url, !url.isEmpty {
            finalURLString = url
        } else {
            finalURLString = defaultImages.randomElement()!
        }
        
        guard let url = URL(string: finalURLString) else {
            ticketImageView.image = UIImage(systemName: "photo")
            ticketImageView.tintColor = .systemGray
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.ticketImageView.image = image
            }
        }.resume()
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
        self.ticket = ticket
    }
    
    // MARK: - Save Button Action
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let ticket = ticket else { return }
        
        print("Ticket #\(ticket.ticket_id) saved with status: \(ticket.status)")
        
        let alert = UIAlertController(title: nil,
                                      message: "Ticket has been assigned",
                                      preferredStyle: .alert)
        present(alert, animated: true)
        
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

