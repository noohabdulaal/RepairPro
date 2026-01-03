//
//  TechnicianPickerViewController.swift (UPDATED - Design 1: Modern Cards)
//  RepairPro
//
//  Modern card-based picker with avatars and smooth animations
//

import UIKit

class TechnicianPickerViewController: UIViewController {
    
    // MARK: - Properties
    var technicians: [Technician] = []
    var selectedTechnician: Technician?
    weak var delegate: TechnicianPickerDelegate?
    
    // MARK: - UI Components
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Select Technician"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose who will handle this ticket"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.register(ModernTechnicianCell.self, forCellReuseIdentifier: "ModernTechnicianCell")
        table.separatorStyle = .none
        table.backgroundColor = .systemBackground
        table.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.backgroundColor = UIColor(white: 0.95, alpha: 1)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Assign Technician", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.backgroundColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1).cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 15
        button.layer.shadowOpacity = 0.3
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        button.isEnabled = selectedTechnician != nil
        button.alpha = selectedTechnician != nil ? 1.0 : 0.5
        return button
    }()
    
    private lazy var buttonStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [cancelButton, confirmButton])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Add subtle animation on appear
        view.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.view.alpha = 1
        }
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add header
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(subtitleLabel)
        
        // Add table view
        view.addSubview(tableView)
        
        // Add buttons
        view.addSubview(buttonStackView)
        
        NSLayoutConstraint.activate([
            // Header view
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            // Subtitle label
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            // Table view
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -16),
            
            // Button stack
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            buttonStackView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 0
        }) { _ in
            self.dismiss(animated: false)
        }
    }
    
    @objc private func confirmTapped() {
        guard let technician = selectedTechnician else { return }
        
        // Animate button press
        UIView.animate(withDuration: 0.1, animations: {
            self.confirmButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.confirmButton.transform = .identity
            }
        }
        
        // Notify delegate
        delegate?.didSelectTechnician(technician)
        
        // Dismiss with animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UIView.animate(withDuration: 0.2, animations: {
                self.view.alpha = 0
            }) { _ in
                self.dismiss(animated: false)
            }
        }
    }
    
    private func updateConfirmButton() {
        UIView.animate(withDuration: 0.3) {
            self.confirmButton.isEnabled = self.selectedTechnician != nil
            self.confirmButton.alpha = self.selectedTechnician != nil ? 1.0 : 0.5
            
            if self.selectedTechnician != nil {
                self.confirmButton.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.confirmButton.transform = .identity
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension TechnicianPickerViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return technicians.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ModernTechnicianCell", for: indexPath) as! ModernTechnicianCell
        let technician = technicians[indexPath.row]
        let isSelected = selectedTechnician?.id == technician.id
        
        cell.configure(with: technician, isSelected: isSelected)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TechnicianPickerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let technician = technicians[indexPath.row]
        selectedTechnician = technician
        
        // Update all cells
        tableView.reloadData()
        
        // Update confirm button
        updateConfirmButton()
        
        // Add haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
}

// MARK: - Modern Technician Cell
class ModernTechnicianCell: UITableViewCell {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 248/255, green: 249/255, blue: 1, alpha: 1)
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor(red: 232/255, green: 236/255, blue: 1, alpha: 1).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1)
        view.layer.cornerRadius = 25
        view.layer.shadowColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1).cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.3
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusDot: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 82/255, green: 196/255, blue: 26/255, alpha: 1)
        view.layer.cornerRadius = 3
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Available"
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(red: 82/255, green: 196/255, blue: 26/255, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let checkIconView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.systemGray4.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let checkLabel: UILabel = {
        let label = UILabel()
        label.text = "✓"
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .clear
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let shimmerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 0.1)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(shimmerView)
        containerView.addSubview(avatarView)
        avatarView.addSubview(avatarLabel)
        containerView.addSubview(nameLabel)
        containerView.addSubview(statusDot)
        containerView.addSubview(statusLabel)
        containerView.addSubview(checkIconView)
        checkIconView.addSubview(checkLabel)
        
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            // Shimmer view (for animation)
            shimmerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            shimmerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            shimmerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            shimmerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Avatar view
            avatarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            avatarView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 50),
            avatarView.heightAnchor.constraint(equalToConstant: 50),
            
            // Avatar label
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            // Name label
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 15),
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            
            // Status dot
            statusDot.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 15),
            statusDot.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            statusDot.widthAnchor.constraint(equalToConstant: 6),
            statusDot.heightAnchor.constraint(equalToConstant: 6),
            
            // Status label
            statusLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 5),
            statusLabel.centerYAnchor.constraint(equalTo: statusDot.centerYAnchor),
            
            // Check icon view
            checkIconView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            checkIconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            checkIconView.widthAnchor.constraint(equalToConstant: 24),
            checkIconView.heightAnchor.constraint(equalToConstant: 24),
            
            // Check label
            checkLabel.centerXAnchor.constraint(equalTo: checkIconView.centerXAnchor),
            checkLabel.centerYAnchor.constraint(equalTo: checkIconView.centerYAnchor)
        ])
    }
    
    // MARK: - Configuration
    func configure(with technician: Technician, isSelected: Bool) {
        nameLabel.text = technician.name
        
        // Set avatar initials
        let initials = technician.name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()
        avatarLabel.text = initials
        
        // Update selection state with animation
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
            if isSelected {
                self.containerView.layer.borderColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1).cgColor
                self.containerView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
                self.checkIconView.layer.borderColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1).cgColor
                self.checkLabel.textColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1)
                self.containerView.layer.shadowColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1).cgColor
                self.containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
                self.containerView.layer.shadowRadius = 12
                self.containerView.layer.shadowOpacity = 0.2
            } else {
                self.containerView.layer.borderColor = UIColor(red: 232/255, green: 236/255, blue: 1, alpha: 1).cgColor
                self.containerView.transform = .identity
                self.checkIconView.layer.borderColor = UIColor.systemGray4.cgColor
                self.checkLabel.textColor = .clear
                self.containerView.layer.shadowOpacity = 0
            }
        }
    }
    
    // MARK: - Hover Effect (for interaction)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.containerView.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5) {
            self.containerView.transform = .identity
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.2) {
            self.containerView.transform = .identity
        }
    }
}
