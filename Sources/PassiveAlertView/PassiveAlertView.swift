import UIKit

// MARK: - PassiveAlertViewDelegate

@objc public protocol PassiveAlertViewDelegate: class {
    func passiveAlertView(_ view: PassiveAlertView, willShowIn view: UIView)
    func passiveAlertView(_ view: PassiveAlertView, didShowIn view: UIView)
    func passiveAlertView(_ view: PassiveAlertView, willDismissFrom view: UIView)
    func passiveAlertView(_ view: PassiveAlertView, didDismissFrom view: UIView)
    func didSelectPassiveAlertView(_ view: PassiveAlertView)
}

// MARK: - PassiveAlertView

@objc public class PassiveAlertView: UIView {
    private var currentlyAnimating = false
    private var dismissAfterFinishedAnimating = false
    private var dismissAnimatedAfterFinishedAnimating = false
    private var dismissDurationAfterFinishedAnimating: TimeInterval = .zero

    private let theme: Theme

    public weak var delegate: PassiveAlertViewDelegate?
    public var animator: PassiveAlertViewAnimator?

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.textColor = theme.labelColor
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = theme.labelColor
        button.addTarget(self, action: #selector(closeButtonPressed(_:)), for: .touchUpInside)
        return button
    }()

    public init(withContent: String, theme: Theme = .default) {
        self.theme = theme

        super.init(frame: .zero)

        if case let .solid(color) = theme.background {
            backgroundColor = color
        }

        self.theme.shadowStyle.apply(to: self)

        contentLabel.text = content

        let stackView = UIStackView(arrangedSubviews: [contentLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = UIStackView.spacingUseSystem

        if theme.showsCloseButton {
            stackView.addArrangedSubview(makeSeparatorView())
            stackView.addArrangedSubview(closeButton)
        }

        addSubview(stackView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(alertTapped(_:)))
        tapGesture.numberOfTouchesRequired = 1
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGesture)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 1.0),
            trailingAnchor.constraint(equalToSystemSpacingAfter: stackView.trailingAnchor, multiplier: 2.0),
            bottomAnchor.constraint(equalToSystemSpacingBelow: stackView.bottomAnchor, multiplier: 1.0),
            stackView.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 2.0),
        ])
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeSeparatorView() -> UIView {
        let view = UIView()
        view.backgroundColor = theme.separatorColor
        view.widthAnchor.constraint(equalToConstant: 2.0).isActive = true
        return view
    }
}

@objc public extension PassiveAlertView {
    func show(in view: UIView, animated: Bool = true) {
        if currentlyAnimating { return }
        if superview != nil { return print("Alert already visible, ignoring.") }

        currentlyAnimating = true

        delegate?.passiveAlertView(self, willShowIn: view)

        view.addSubview(self)

        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 26),
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        setNeedsLayout()
        layoutIfNeeded()

        // now we know the size we can apply shapes like the pill
        theme.shape.apply(to: self)

        if animated {
            animator = PassiveAlertViewFadeZoomAnimator(alertView: self)
            animator!.show {
                self.currentlyAnimating = false
                self.delegate?.passiveAlertView(self, didShowIn: view)
                if self.dismissAfterFinishedAnimating {
                    self.dismiss(after: self.dismissDurationAfterFinishedAnimating, animated: self.dismissAnimatedAfterFinishedAnimating)
                }
            }
        } else {
            currentlyAnimating = false
            delegate?.passiveAlertView(self, didShowIn: view)
        }
    }

    func dismiss(after delay: TimeInterval = .zero, animated: Bool = true) {
        if currentlyAnimating {
            dismissAfterFinishedAnimating = true
            dismissAnimatedAfterFinishedAnimating = animated
            dismissDurationAfterFinishedAnimating = delay
            return
        }
        guard let superview = superview else { return print("Alert already dismissed, ignoring.") }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.currentlyAnimating = true
            self.delegate?.passiveAlertView(self, willDismissFrom: superview)
            if animated, let animator = self.animator {
                animator.hide {
                    self.currentlyAnimating = false
                    self.isHidden = true
                    self.removeFromSuperview()
                    self.delegate?.passiveAlertView(self, didDismissFrom: superview)
                    self.dismissAfterFinishedAnimating = false
                    self.dismissAnimatedAfterFinishedAnimating = false
                    self.dismissDurationAfterFinishedAnimating = .zero
                }
            } else {
                self.currentlyAnimating = false
                self.delegate?.passiveAlertView(self, didDismissFrom: superview)
            }
        }
    }
}

@objc private extension PassiveAlertView {
    func closeButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }

    func alertTapped(_ sender: UITapGestureRecognizer) {
        delegate?.didSelectPassiveAlertView(self)
    }
}
