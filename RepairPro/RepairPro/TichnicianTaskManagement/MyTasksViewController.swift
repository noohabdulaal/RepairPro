import UIKit

final class MyTasksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - UI Model (screen-specific, keeps you safe from teammate model changes)
    enum Status: String {
        case assigned = "Assigned"
        case inProgress = "In Progress"
        case completed = "Completed"
    }

    enum Priority {
        case low, medium, high

        var tint: UIColor {
            switch self {
            case .low: return .systemGreen
            case .medium: return .systemYellow
            case .high: return .systemRed
            }
        }
    }

    struct TicketUI {
        let id: Int
        let due: Date
        let subject: String
        let status: Status
        let campus: String
        let location: String
        let priority: Priority
    }

    // MARK: - Sample Data (replace later with Firebase)
    private lazy var tickets: [TicketUI] = [
        .init(id: 4325, due: Self.makeDate("2025-10-25"), subject: "Light switch broken", status: .inProgress, campus: "Campus A", location: "19.120", priority: .high),
        .init(id: 1022, due: Self.makeDate("2025-12-25"), subject: "Damaged wall socket in Lab 3 (needs replacement)", status: .assigned, campus: "Campus A", location: "5.17", priority: .low),
        .init(id: 1100, due: Self.makeDate("2025-10-25"), subject: "Flickering light in Room 104", status: .completed, campus: "Campus A", location: "19.104", priority: .medium),
        .init(id: 1120, due: Self.makeDate("2025-09-30"), subject: "Power outage in Lab 20.204", status: .inProgress, campus: "Campus B", location: "20.204", priority: .high),
        .init(id: 1133, due: Self.makeDate("2025-10-30"), subject: "Projector power cable not working", status: .completed, campus: "Campus B", location: "25.107", priority: .medium),
        .init(id: 1203, due: Self.makeDate("2025-11-30"), subject: "Light switch stuck in Office 26.110", status: .assigned, campus: "Campus A", location: "26.110", priority: .low)
    ]

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Tasks"
        view.backgroundColor = .systemBackground

        setupTable()
        sortTickets()
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(TaskTicketCell.self, forCellReuseIdentifier: TaskTicketCell.reuseID)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func sortTickets() {
        // Suggested UX sorting: overdue first, then due date ascending, then status
        tickets.sort { a, b in
            let aOver = isOverdue(a)
            let bOver = isOverdue(b)
            if aOver != bOver { return aOver && !bOver }

            if a.due != b.due { return a.due < b.due }

            // In Progress > Assigned > Completed
            func rank(_ s: Status) -> Int {
                switch s {
                case .inProgress: return 0
                case .assigned: return 1
                case .completed: return 2
                }
            }
            return rank(a.status) < rank(b.status)
        }
    }

    private func isOverdue(_ ticket: TicketUI) -> Bool {
        guard ticket.status != .completed else { return false }
        return ticket.due < Calendar.current.startOfDay(for: Date())
    }

    // MARK: - Table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tickets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TaskTicketCell.reuseID, for: indexPath) as? TaskTicketCell else {
            return UITableViewCell()
        }
        let t = tickets[indexPath.row]
        cell.configure(ticket: t, overdue: isOverdue(t))
        return cell
    }

    // MARK: - Date helper
    private static func makeDate(_ iso: String) -> Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: iso) ?? Date()
    }
}

// MARK: - Custom Cell (inside same file to minimize files)
final class TaskTicketCell: UITableViewCell {

    static let reuseID = "TaskTicketCell"

    private let card = UIView()
    private let leftStrip = UIView()

    private let ticketIdLabel = UILabel()
    private let dueLabel = UILabel()

    private let subjectTitleLabel = UILabel()
    private let subjectValueLabel = UILabel()

    private let statusIcon = UIImageView()
    private let statusLabel = UILabel()

    private let locationIcon = UIImageView()
    private let locationLabel = UILabel()

    private let priorityIcon = UIImageView()

    private let vStack = UIStackView()
    private let topRow = UIStackView()
    private let subjectStack = UIStackView()
    private let statusRow = UIStackView()
    private let locationRow = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func buildUI() {
        // Card
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 3)

        contentView.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])

        // Left strip (always blue)
        leftStrip.translatesAutoresizingMaskIntoConstraints = false
        leftStrip.backgroundColor = .systemBlue
        leftStrip.layer.cornerRadius = 12
        card.addSubview(leftStrip)

        NSLayoutConstraint.activate([
            leftStrip.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            leftStrip.topAnchor.constraint(equalTo: card.topAnchor),
            leftStrip.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            leftStrip.widthAnchor.constraint(equalToConstant: 12)
        ])

        // Priority icon (SF Symbol)
        priorityIcon.translatesAutoresizingMaskIntoConstraints = false
        priorityIcon.contentMode = .scaleAspectFit
        priorityIcon.image = UIImage(systemName: "exclamationmark.circle.fill")
        card.addSubview(priorityIcon)

        NSLayoutConstraint.activate([
            priorityIcon.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            priorityIcon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            priorityIcon.widthAnchor.constraint(equalToConstant: 44),
            priorityIcon.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Labels config
        ticketIdLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        dueLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        dueLabel.textAlignment = .right

        subjectTitleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        subjectTitleLabel.text = "Subject:"
        subjectValueLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subjectValueLabel.numberOfLines = 2

        statusLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        locationLabel.font = .systemFont(ofSize: 13, weight: .semibold)

        statusIcon.image = UIImage(systemName: "gearshape")
        statusIcon.tintColor = .secondaryLabel
        locationIcon.image = UIImage(systemName: "mappin.and.ellipse")
        locationIcon.tintColor = .secondaryLabel

        [statusIcon, locationIcon].forEach { icon in
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                icon.widthAnchor.constraint(equalToConstant: 18),
                icon.heightAnchor.constraint(equalToConstant: 18)
            ])
        }

        // Stacks
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.distribution = .fill
        topRow.spacing = 10

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        topRow.addArrangedSubview(ticketIdLabel)
        topRow.addArrangedSubview(spacer)
        topRow.addArrangedSubview(dueLabel)

        subjectStack.axis = .vertical
        subjectStack.spacing = 2
        subjectStack.addArrangedSubview(subjectTitleLabel)
        subjectStack.addArrangedSubview(subjectValueLabel)

        statusRow.axis = .horizontal
        statusRow.spacing = 8
        statusRow.alignment = .center
        statusRow.addArrangedSubview(statusIcon)
        statusRow.addArrangedSubview(statusLabel)

        locationRow.axis = .horizontal
        locationRow.spacing = 8
        locationRow.alignment = .center
        locationRow.addArrangedSubview(locationIcon)
        locationRow.addArrangedSubview(locationLabel)

        vStack.axis = .vertical
        vStack.spacing = 10
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.addArrangedSubview(topRow)
        vStack.addArrangedSubview(subjectStack)
        vStack.addArrangedSubview(statusRow)
        vStack.addArrangedSubview(locationRow)

        card.addSubview(vStack)

        NSLayoutConstraint.activate([
            vStack.leadingAnchor.constraint(equalTo: leftStrip.trailingAnchor, constant: 14),
            vStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            vStack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -14),
            vStack.trailingAnchor.constraint(equalTo: priorityIcon.leadingAnchor, constant: -12)
        ])
    }

    func configure(ticket: MyTasksViewController.TicketUI, overdue: Bool) {
        ticketIdLabel.text = "Ticket ID: \(ticket.id)"

        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        dueLabel.text = "Due: \(df.string(from: ticket.due))"
        dueLabel.textColor = overdue ? .systemRed : .label

        subjectValueLabel.text = ticket.subject

        statusLabel.text = "Status: \(ticket.status.rawValue)"
        locationLabel.text = "\(ticket.campus), \(ticket.location)"

        priorityIcon.tintColor = ticket.priority.tint
    }
}
