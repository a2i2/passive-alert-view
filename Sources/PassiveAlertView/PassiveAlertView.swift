import UIKit

@objc public protocol PassiveAlertViewDelegate: class {
    func passiveAlertView(_ view: PassiveAlertView, willShowIn view: UIView)
    func passiveAlertView(_ view: PassiveAlertView, didShowIn view: UIView)
    func passiveAlertView(_ view: PassiveAlertView, willDismissFrom view: UIView)
    func passiveAlertView(_ view: PassiveAlertView, didDismissFrom view: UIView)
    func passiveAlertViewWasSelected(_ view: PassiveAlertView)
}

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

    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = theme.separatorColor
        view.widthAnchor.constraint(equalToConstant: 2.0).isActive = true
        return view
    }()

    public init(withContent content: String, theme: Theme = .default) {
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
            stackView.addArrangedSubview(separatorView)
            stackView.addArrangedSubview(closeButton)
        }

        addSubview(stackView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(alertTapped(_:)))
        tapGesture.numberOfTouchesRequired = 1
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGesture)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalToSystemSpacingBelow: self.topAnchor, multiplier: 1.0),
            self.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: stackView.trailingAnchor, multiplier: 2.0),
            self.bottomAnchor.constraint(equalToSystemSpacingBelow: stackView.bottomAnchor, multiplier: 1.0),
            stackView.leadingAnchor.constraint(lessThanOrEqualToSystemSpacingAfter: self.leadingAnchor, multiplier: 2.0),
        ])
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc public func show(in view: UIView, animated: Bool = true) {
        if currentlyAnimating { return }
        if superview != nil { return print("Alert already visible, ignoring.") }

        currentlyAnimating = true

        delegate?.passiveAlertView(self, willShowIn: view)

        view.addSubview(self)

        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 26),
            self.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: self.trailingAnchor, multiplier: 1.0),
            self.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: view.safeAreaLayoutGuide.leadingAnchor, multiplier: 1.0),
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

    @objc public func dismiss(after delay: TimeInterval = .zero, animated: Bool = true) {
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

// MARK: - PassiveAlertView Themeing

public extension PassiveAlertView {
    class Theme {
        public let shape: Shape
        public let background: Background
        public let labelColor: UIColor
        public let separatorColor: UIColor
        public let shadowStyle: Shadow
        public let showsCloseButton: Bool

        public init(shape: Shape, background: Background, labelColor: UIColor, separatorColor: UIColor, shadowStyle: Shadow, showsCloseButton: Bool) {
            self.shape = shape
            self.background = background
            self.labelColor = labelColor
            self.separatorColor = separatorColor
            self.shadowStyle = shadowStyle
            self.showsCloseButton = showsCloseButton
        }

        public enum Shape {
            case roundedRect(cornerRadius: CGFloat, curve: CALayerCornerCurve)
            case pill(curve: CALayerCornerCurve)

            func apply(to alertView: PassiveAlertView) {
                switch self {
                case let .roundedRect(cornerRadius, curve):
                    alertView.layer.cornerRadius = cornerRadius
                    alertView.layer.cornerCurve = curve
                case let .pill(curve):
                    alertView.layer.cornerRadius = min(alertView.bounds.width, alertView.bounds.height) / 2
                    alertView.layer.cornerCurve = curve
                }
                alertView.clipsToBounds = true
            }
        }

        public enum Background {
            case blur(effect: UIBlurEffect, prominence: Bool = true)
            case solid(UIColor)
            case gradient(CAGradientLayer)
        }

        public enum Shadow {
            case none
            case with(color: UIColor, radius: CGFloat, opacity: Float = 0.5)

            func apply(to alertView: PassiveAlertView) {
                switch self {
                case .none:
                    break
                case let .with(color, radius, opacity):
                    alertView.layer.shadowColor = color.cgColor
                    alertView.layer.shadowOpacity = opacity
                    alertView.layer.shadowRadius = radius
                    alertView.layer.shadowOffset = .zero
                }
            }
        }
    }
}

// MARK: - Default PassiveAlertView Theme

public extension PassiveAlertView.Theme {
    static let `default` = PassiveAlertView.Theme(
        shape: .pill(curve: .continuous),
        background: .solid(.systemBlue),
        labelColor: .white,
        separatorColor: .separator,
        shadowStyle: .with(color: .black, radius: 5.0),
        showsCloseButton: true
    )
}

@objc private extension PassiveAlertView {
    func closeButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }

    func alertTapped(_ sender: UITapGestureRecognizer) {
        delegate?.passiveAlertViewWasSelected(self)
    }
}
