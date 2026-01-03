//
//  RateFeedbackViewController.swift
//  RepairPro
//
//  Feature 4: Rate & Feedback
//  Developer: Noof Abdullah [202204310]
//

import UIKit
import FirebaseFirestore

class RateFeedbackViewController: UIViewController {

    @IBOutlet weak var refrenceNo: UILabel!
    @IBOutlet weak var Status: UILabel!
    @IBOutlet weak var subject: UILabel!
    @IBOutlet weak var campus: UILabel!
    @IBOutlet weak var roomNo: UILabel!
    @IBOutlet weak var buildingNo: UILabel!
    @IBOutlet weak var Description: UILabel!
    @IBOutlet weak var image: UIImageView!
    
    @IBOutlet weak var star1: UIImageView!
    @IBOutlet weak var star2: UIImageView!
    @IBOutlet weak var star3: UIImageView!
    @IBOutlet weak var star4: UIImageView!
    @IBOutlet weak var star5: UIImageView!
    
    @IBOutlet weak var Feedback: UITextField!
    
    // Ticket data passed from previous screen
    var ticket: Ticket?
    
    // Selected rating (1-5)
    var selectedRating: Int = 0
    
    // Star images array for easy access
    var starImages: [UIImageView] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup star images array
        starImages = [star1, star2, star3, star4, star5]
        
        // Add tap gestures to stars
        setupStarTapGestures()
        
        // Display ticket data
        if let ticket = ticket {
            displayTicketInfo(ticket)
        }
    }
    
    // MARK: - Display Ticket Info
    func displayTicketInfo(_ ticket: Ticket) {
        refrenceNo.text = "#\(ticket.ticketNumber)"
        Status.text = ticket.status.rawValue
        subject.text = ticket.title
        campus.text = ticket.campus
        roomNo.text = ticket.roomNumber
        buildingNo.text = ticket.building
        Description.text = ticket.description
        
        // Load image if exists
        if let imageUrl = ticket.imageUrl, let url = URL(string: imageUrl) {
            loadImage(from: url)
        } else {
            image.image = UIImage(systemName: "photo")
        }
    }
    
    func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let data = data, let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.image.image = loadedImage
                }
            }
        }.resume()
    }
    
    // MARK: - Setup Star Tap Gestures
    func setupStarTapGestures() {
        for (index, star) in starImages.enumerated() {
            star.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(starTapped(_:)))
            star.tag = index + 1 // Tag: 1-5
            star.addGestureRecognizer(tapGesture)
            
            // Set initial empty star
            star.image = UIImage(systemName: "star")
            star.tintColor = .systemYellow
        }
    }
    
    @objc func starTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedStar = sender.view as? UIImageView else { return }
        
        selectedRating = tappedStar.tag
        updateStars(rating: selectedRating)
    }
    
    func updateStars(rating: Int) {
        for (index, star) in starImages.enumerated() {
            if index < rating {
                // Fill star
                star.image = UIImage(systemName: "star.fill")
                star.tintColor = .systemYellow
            } else {
                // Empty star
                star.image = UIImage(systemName: "star")
                star.tintColor = .systemYellow
            }
        }
    }
    
    // MARK: - Confirm Button
    @IBAction func Confirmbutton(_ sender: Any) {
        // Validate rating
        guard selectedRating > 0 else {
            showAlert(title: "Missing Rating", message: "Please select a star rating")
            return
        }
        
        guard let ticket = ticket,
              let ticketId = ticket.id else {
            showAlert(title: "Error", message: "Unable to submit feedback")
            return
        }
        
        // Use mock user instead of Firebase Auth
        let userId = CurrentUser.getUserId()
        let userName = CurrentUser.getUserName()
        
        let feedbackComment = self.Feedback.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Show loading
        self.showLoading()
        
        // Submit feedback to Firebase
        RepairPro.Feedback.submit(
            ticketId: ticketId,
            userId: userId,
            userName: userName,
            rating: self.selectedRating,
            comment: feedbackComment?.isEmpty == false ? feedbackComment : nil
        ) { result in
            self.hideLoading()
            
            switch result {
            case .success:
                self.showSuccessAndNavigateBack()
                
            case .failure(let error):
                self.showAlert(title: "Error", message: "Failed to submit feedback: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Success & Navigation
    func showSuccessAndNavigateBack() {
        let alert = UIAlertController(
            title: "Thank You!",
            message: "Your feedback has been submitted successfully",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            // Navigate back to previous screen
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Loading Indicator
    var loadingAlert: UIAlertController?
    
    func showLoading() {
        loadingAlert = UIAlertController(title: nil, message: "Submitting feedback...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert?.view.addSubview(loadingIndicator)
        present(loadingAlert!, animated: true)
    }
    
    func hideLoading() {
        loadingAlert?.dismiss(animated: true)
    }
    
    // MARK: - Helper
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
