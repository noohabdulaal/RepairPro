import UIKit

final class TechnicianTableViewCell: UITableViewCell {

    @IBOutlet weak var cardContainerView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var departmentLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!

    var onEditTapped: (() -> Void)?
    var onDeleteTapped: (() -> Void)?

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
        onEditTapped = nil
        onDeleteTapped = nil
    }

    func configure(name: String, department: String, phone: String) {
        nameLabel.text = name
        departmentLabel.text = department
        phoneLabel.text = phone
    }

    private func setupCardStyle() {
        cardContainerView.backgroundColor = UIColor(white: 0.97, alpha: 1)
        cardContainerView.layer.cornerRadius = 16
        cardContainerView.layer.shadowColor = UIColor.black.cgColor
        cardContainerView.layer.shadowOpacity = 0.14
        cardContainerView.layer.shadowRadius = 4
        cardContainerView.layer.shadowOffset = CGSize(width: 0, height: 3)
    }

    private func setupButtons() {
        editButton.addPressAnimation()
        deleteButton.addPressAnimation()

        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }

    @objc private func editTapped() {
        onEditTapped?()
    }

    @objc private func deleteTapped() {
        onDeleteTapped?()
    }
}
