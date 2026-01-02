//
//  Edittickets.swift (FIXED)
//  Auto-sets status to "Assigned" when technician selected + save
//  ✅ FIXED: Added debug logging for priority saving
//

import UIKit
import FirebaseFirestore

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
    
    // MARK: - Technician Button
    @IBOutlet weak var technicianButton: UIButton!
    
    // MARK: - Save Button
    @IBOutlet weak var saveButton: UIButton!
    
    // MARK: - Firestore
    let db = Firestore.firestore()
    
    // MARK: - Technician Selection
    var selectedTechnician: Technician?
    let availableTechnicians = [
        Technician(id: 1, name: "Ahmed Abbas"),
        Technician(id: 2, name: "Sarah Johnson"),
        Technician(id: 3, name: "Mike Chen"),
        Technician(id: 4, name: "Emma Wilson"),
        Technician(id: 5, name: "David Martinez"),
        Technician(id: 6, name: "Lisa Anderson"),
        Technician(id: 7, name: "Tom Brown")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        displayTicketDetails()
        setupPrioritySegment()
        setupTechnicianButton()
        loadTicketImage()
        loadExistingTechnician()
        updatePredictedDeadline()
        
        // Make deadline read-only
        dueDateLabel.isEnabled = false
        dueDateLabel.textColor = .systemGray
        
        // Make status read-only (will be auto-updated)
        statusLabel.isEnabled = false
        statusLabel.textColor = .systemGray
        
        // Disable save button if no technician is selected
        updateSaveButtonState()
        
        // ✅ DEBUG: Log initial priority
        print("📝 Initial ticket priority: \(ticket?.priority ?? "nil")")
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
    
    // MARK: - Load Existing Technician
    func loadExistingTechnician() {
        guard let ticket = ticket,
              let technicianID = ticket.technician_id,
              let technicianName = ticket.technician_name else {
            print("⚠️ No technician assigned to ticket")
            updateSaveButtonState()  // Will disable save button
            return
        }
        
        if let technician = availableTechnicians.first(where: { $0.id == technicianID }) {
            selectedTechnician = technician
        } else {
            selectedTechnician = Technician(id: technicianID, name: technicianName)
        }
        
        updateTechnicianButtonTitle()
        updateSaveButtonState()  // Will enable save button since technician exists
        print("✅ Loaded existing technician: \(technicianName)")
    }
    
    // MARK: - Setup Technician Button
    func setupTechnicianButton() {
        guard let button = technicianButton else { return }
        
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .systemGray
        config.background.backgroundColor = UIColor.systemGray6
        config.background.cornerRadius = 8
        config.background.strokeWidth = 0.5
        config.background.strokeColor = UIColor.systemGray4
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        let chevronImage = UIImage(systemName: "chevron.down", withConfiguration: chevronConfig)
        config.image = chevronImage
        config.imagePlacement = .trailing
        config.imagePadding = 10
        
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        
        updateTechnicianButtonTitle()
        
        button.addTarget(self, action: #selector(technicianButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Update Technician Button Title
    func updateTechnicianButtonTitle() {
        guard let button = technicianButton,
              var config = button.configuration else { return }
        
        if let technician = selectedTechnician {
            config.title = technician.name
            config.baseForegroundColor = .label
        } else {
            config.title = "Select Technician"
            config.baseForegroundColor = .systemGray
        }
        
        button.configuration = config
    }
    
    // MARK: - Technician Button Tapped
    @objc func technicianButtonTapped() {
        let pickerVC = TechnicianPickerViewController()
        pickerVC.technicians = availableTechnicians
        pickerVC.selectedTechnician = selectedTechnician
        pickerVC.delegate = self
        
        let navController = UINavigationController(rootViewController: pickerVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(navController, animated: true)
    }
    
    // MARK: - Load ticket image
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
        guard let priority = ticket?.priority else {
            print("⚠️ No priority set for ticket, defaulting to Medium")
            prioritySegment.selectedSegmentIndex = 1 // Default to Medium (index 1)
            return
        }
        
        print("📝 Setting up priority segment with: \(priority)")
        
        switch priority.lowercased() {
        case "high":
            prioritySegment.selectedSegmentIndex = 0
            print("✅ Set to High (index 0)")
        case "medium":
            prioritySegment.selectedSegmentIndex = 1
            print("✅ Set to Medium (index 1)")
        case "low":
            prioritySegment.selectedSegmentIndex = 2
            print("✅ Set to Low (index 2)")
        default:
            prioritySegment.selectedSegmentIndex = 1 // Default to Medium
            print("⚠️ Unknown priority '\(priority)', defaulting to Medium")
        }
    }
    
    // MARK: - Priority changed
    @IBAction func priorityChanged(_ sender: UISegmentedControl) {
        let selectedPriority = getSelectedPriority()
        print("📝 Priority changed to: \(selectedPriority.rawValue)")
        updatePredictedDeadline()
        updateStatusPreview()
    }
    
    // ✅ Update Save Button State
    func updateSaveButtonState() {
        if selectedTechnician != nil {
            saveButton.isEnabled = true
            saveButton.alpha = 1.0
        } else {
            saveButton.isEnabled = false
            saveButton.alpha = 0.5
        }
    }
    
    // ✅ Update Status Preview
    func updateStatusPreview() {
        // If technician is selected, show "Assigned"
        if selectedTechnician != nil {
            statusLabel.text = "Assigned"
            statusLabel.textColor = UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1) // Green for assigned
        } else {
            statusLabel.text = "Pending"
            statusLabel.textColor = .systemGray
        }
    }
    
    // MARK: - Update Predicted Deadline
    func updatePredictedDeadline() {
        // Determine status based on technician selection
        let status: TicketStatus = selectedTechnician != nil ? .assigned : .pending
        let priority = getSelectedPriority()
        
        // Calculate deadline
        let deadline = DeadlineCalculator.calculateDeadline(
            status: status,
            priority: priority
        )
        
        // Display predicted deadline
        let formatted = DeadlineCalculator.formatDeadline(deadline)
        let timeRemaining = DeadlineCalculator.timeRemaining(until: deadline)
        dueDateLabel.text = "📅 \(formatted) (\(timeRemaining))"
        dueDateLabel.textColor = .systemGreen
    }
    
    // MARK: - Get Selected Priority
    func getSelectedPriority() -> TicketPriority {
        switch prioritySegment.selectedSegmentIndex {
        case 0:
            return .high
        case 1:
            return .medium
        case 2:
            return .low
        default:
            return .medium
        }
    }
    
    // MARK: - Save Button Action (FIXED with logging)
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard var ticket = ticket else { return }
        
        // ✅ Check if technician is selected
        guard let technician = selectedTechnician else {
            showAlert(title: "Technician Required", message: "Please select a technician before saving. A ticket cannot have 'Assigned' status without a technician.")
            return
        }
        
        // Get selected priority
        let priority = getSelectedPriority()
        print("💾 Saving with priority: \(priority.rawValue)")
        
        // ✅ Set status to "Assigned" when technician is selected
        let status: TicketStatus = .assigned
        
        // Validate: Cannot assign without technician
        if status == .assigned && ticket.technician_id == nil {
            showAlert(title: "Error", message: "Cannot set status to 'Assigned' without a technician")
            return
        }
        
        // ✅ AUTO-GENERATE DEADLINE based on Assigned status + priority
        let deadline = DeadlineCalculator.calculateDeadline(
            status: status,
            priority: priority
        )
        
        // Update ticket with selected technician
        ticket.technician_id = technician.id
        ticket.technician_name = technician.name
        
        // Save to Firestore
        saveTicketToFirestore(
            ticket: ticket,
            status: status,
            priority: priority,
            deadline: deadline
        )
    }
    
    // MARK: - Save Ticket to Firestore (FIXED with better logging)
    func saveTicketToFirestore(
        ticket: Ticket,
        status: TicketStatus,
        priority: TicketPriority,
        deadline: Date
    ) {
        saveButton.isEnabled = false
        saveButton.setTitle("Saving...", for: .normal)
        
        // Prepare data to update
        var updateData: [String: Any] = [
            "status": status.rawValue,
            "description": descriptionLabel.text ?? ticket.description,
            "campus": campusLabel.text ?? ticket.campus,
            "priority": priority.rawValue,  // ✅ This saves the priority
            "due": DeadlineCalculator.formatDeadlineForFirebase(deadline)
        ]
        
        // Add technician data
        if let technicianID = ticket.technician_id,
           let technicianName = ticket.technician_name {
            updateData["technician_id"] = technicianID
            updateData["technician_name"] = technicianName
        }
        
        print("💾 Updating Firestore with data:")
        print("   Ticket ID: \(ticket.ticket_id)")
        print("   Status: \(status.rawValue)")
        print("   Priority: \(priority.rawValue)")
        print("   Due: \(DeadlineCalculator.formatDeadlineForFirebase(deadline))")
        
        // Update Firestore document
        db.collection("Tickets")
            .whereField("ticket_id", isEqualTo: ticket.ticket_id)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error finding ticket: \(error.localizedDescription)")
                    self.showErrorAndResetButton("Failed to save ticket")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("❌ Ticket document not found")
                    self.showErrorAndResetButton("Ticket not found")
                    return
                }
                
                print("📝 Found ticket document: \(document.documentID)")
                
                document.reference.updateData(updateData) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("❌ Error updating ticket: \(error.localizedDescription)")
                            self.showErrorAndResetButton("Failed to save changes")
                        } else {
                            print("✅ Ticket updated successfully!")
                            print("   Status: \(status.rawValue)")
                            print("   Priority: \(priority.rawValue)")
                            print("   New deadline: \(DeadlineCalculator.formatDeadline(deadline))")
                            self.showSuccessAndReturn(deadline: deadline)
                        }
                    }
                }
            }
    }
    
    // MARK: - Show Success and Return
    func showSuccessAndReturn(deadline: Date) {
        saveButton.setTitle("Save changes", for: .normal)
        saveButton.isEnabled = true
        
        let deadlineStr = DeadlineCalculator.formatDeadline(deadline)
        let timeRemaining = DeadlineCalculator.timeRemaining(until: deadline)
        
        let alert = UIAlertController(
            title: "✅ Ticket Assigned",
            message: "Status: Assigned\nDeadline: \(deadlineStr)\n(\(timeRemaining))",
            preferredStyle: .alert
        )
        
        present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true) {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // MARK: - Show Error and Reset Button
    func showErrorAndResetButton(_ message: String) {
        saveButton.setTitle("Save changes", for: .normal)
        saveButton.isEnabled = true
        showAlert(title: "Error", message: message)
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

// MARK: - Technician Picker Delegate
extension Edittickets: TechnicianPickerDelegate {
    func didSelectTechnician(_ technician: Technician) {
        selectedTechnician = technician
        updateTechnicianButtonTitle()
        updateStatusPreview()  // ✅ Update status to "Assigned"
        updateSaveButtonState()  // ✅ Enable save button
        updatePredictedDeadline()  // ✅ Recalculate deadline with Assigned status
        print("✅ Selected technician: \(technician.name)")
        print("   Status will be: Assigned")
        print("   Save button enabled: true")
    }
}
