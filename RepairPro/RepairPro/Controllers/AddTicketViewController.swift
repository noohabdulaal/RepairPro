//
//  AddTicketViewController.swift
//  RepairPro
//
//  Feature 3: Create Maintenance Request
//  Developer: Noof Abdullah [202204310]
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class AddTicketViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var Campus: UITextField!
    @IBOutlet weak var Building: UITextField!
    @IBOutlet weak var Category: UITextField!
    @IBOutlet weak var RoomNumber: UITextField!
    @IBOutlet weak var Subject: UITextField!
    @IBOutlet weak var Description: UITextView!
    @IBOutlet weak var Image: UIImageView!
    
    // Data arrays
    var categories: [String] = ["IT", "Electrical", "AC", "Plumbing", "Furniture", "Cleaning"]
    var campuses: [String] = ["Campus A", "Campus B"]
    var buildings: [String] = []
    
    // Pickers
    let categoryPicker = UIPickerView()
    let campusPicker = UIPickerView()
    let buildingPicker = UIPickerView()
    
    // Selected image
    var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPickers()
        setupDescriptionPlaceholder()
        loadCategoriesFromFirebase()
        loadLocationsFromFirebase()
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
        Campus.inputView = campusPicker
        
        // Building Picker
        buildingPicker.delegate = self
        buildingPicker.dataSource = self
        Building.inputView = buildingPicker
        
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
        Campus.inputAccessoryView = toolbar
        Building.inputAccessoryView = toolbar
    }
    
    @objc func dismissPicker() {
        view.endEditing(true)
    }
    
    // MARK: - Description Placeholder
    func setupDescriptionPlaceholder() {
        Description.text = "Describe the ongoing issues..."
        Description.textColor = UIColor.lightGray
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
                // Keep default categories if Firebase fails
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
                // Keep default campuses if Firebase fails
            }
        }
    }
    
    func loadBuildingsForCampus(_ campusName: String) {
        LocationManager.fetchBuildingNames(forCampus: campusName) { [weak self] result in
            switch result {
            case .success(let fetchedBuildings):
                self?.buildings = fetchedBuildings
                self?.buildingPicker.reloadAllComponents()
                
                // Clear building field when campus changes
                self?.Building.text = ""
                
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
            Campus.text = campuses[row]
            // Load buildings for selected campus
            loadBuildingsForCampus(campuses[row])
        } else if pickerView == buildingPicker {
            if !buildings.isEmpty {
                Building.text = buildings[row]
            }
        }
    }
    
    // MARK: - Upload Image
    @IBAction func uploadImage(_ sender: Any) {
        let alert = UIAlertController(title: "Choose Image Source", message: nil, preferredStyle: .actionSheet)
        
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
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImage = originalImage
            Image.image = originalImage
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    // MARK: - Continue Button
    @IBAction func `continue`(_ sender: Any) {
        // Validate inputs
        guard let campus = Campus.text, !campus.isEmpty else {
            showAlert(message: "Please select a campus")
            return
        }
        
        guard let building = Building.text, !building.isEmpty else {
            showAlert(message: "Please select a building")
            return
        }
        
        guard let category = Category.text, !category.isEmpty else {
            showAlert(message: "Please select a category")
            return
        }
        
        guard let roomNumber = RoomNumber.text, !roomNumber.isEmpty else {
            showAlert(message: "Please enter a room number")
            return
        }
        
        guard let subject = Subject.text, !subject.isEmpty else {
            showAlert(message: "Please enter a subject")
            return
        }
        
        guard let description = Description.text,
              !description.isEmpty,
              description != "Describe the ongoing issues..." else {
            showAlert(message: "Please describe the issue")
            return
        }
        
        // Navigate to preview
       // performSegue(withIdentifier: "toPreview", sender: nil)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPreview" {
            if let previewVC = segue.destination as? PreviewTicketViewController {
                // Pass data to preview
                previewVC.campusText = Campus.text ?? ""
                previewVC.buildingText = Building.text ?? ""
                previewVC.categoryText = Category.text ?? ""
                previewVC.roomText = RoomNumber.text ?? ""
                previewVC.subjectText = Subject.text ?? ""
                previewVC.descriptionText = Description.text ?? ""
                previewVC.ticketImage = selectedImage
            }
        }
    }
    
    // MARK: - Helper
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Missing Information", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextView Delegate (for placeholder)
extension AddTicketViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Describe the ongoing issues..."
            textView.textColor = UIColor.lightGray
        }
    }
}
