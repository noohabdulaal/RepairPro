import UIKit

final class TechnicianListViewController: UIViewController,
                                         UITableViewDataSource,
                                         UITableViewDelegate,
                                         UITextFieldDelegate {

    // MARK: - Outlets
    @IBOutlet weak var sectionContainerView: UIView!
    @IBOutlet weak var searchContainerView: UIView!
    @IBOutlet weak var departmentDropdownView: UIView!
    @IBOutlet weak var addTechnicianButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var departmentArrowImageView: UIImageView!
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
    private var selectedDepartment: String? = nil
    private var selectedForEdit: Technician?

    // ✅ NEW: prevents double-trigger / double-rotation while sheet is open
    private var isDepartmentSheetOpen = false

    private var searchText: String {
        searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        technicians = [
            .init(id: UUID(), name: "Ahmed Darwish", department: "IT Support", phone: "+973 3321 8745"),
            .init(id: UUID(), name: "Sara Mansoor", department: "Maintenance", phone: "+973 3952 1067"),
            .init(id: UUID(), name: "Khalid Haddad", department: "Facilities", phone: "+973 3664 9821"),
            .init(id: UUID(),
                  name: "Ahmed Darwish Senior IT Infrastructure & Systems Administrator",
                  department: "Network & Systems Operations Department",
                  phone: "+973 3333 3333")
        ]

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
        tableView.backgroundColor = view.backgroundColor

        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 120, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset

        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)

        let tap = UITapGestureRecognizer(target: self, action: #selector(departmentDropdownTapped))
        departmentDropdownView.addGestureRecognizer(tap)
        departmentDropdownView.isUserInteractionEnabled = true

        styleScreenBackground()
        styleSectionContainer()
        styleSearchBar()
        styleDepartmentDropdown()
        styleAddTechnicianButton()

        departmentValueLabel.text = "All Departments"
        applyFiltersAndReload()
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
        sender.animateAndThen {
            self.performSegue(withIdentifier: "showAddTechnician", sender: nil)
        }
    }

    @objc private func searchChanged() {
        applyFiltersAndReload()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Dropdown (FIXED: no double 180, tint lasts a bit longer)
    @objc private func departmentDropdownTapped() {
        view.endEditing(true)

        // ✅ stop double-tap double-rotation while the sheet is open
        guard !isDepartmentSheetOpen else { return }
        isDepartmentSheetOpen = true

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Rotate once to “open” state (180° looks most natural for chevron-down → chevron-up)
        UIView.animate(withDuration: 0.15) {
            self.departmentArrowImageView.transform = CGAffineTransform(rotationAngle: .pi)
        }

        // Darker highlight + lasts a bit longer, then fades back (even while sheet is open)
        departmentDropdownView.backgroundColor = UIColor(white: 0.93, alpha: 1)   // darker than before
        UIView.animate(withDuration: 0.18, delay: 0.22, options: [.curveEaseOut]) { // lasts a bit longer
            self.departmentDropdownView.backgroundColor = UIColor(white: 0.97, alpha: 1)
        }

        let departments = Array(Set(technicians.map { $0.department })).sorted()
        let sheet = UIAlertController(title: "Department", message: nil, preferredStyle: .actionSheet)

        // helper to reset arrow + unlock taps when sheet closes
        func closeSheetUI() {
            UIView.animate(withDuration: 0.15) {
                self.departmentArrowImageView.transform = .identity
            }
            self.isDepartmentSheetOpen = false
        }

        sheet.addAction(UIAlertAction(title: "All Departments", style: .default) { _ in
            self.selectedDepartment = nil
            self.departmentValueLabel.text = "All Departments"
            self.applyFiltersAndReload()
            closeSheetUI()
        })

        for dept in departments {
            sheet.addAction(UIAlertAction(title: dept, style: .default) { _ in
                self.selectedDepartment = dept
                self.departmentValueLabel.text = dept
                self.applyFiltersAndReload()
                closeSheetUI()
            })
        }

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            closeSheetUI()
        })

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
            let matchesDept = selectedDepartment == nil || tech.department == selectedDepartment
            if text.isEmpty { return matchesDept }
            return matchesDept &&
                (tech.name.lowercased().contains(text) ||
                 tech.department.lowercased().contains(text) ||
                 tech.phone.lowercased().contains(text))
        }

        tableView.reloadData()
    }

    // MARK: - Delete
    private func confirmDelete(_ tech: Technician) {
        let alert = UIAlertController(
            title: "Delete Technician",
            message: "Are you sure you want to delete \"\(tech.name)\"?\nThis action cannot be undone.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.technicians.removeAll { $0.id == tech.id }
            self.applyFiltersAndReload()
        })

        present(alert, animated: true)
    }

    // MARK: - Table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filtered.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let tech = filtered[indexPath.row]

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "TechnicianCell",
            for: indexPath
        ) as! TechnicianTableViewCell

        cell.configure(name: tech.name, department: tech.department, phone: tech.phone)

        cell.onEditTapped = {
            self.selectedForEdit = tech
            self.performSegue(withIdentifier: "showEditTechnician", sender: nil)
        }

        cell.onDeleteTapped = {
            self.confirmDelete(tech)
        }

        return cell
    }

    // MARK: - Styling
    private func styleScreenBackground() {
        view.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
    }

    private func styleSectionContainer() {
        sectionContainerView.backgroundColor = UIColor(white: 0.97, alpha: 1)
        sectionContainerView.layer.cornerRadius = 16
        sectionContainerView.layer.shadowColor = UIColor.black.cgColor
        sectionContainerView.layer.shadowOpacity = 0.14
        sectionContainerView.layer.shadowRadius = 4
        sectionContainerView.layer.shadowOffset = CGSize(width: 0, height: 3)
    }

    private func styleSearchBar() {
        searchContainerView.backgroundColor = UIColor(white: 0.92, alpha: 1)
        searchContainerView.layer.cornerRadius = 12
    }

    private func styleDepartmentDropdown() {
        departmentDropdownView.backgroundColor = UIColor(white: 0.97, alpha: 1)
        departmentDropdownView.layer.cornerRadius = 12
        departmentDropdownView.layer.borderWidth = 1
        departmentDropdownView.layer.borderColor = UIColor.systemGray4.cgColor
    }

    private func styleAddTechnicianButton() {
        addTechnicianButton.layer.cornerRadius = 12
        addTechnicianButton.addPressAnimation()
    }
}
