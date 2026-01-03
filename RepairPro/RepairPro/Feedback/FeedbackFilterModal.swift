//
//  FeedbackFilterModal.swift
//  WITH DEBUG LOGS to diagnose the issue
//

import UIKit

class FeedbackFilterModal: UIViewController {
    
    // MARK: - Properties
    var applyFilters: ((String?) -> Void)?
    var availableTechnicians: [String] = []
    var selectedTechnician: String = "All Technicians"
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 24
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 10)
        view.layer.shadowRadius = 30
        view.layer.shadowOpacity = 0.3
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Filter by Technician"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap to select"
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.delegate = self
        cv.dataSource = self
        cv.register(TechnicianCardCell.self, forCellWithReuseIdentifier: "TechnicianCardCell")
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.isUserInteractionEnabled = true  // Enable interaction
        cv.allowsSelection = true  // Allow selection
        return cv
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.backgroundColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 14
        button.layer.shadowColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1).cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 16
        button.layer.shadowOpacity = 0.3
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🎯 FeedbackFilterModal viewDidLoad")
        print("📋 Initial technicians: \(availableTechnicians)")
        print("✅ Initial selection: \(selectedTechnician)")
        
        setupUI()
        
        // Add "All Technicians" if not present
        if !availableTechnicians.contains("All Technicians") {
            availableTechnicians.insert("All Technicians", at: 0)
            print("➕ Added 'All Technicians' to list")
        }
        
        print("📋 Final technicians: \(availableTechnicians)")
        
        // Animate appearance
        containerView.alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Tap to dismiss - but only on background, not on container
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        // Add container
        view.addSubview(containerView)
        
        // Add header
        containerView.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(subtitleLabel)
        
        // Round top corners of header
        headerView.layer.cornerRadius = 24
        headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // Add collection view
        containerView.addSubview(collectionView)
        
        // Add done button
        containerView.addSubview(doneButton)
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        print("✅ Done button target added")
        
        NSLayoutConstraint.activate([
            // Container
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.heightAnchor.constraint(equalToConstant: 550),
            
            // Header view
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 100),
            
            // Title label
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 28),
            
            // Subtitle label
            subtitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            
            // Collection view
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -16),
            
            // Done button
            doneButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            doneButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            doneButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            doneButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Actions
    @objc private func backgroundTapped() {
        print("🔘 Background tapped - dismissing without changes")
        dismissModal()
    }
    
    @objc private func doneTapped() {
        print("🔘 Done button tapped!")
        print("✅ Selected technician: '\(selectedTechnician)'")
        
        // Animate button press
        UIView.animate(withDuration: 0.1, animations: {
            self.doneButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.doneButton.transform = .identity
            }
        }
        
        // Apply filter
        let filterValue = selectedTechnician == "All Technicians" ? nil : selectedTechnician
        print("📤 Calling applyFilters with: \(filterValue ?? "nil (All Technicians)")")
        
        if applyFilters != nil {
            print("✅ applyFilters closure exists")
            applyFilters?(filterValue)
        } else {
            print("❌ ERROR: applyFilters closure is nil!")
        }
        
        // Dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            print("👋 Dismissing modal")
            self.dismissModal()
        }
    }
    
    private func dismissModal() {
        UIView.animate(withDuration: 0.2, animations: {
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
        }) { _ in
            self.dismiss(animated: false)
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension FeedbackFilterModal: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only allow tap gesture on background (not on containerView)
        let location = touch.location(in: view)
        let containerFrame = containerView.frame
        
        // If touch is inside container, don't trigger background tap
        if containerFrame.contains(location) {
            print("👆 Tap inside container - not dismissing")
            return false
        }
        
        print("👆 Tap outside container - will dismiss")
        return true
    }
}

// MARK: - UICollectionViewDataSource
extension FeedbackFilterModal: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("📊 CollectionView requested count: \(availableTechnicians.count)")
        return availableTechnicians.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TechnicianCardCell", for: indexPath) as! TechnicianCardCell
        let technician = availableTechnicians[indexPath.item]
        let isSelected = technician == selectedTechnician
        
        print("🎨 Configuring cell \(indexPath.item): '\(technician)' - Selected: \(isSelected)")
        
        cell.configure(with: technician, isSelected: isSelected)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension FeedbackFilterModal: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let newSelection = availableTechnicians[indexPath.item]
        print("👆 Cell tapped at index \(indexPath.item): '\(newSelection)'")
        print("   Previous selection: '\(selectedTechnician)'")
        
        selectedTechnician = newSelection
        print("   New selection: '\(selectedTechnician)'")
        
        collectionView.reloadData()
        print("   ✅ Collection view reloaded")
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        print("   📳 Haptic feedback triggered")
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FeedbackFilterModal: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 24 + 12
        let availableWidth = collectionView.bounds.width - padding
        let itemWidth = availableWidth / 2
        
        return CGSize(width: itemWidth, height: 110)
    }
}

// MARK: - Technician Card Cell
class TechnicianCardCell: UICollectionViewCell {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 248/255, green: 249/255, blue: 250/255, alpha: 1)
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor(red: 233/255, green: 236/255, blue: 239/255, alpha: 1).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1)
        view.layer.cornerRadius = 25
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
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let highlightView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 0.1)
        view.layer.cornerRadius = 16
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Enable interaction on cell
        contentView.isUserInteractionEnabled = true
        
        contentView.addSubview(containerView)
        containerView.addSubview(highlightView)
        containerView.addSubview(avatarView)
        avatarView.addSubview(avatarLabel)
        containerView.addSubview(nameLabel)
        
        // Make sure containerView doesn't block touches
        containerView.isUserInteractionEnabled = true
        highlightView.isUserInteractionEnabled = false
        avatarView.isUserInteractionEnabled = false
        nameLabel.isUserInteractionEnabled = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            highlightView.topAnchor.constraint(equalTo: containerView.topAnchor),
            highlightView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            highlightView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            highlightView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            avatarView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            avatarView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            avatarView.widthAnchor.constraint(equalToConstant: 50),
            avatarView.heightAnchor.constraint(equalToConstant: 50),
            
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8)
        ])
    }
    
    // MARK: - Configuration
    func configure(with technician: String, isSelected: Bool) {
        nameLabel.text = technician
        
        // Set avatar initials
        let initials: String
        if technician == "All Technicians" {
            initials = "ALL"
        } else {
            initials = technician.split(separator: " ")
                .prefix(2)
                .compactMap { $0.first }
                .map { String($0).uppercased() }
                .joined()
        }
        avatarLabel.text = initials
        
        // Update selection state with animation
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
            if isSelected {
                self.containerView.layer.borderColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1).cgColor
                self.highlightView.alpha = 1
                self.avatarView.backgroundColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1)
                
                self.containerView.layer.shadowColor = UIColor(red: 254/255, green: 162/255, blue: 20/255, alpha: 1).cgColor
                self.containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
                self.containerView.layer.shadowRadius = 12
                self.containerView.layer.shadowOpacity = 0.4
            } else {
                self.containerView.layer.borderColor = UIColor(red: 233/255, green: 236/255, blue: 239/255, alpha: 1).cgColor
                self.highlightView.alpha = 0
                self.avatarView.backgroundColor = UIColor(red: 0/255, green: 71/255, blue: 111/255, alpha: 1)
                
                self.containerView.layer.shadowOpacity = 0
            }
        }
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        print("👆 Cell touch began")
        UIView.animate(withDuration: 0.1) {
            self.containerView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        print("👆 Cell touch ended")
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
