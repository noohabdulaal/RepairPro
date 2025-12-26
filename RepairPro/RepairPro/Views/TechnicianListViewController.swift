import UIKit

final class TechnicianListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    // MARK: - Outlets
    @IBOutlet weak var sectionContainerView: UIView!
    @IBOutlet weak var searchContainerView: UIView!
    @IBOutlet weak var departmentDropdownView: UIView!
    @IBOutlet weak var addTechnicianButton: UIButton!
    @IBOutlet weak var tableView: UITableView!

    // Add these outlets in storyboard (recommended)
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var departmentValueLabel: UILabel!
    
    // MARK: - Model
    struct Technician: Equatable {
        let id: UUID
        var name: String
        var department: String
        var phone: String
    }

    private var technicians: [Technician] = []
    private var filtered: [Technician] = []

    private var selectedDepartment: String? = nil  // nil = All Departments
    private var selectedForEdit: Technician?

    private var searchText: String {
        (searchTextField?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var displayedTechnicians: [Technician] {
        filtered
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Test data (replace later with Firebase)
        technicians = [
            .init(id: UUID(), name: "Ahmed Darwish", department: "IT Support", phone: "+973 3321 8745"),
            .init(id: UUID(), name: "Sara Mansoor", department: "Maintenance", phone: "+973 3952 1067"),
            .init(id: UUID(), name: "Khalid Haddad", department: "Facilities", phone: "+973 3664 9821"),
            .init(id: UUID(), name: "Ahmed Darwish Senior IT Infrastructure & Systems Administrator", department: "Network & Systems Operations Department", phone: "+973 3333 3333"),
        ]
        applyFiltersAndReload()

        tableView.dataSource = self
        tableView.delegate = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
        tableView.separatorStyle = .none

        // Good defaults for your design
        tableView.backgroundColor = view.backgroundColor
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 120, right: 0) // bottom room for future nav
        tableView.scrollIndicatorInsets = tableView.contentInset

        // Search
        searchTextField?.delegate = self
        searchTextField?.addTarget(self, action: #selector(searchChanged), for: .editingChanged)

        // Dropdown tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(departmentDropdownTapped))
        departmentDropdownView.addGestureRecognizer(tap)
        departmentDropdownView.isUserInteractionEnabled = true

        // Styling (keep yours if you want — not the main part here)
        styleScreenBackground()
        styleSectionContainer()
        styleSearchBar()
        styleDepartmentDropdown()
        styleAddTechnicianButton()

        departmentValueLabel?.text = "All Departments"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        sectionContainerView.layer.shadowPath = UIBezierPath(
            roundedRect: sectionContainerView.bounds,
            cornerRadius: 16
        ).cgPath
    }

    // MARK: - Actions
    @IBAction func addTechnicianTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showAddTechnician", sender: nil)
    }

    @objc private func searchChanged() {
        applyFiltersAndReload()
    }

    @objc private func departmentDropdownTapped() {
        view.endEditing(true)

        let allDepartments = Array(Set(technicians.map { $0.department })).sorted()

        let sheet = UIAlertController(title: "Department", message: nil, preferredStyle: .actionSheet)

        sheet.addAction(UIAlertAction(title: "All Departments", style: .default) { [weak self] _ in
            self?.selectedDepartment = nil
            self?.departmentValueLabel?.text = "All Departments"
            self?.applyFiltersAndReload()
        })

        for dept in allDepartments {
            sheet.addAction(UIAlertAction(title: dept, style: .default) { [weak self] _ in
                self?.selectedDepartment = dept
                self?.departmentValueLabel?.text = dept
                self?.applyFiltersAndReload()
            })
        }

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad safety (doesn’t hurt on iPhone)
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = departmentDropdownView
            pop.sourceRect = departmentDropdownView.bounds
        }

        present(sheet, animated: true)
    }

    // MARK: - Filtering
    private func applyFiltersAndReload() {
        let text = searchText.lowercased()

        filtered = technicians.filter { tech in
            let matchesDept = (selectedDepartment == nil) || (tech.department == selectedDepartment)

            if text.isEmpty {
                return matchesDept
            }

            let matchesText =
                tech.name.lowercased().contains(text) ||
                tech.department.lowercased().contains(text) ||
                tech.phone.lowercased().contains(text)

            return matchesDept && matchesText
        }

        tableView.reloadData()
    }

    // MARK: - Delete
    private func confirmDelete(_ tech: Technician) {
        let alert = UIAlertController(
            title: "Confirmation",
            message: "Are you sure you want to delete this technician?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.technicians.removeAll { $0.id == tech.id }
            self.applyFiltersAndReload()
        })

        present(alert, animated: true)
    }

    // MARK: - Table Data
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedTechnicians.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let tech = displayedTechnicians[indexPath.row]

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "TechnicianCell",
            for: indexPath
        ) as! TechnicianTableViewCell

        cell.configure(name: tech.name, department: tech.department, phone: tech.phone)

        cell.onEditTapped = { [weak self] in
            self?.selectedForEdit = tech
            self?.performSegue(withIdentifier: "showEditTechnician", sender: nil)
        }

        cell.onDeleteTapped = { [weak self] in
            self?.confirmDelete(tech)
        }

        return cell
    }

    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEditTechnician",
           let editVC = segue.destination as? EditTechnicianViewController {
            editVC.technicianName = selectedForEdit?.name ?? ""
        }
    }

    // MARK: - Styling (keep yours)
    private func styleScreenBackground() {
        view.backgroundColor = UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
    }

    private func styleSectionContainer() {
        sectionContainerView.backgroundColor = UIColor(red: 232/255, green: 232/255, blue: 238/255, alpha: 1)
        sectionContainerView.layer.cornerRadius = 16
        sectionContainerView.layer.masksToBounds = false
        sectionContainerView.layer.shadowColor = UIColor.black.cgColor
        sectionContainerView.layer.shadowOpacity = 0.15
        sectionContainerView.layer.shadowRadius = 8
        sectionContainerView.layer.shadowOffset = CGSize(width: 0, height: 3)
    }

    private func styleSearchBar() {
        searchContainerView.backgroundColor = UIColor(red: 220/255, green: 220/255, blue: 225/255, alpha: 1)
        searchContainerView.layer.cornerRadius = 12
        searchContainerView.layer.masksToBounds = true
    }

    private func styleDepartmentDropdown() {
        departmentDropdownView.backgroundColor = .white
        departmentDropdownView.layer.cornerRadius = 12
        departmentDropdownView.layer.borderWidth = 1
        departmentDropdownView.layer.borderColor = UIColor(red: 209/255, green: 209/255, blue: 214/255, alpha: 1).cgColor
    }

    private func styleAddTechnicianButton() {
        addTechnicianButton.layer.cornerRadius = 12
        addTechnicianButton.layer.masksToBounds = true
    }
}
