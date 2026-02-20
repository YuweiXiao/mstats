import AppKit

final class NetworkMultilineStatusItemView: NSView {
    private let leadingLabel = NSTextField(labelWithString: "")
    private let topLabel = NSTextField(labelWithString: "--")
    private let bottomLabel = NSTextField(labelWithString: "--")
    private let verticalStackView = NSStackView()
    private let rootStackView = NSStackView()

    var onPressed: (() -> Void)?

    var leadingMetricText: String? {
        leadingLabel.isHidden ? nil : leadingLabel.stringValue
    }

    var topLineText: String {
        topLabel.stringValue
    }

    var bottomLineText: String {
        bottomLabel.stringValue
    }

    var isCenterAligned: Bool {
        leadingLabel.alignment == .center &&
            topLabel.alignment == .center &&
            bottomLabel.alignment == .center &&
            verticalStackView.alignment == .centerX
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func update(leadingText: String?, topLine: String, bottomLine: String) {
        if let leadingText, !leadingText.isEmpty {
            leadingLabel.stringValue = leadingText
            leadingLabel.isHidden = false
        } else {
            leadingLabel.stringValue = ""
            leadingLabel.isHidden = true
        }
        topLabel.stringValue = topLine
        bottomLabel.stringValue = bottomLine
    }

    override func mouseDown(with event: NSEvent) {
        onPressed?()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(point) ? self : nil
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    private func setupView() {
        let networkFont = NSFont.monospacedDigitSystemFont(ofSize: 8.5, weight: .regular)
        let leadingFont = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

        leadingLabel.font = leadingFont
        leadingLabel.alignment = .center
        leadingLabel.lineBreakMode = .byTruncatingTail
        leadingLabel.translatesAutoresizingMaskIntoConstraints = false
        leadingLabel.isHidden = true
        leadingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        leadingLabel.setContentHuggingPriority(.required, for: .horizontal)

        topLabel.font = networkFont
        topLabel.alignment = .center
        topLabel.lineBreakMode = .byTruncatingTail
        topLabel.translatesAutoresizingMaskIntoConstraints = false

        bottomLabel.font = networkFont
        bottomLabel.alignment = .center
        bottomLabel.lineBreakMode = .byTruncatingTail
        bottomLabel.translatesAutoresizingMaskIntoConstraints = false

        verticalStackView.orientation = .vertical
        verticalStackView.alignment = .centerX
        verticalStackView.spacing = 0
        verticalStackView.edgeInsets = NSEdgeInsetsZero
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.addArrangedSubview(topLabel)
        verticalStackView.addArrangedSubview(bottomLabel)
        verticalStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        rootStackView.orientation = .horizontal
        rootStackView.alignment = .centerY
        rootStackView.spacing = 2
        rootStackView.edgeInsets = NSEdgeInsetsZero
        rootStackView.translatesAutoresizingMaskIntoConstraints = false
        rootStackView.addArrangedSubview(leadingLabel)
        rootStackView.addArrangedSubview(verticalStackView)

        addSubview(rootStackView)

        NSLayoutConstraint.activate([
            rootStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            rootStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            rootStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            rootStackView.topAnchor.constraint(equalTo: topAnchor),
            rootStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
