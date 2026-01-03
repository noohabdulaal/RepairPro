//
//  EditTicketViewController.swift
//  RepairPro
//
//  Feature 4: Edit Ticket
//  Developer: Noof Abdullah [202204310]
//

import UIKit
import FirebaseFirestore

class EditTicketViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var campus: UITextField!
    @IBOutlet weak var building: UITextField!
    @IBOutlet weak var Category: UITextField!
    @IBOutlet weak var roomNumber: UITextField!
    @IBOutlet weak var Subject: UITextField!
    @IBOutlet weak var Description: UITextView!
    @IBOutlet weak var Image: UIImageView!
    
    // Ticket data passed from previous screen
    var ticket: Ticket?
    
    // Data arrays
    var categories: [String] = ["IT", "Electrical", "AC", "Plumbing", "Furniture", "Cleaning"]
    var campuses: [String] = ["Campus A", "Campus B"]
    var buildings: [String] = []
    
    // Pickers
    let categoryPicker = UIPickerView()
    let campusPicker = UIPickerView()
    let buildingPicker = UIPickerView()
    
    // Selected image (if user changes it)
    var selectedImage: UIImage?
    var hasChangedImage: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPickers()
        setupDescriptionPlaceholder()
        loadCategoriesFromFirebase()
        loadLocationsFromFirebase()
        
        // Display ticket data
        if let ticket = ticket {
            displayTicketInfo(ticket)
        }
    }
    
    // MARK: - Display Ticket Info
    func displayTicketInfo(_ ticket: Ticket) {
        campus.text = ticket.campus
        building.text = ticket.building
        Category.text = ticket.category
        roomNumber.text = ticket.roomNumber
        Subject.text = ticket.title
        Description.text = ticket.description
        
        // Load buildings for the current campus
        loadBuildingsForCampus(ticket.campus)
        
        // Load image if exists
        if let imageUrl = ticket.imageUrl, let url = URL(string: imageUrl) {
            loadImage(from: url)
        } else {
            Image.image = UIImage(systemName: "photo")
        }
    }
    
    func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let data = data, let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.Image.image = loadedImage
                }
            }
        }.resume()
    }
    
    // MARK: - Setup Pickers
    func setupPickers() {
        // Category Picker
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        Category.inputView = categoryPicker
        
        // Campus Picker
        campusPicker.delegate = self
        campusPicker.dataSource = self
        campus.inputView = campusPicker
        
        // Building Picker
        buildingPicker.delegate = self
        buildingPicker.dataSource = self
        building.inputView = buildingPicker
        
        // Add toolbar with Done button
        addToolbarToPickers()
    }
    
    func addToolbarToPickers() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissPicker))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexSpace, doneButton], animated: false)
        
        Category.inputAccessoryView = toolbar
        campus.inputAccessoryView = toolbar
        building.inputAccessoryView = toolbar
    }
    
    @objc func dismissPicker() {
        view.endEditing(true)
    }
    
    // MARK: - Description Placeholder
    func setupDescriptionPlaceholder() {
        Description.delegate = self
    }
    
    // MARK: - Load Data from Firebase
    func loadCategoriesFromFirebase() {
        RepairPro.Category.fetchCategoryNames { [weak self] result in
            switch result {
            case .success(let fetchedCategories):
                if !fetchedCategories.isEmpty {
                    self?.categories = fetchedCategories
                    self?.categoryPicker.reloadAllComponents()
                }
            case .failure(let error):
                print("Error loading categories: \(error.localizedDescription)")
            }
        }
    }
    
    func loadLocationsFromFirebase() {
        LocationManager.fetchCampusNames { [weak self] result in
            switch result {
            case .success(let fetchedCampuses):
                if !fetchedCampuses.isEmpty {
                    self?.campuses = fetchedCampuses
                    self?.campusPicker.reloadAllComponents()
                }
            case .failure(let error):
                print("Error loading campuses: \(error.localizedDescription)")
            }
        }
    }
    
    func loadBuildingsForCampus(_ campusName: String) {
        LocationManager.fetchBuildingNames(forCampus: campusName) { [weak self] result in
            switch result {
            case .success(let fetchedBuildings):
                self?.buildings = fetchedBuildings
                self?.buildingPicker.reloadAllComponents()
                
            case .failure(let error):
                print("Error loading buildings: \(error.localizedDescription)")
                self?.buildings = []
            }
        }
    }
    
    // MARK: - UIPickerView DataSource & Delegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == categoryPicker {
            return categories.count
        } else if pickerView == campusPicker {
            return campuses.count
        } else if pickerView == buildingPicker {
            return buildings.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == categoryPicker {
            return categories[row]
        } else if pickerView == campusPicker {
            return campuses[row]
        } else if pickerView == buildingPicker {
            return buildings.isEmpty ? "Select campus first" : buildings[row]
        }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == categoryPicker {
            Category.text = categories[row]
        } else if pickerView == campusPicker {
            campus.text = campuses[row]
            // Load buildings for selected campus
            loadBuildingsForCampus(campuses[row])
            building.text = "" // Clear building when campus changes
        } else if pickerView == buildingPicker {
            if !buildings.isEmpty {
                building.text = buildings[row]
            }
        }
    }
    
    // MARK: - Upload Image
    @IBAction func uploadImage(_ sender: Any) {
        let alert = UIAlertController(title: "Change Image", message: nil, preferredStyle: .actionSheet)
        
        // Camera option
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openImagePicker(sourceType: .camera)
        }))
        
        // Photo Library option
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            self.openImagePicker(sourceType: .photoLibrary)
        }))
        
        // Cancel
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = sourceType
            imagePicker.allowsEditing = true
            present(imagePicker, animated: true)
        }
    }
    
    // MARK: - UIImagePickerController Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImage = editedImage
            Image.image = editedImage
            hasChangedImage = true
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImage = originalImage
            Image.image = originalImage
            hasChangedImage = true
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    // MARK: - Save Details
    @IBAction func SaveDetails(_ sender: Any) {
        guard let ticket = ticket else { return }
        
        // Validate inputs
        guard let subject = Subject.text, !subject.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter a subject")
            return
        }
        
        guard let description = Description.text, !description.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter a description")
            return
        }
        
        guard let category = Category.text, !category.isEmpty else {
            showAlert(title: "Missing Information", message: "Please select a category")
            return
        }
        
        guard let roomNum = roomNumber.text, !roomNum.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter a room number")
            return
        }
        
        // Check if ticket is still editable
        guard ticket.isEditable else {
            showAlert(title: "Cannot Edit", message: "This ticket can no longer be edited")
            return
        }
        
        // Show confirmation modal
        showConfirmationAlert(ticket: ticket, subject: subject, description: description, category: category, roomNum: roomNum)
    }
    
    func showConfirmationAlert(ticket: Ticket, subject: String, description: String, category: String, roomNum: String) {
        let alert = UIAlertController(
            title: "Save Changes",
            message: "Are you sure you want to save these changes?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            self?.updateTicket(ticket: ticket, subject: subject, description: description, category: category, roomNum: roomNum)
        })
        
        present(alert, animated: true)
    }
    
    func updateTicket(ticket: Ticket, subject: String, description: String, category: String, roomNum: String) {
        // Show loading
        let loadingAlert = UIAlertController(title: nil, message: "Saving changes...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        present(loadingAlert, animated: true)
        
        // Update ticket in Firebase
        ticket.update(
            title: subject,
            description: description,
            category: category,
            roomNumber: roomNum
        ) { [weak self] result in
            guard let self = self else { return }
            
            // Dismiss loading
            loadingAlert.dismiss(animated: true) {
                switch result {
                case .success:
                    self.showSuccessAndNavigateBack()
                    
                case .failure(let error):
                    self.showAlert(title: "Error", message: "Failed to update ticket: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func showSuccessAndNavigateBack() {
        let alert = UIAlertController(
            title: "Success",
            message: "Ticket has been updated successfully",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            // Navigate back to previous screen
            self?.navigationController?.popViewController(animated: true)
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

// MARK: - UITextView Delegate (for placeholder if needed)
extension EditTicketViewController: UITextViewDelegate {
    // No placeholder needed since we're editing existing ticket
}
