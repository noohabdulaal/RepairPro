import UIKit

class TechnicianTableViewCell: UITableViewCell {

    // MARK: - IBOutlets
    @IBOutlet weak var cardContainerView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var departmentLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    var onEditTapped: (() -> Void)?
    var onDeleteTapped: (() -> Void)?

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        setupCardStyle()
        setupButtons()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        cardContainerView.layer.shadowPath = UIBezierPath(
            roundedRect: cardContainerView.bounds,
            cornerRadius: 16
        ).cgPath
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        departmentLabel.text = nil
        phoneLabel.text = nil
    }

    // MARK: - Configuration
    func configure(name: String, department: String, phone: String) {
        nameLabel.text = name
        departmentLabel.text = department
        phoneLabel.text = phone
    }

    // MARK: - Styling

    private func setupCardStyle() {
        // 🔹 Slightly darker than background (Figma match)
        cardContainerView.backgroundColor = UIColor(
            red: 250/255,
            green: 250/255,
            blue: 252/255,
            alpha: 1
        )

        cardContainerView.layer.cornerRadius = 16
        cardContainerView.layer.masksToBounds = false

        // 🔹 Subtle depth shadow (NOT floating)
        cardContainerView.layer.shadowColor = UIColor.black.cgColor
        cardContainerView.layer.shadowOpacity = 0.08
        cardContainerView.layer.shadowRadius = 6
        cardContainerView.layer.shadowOffset = CGSize(width: 0, height: 3)

        cardContainerView.layer.shouldRasterize = true
        cardContainerView.layer.rasterizationScale = UIScreen.main.scale
    }

    private func setupButtons() {
        editButton.configurationUpdateHandler = { button in
            button.alpha = button.isHighlighted ? 0.6 : 1
        }

        deleteButton.configurationUpdateHandler = { button in
            button.alpha = button.isHighlighted ? 0.6 : 1
        }
    }

    // MARK: - Actions
    @IBAction func editButtonTapped(_ sender: UIButton) {
        onEditTapped?()
    }

    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        onDeleteTapped?()
    }
}
