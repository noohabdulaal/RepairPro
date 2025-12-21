import UIKit

class TechnicianTableViewCell: UITableViewCell {

    // MARK: - IBOutlets
    @IBOutlet weak var cardContainerView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var departmentLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none   // No gray highlight
        setupCardStyle()
        setupLabels()
        setupButtons()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Keep shadow correct for dynamic height cells
        cardContainerView.layer.shadowPath = UIBezierPath(
            roundedRect: cardContainerView.bounds,
            cornerRadius: 16
        ).cgPath
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        // Reset reused content
        nameLabel.text = nil
        departmentLabel.text = nil
        phoneLabel.text = nil
    }

    // MARK: - Public Configuration
    func configure(name: String, department: String, phone: String) {
        nameLabel.text = name
        departmentLabel.text = department
        phoneLabel.text = phone
    }

    // MARK: - Styling

    private func setupCardStyle() {
        cardContainerView.backgroundColor = .white
        cardContainerView.layer.cornerRadius = 16
        cardContainerView.layer.masksToBounds = false

        // Figma-style bottom shadow
        cardContainerView.layer.shadowColor = UIColor.black.cgColor
        cardContainerView.layer.shadowOpacity = 0.18
        cardContainerView.layer.shadowRadius = 12
        cardContainerView.layer.shadowOffset = CGSize(width: 0, height: 8)
    }

    private func setupLabels() {
        nameLabel.numberOfLines = 0
        departmentLabel.numberOfLines = 0
        phoneLabel.numberOfLines = 1

        nameLabel.lineBreakMode = .byWordWrapping
        departmentLabel.lineBreakMode = .byWordWrapping
    }

    private func setupButtons() {
        editButton.configurationUpdateHandler = { button in
            button.alpha = button.isHighlighted ? 0.6 : 1.0
        }

        deleteButton.configurationUpdateHandler = { button in
            button.alpha = button.isHighlighted ? 0.6 : 1.0
        }
    }

    // MARK: - Button Actions (temporary debug)
    @IBAction func editButtonTapped(_ sender: UIButton) {
        print("Edit tapped")
    }

    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        print("Delete tapped")
    }
}
