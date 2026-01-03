//
//  SubmittedTicketViewController.swift
//  RepairPro
//
//  Feature 3: Ticket Submitted Confirmation
//  Developer: Noof Abdullah [202204310]
//

import UIKit

class SubmittedTicketViewController: UIViewController {
    
    @IBOutlet weak var SubmittedDescription: UITextView!
    
    // Ticket data passed from PreviewTicketViewController
    var ticketNumber: Int = 0
    var ticketId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable the back button
        navigationItem.hidesBackButton = true
        
        // Display ticket info
        displayTicketInfo()
    }
    
    func displayTicketInfo() {
        SubmittedDescription.text = """
        Ticket #\(ticketNumber) has been submitted successfully!
        
        Your request has been received and will be reviewed by our maintenance team.
        
        You can track the status of your ticket in the "Current Requests" section.
        """
        
        SubmittedDescription.isEditable = false
    }
    
    @IBAction func DoneBtn(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
}
