//
//  PreviewTicketViewController.swift
//  RepairPro
//
//  Feature 3: Create Maintenance Request - Preview & Submit
//  Developer: Noof Abdullah [202204310]
//

import UIKit
import FirebaseFirestore

class PreviewTicketViewController: UIViewController {

    @IBOutlet weak var Campus: UITextField!
    @IBOutlet weak var Building: UITextField!
    @IBOutlet weak var Category: UITextField!
    @IBOutlet weak var Room: UITextField!
    @IBOutlet weak var Subject: UITextField!
    @IBOutlet weak var Description: UITextView!
    @IBOutlet weak var image: UIImageView!
    
    // Data passed from AddTicketViewController
    var campusText: String = ""
    var buildingText: String = ""
    var categoryText: String = ""
    var roomText: String = ""
    var subjectText: String = ""
    var descriptionText: String = ""
    var ticketImage: UIImage?
    
    // Loading indicator
    var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayTicketInfo()
        setupLoadingIndicator()
        
        // Make fields non-editable (this is preview only)
        Campus.isEnabled = false
        Building.isEnabled = false
        Category.isEnabled = false
        Room.isEnabled = false
        Subject.isEnabled = false
        Description.isEditable = false
    }
    
    // MARK: - Display Data
    func displayTicketInfo() {
        Campus.text = campusText
        Building.text = buildingText
        Category.text = categoryText
        Room.text = roomText
        Subject.text = subjectText
        Description.text = descriptionText
        
        if let ticketImage = ticketImage {
            image.image = ticketImage
        }
    }
    
    // MARK: - Setup Loading Indicator
    func setupLoadingIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
    }
    
    // MARK: - Confirm Button
    @IBAction func ConfirmBtnClicked(_ sender: Any) {
        // Use mock user instead of Firebase Auth
        let userId = CurrentUser.getUserId()
        let userName = CurrentUser.getUserName()
        
        // Show loading
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        
        // Create ticket
        createTicket(userId: userId, userName: userName)
    }
    
    func createTicket(userId: String, userName: String) {
        Ticket.create(
            title: subjectText,
            description: descriptionText,
            category: categoryText,
            campus: campusText,
            building: buildingText,
            roomNumber: roomText,
            image: ticketImage,
            userId: userId,
            userName: userName
        ) { [weak self] result in
            guard let self = self else { return }
            
            self.hideLoading()
            
            switch result {
            case .success(let (ticketId, ticketNumber)):
                print("✅ Ticket created! ID: \(ticketId), Number: \(ticketNumber)")
                self.showSuccessAlert(ticketNumber: ticketNumber)
                
            case .failure(let error):
                self.showAlert(title: "Error", message: "Failed to create ticket: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Success Alert
    func showSuccessAlert(ticketNumber: Int) {
        // Navigate to Submitted Ticket page
        if let submittedVC = storyboard?.instantiateViewController(withIdentifier: "submittedTicket") as? SubmittedTicketViewController {
            // Pass ticket data
            submittedVC.ticketNumber = ticketNumber
            
            // Navigate
            navigationController?.pushViewController(submittedVC, animated: true)
        } else {
            // Fallback: Show alert if storyboard ID not found
            let alert = UIAlertController(
                title: "Ticket Submitted!",
                message: "Your ticket #\(ticketNumber) has been created successfully.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.navigationController?.popToRootViewController(animated: true)
            })
            
            present(alert, animated: true)
        }
    }
    
    // MARK: - Helpers
    func hideLoading() {
        activityIndicator.stopAnimating()
        view.isUserInteractionEnabled = true
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
