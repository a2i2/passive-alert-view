import UIKit

public class PassiveAlertView: UIView {
    private var currentlyAnimating = false
    private var dismissAfterFinishedAnimating = false
    private var dismissAnimatedAfterFinishedAnimating = false
    private var dismissDurationAfterFinishedAnimating: TimeInterval = .zero

    public weak var delegate: PassiveAlertViewDelegate?
    public var animator: PassiveAlertViewAnimator?

    private let theme: Theme
    public let leadingAccessory: Accessory?
    public let contentLabel: UILabel!
    public let trailingAccessory: Accessory?
    public var shouldDismissOnSelect: Bool

    private var leadingImageView: UIImageView?
    private var trailingImageView: UIImageView?

    public var message: String? {
        get { contentLabel.text }
        set { contentLabel.text = newValue }
    }

    public init(
        leadingAccessory: Accessory? = .none,
        message: String,
        trailingAccessory: Accessory? = .none,
        shouldDismissOnSelect: Bool = false,
        theme: Theme = .default
    ) {
        self.theme = theme
        self.leadingAccessory = leadingAccessory
        self.trailingAccessory = trailingAccessory
        self.shouldDismissOnSelect = shouldDismissOnSelect
        contentLabel = configure(InsetLabel()) {
            $0.isUserInteractionEnabled = true
            $0.textColor = theme.labelColor
            $0.text = message
            $0.adjustsFontForContentSizeCategory = true
            $0.font = .preferredFont(forTextStyle: .body)
            // less padding is needed when there is a separator
            let leadingInset: CGFloat = (leadingAccessory?.isSeparatorRequired ?? true) ? 12 : 4
            let trailingInset: CGFloat = (trailingAccessory?.isSeparatorRequired ?? true) ? 12 : 4
            $0.contentInsets = .init(top: 5, left: leadingInset, bottom: 5, right: trailingInset)
        }

        super.init(frame: .zero)

        configureView()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension PassiveAlertView {
    func configureView() {
        theme.background.apply(to: self)
        theme.shadowStyle.apply(to: self)

        let stackView = configure(UIStackView(arrangedSubviews: [contentLabel])) {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.axis = .horizontal
            $0.alignment = .fill
            $0.distribution = .fill
        }
        addSubview(stackView)

        let alertTapGesture = configure(UITapGestureRecognizer(target: self, action: #selector(alertTapped(_:)))) {
            $0.numberOfTouchesRequired = 1
            $0.numberOfTapsRequired = 1
        }
        contentLabel.addGestureRecognizer(alertTapGesture)

        // Setup leading accessory
        leadingImageView = leadingAccessory.map { accessory in
            let imageView = makeAccessoryImageView(accessory,
                                                   theme: theme,
                                                   action: #selector(leadingAccessoryTapped(_:)))
            stackView.insertArrangedSubview(imageView, at: 0)
            if accessory.isSeparatorRequired {
                stackView.insertArrangedSubview(makeSeparatorView(), at: 1)
            }
            return imageView
        }

        // Setup trailing accessory
        trailingImageView = trailingAccessory.map { accessory in
            let imageView = makeAccessoryImageView(accessory,
                                                   theme: theme,
                                                   action: #selector(trailingAccessoryTapped(_:)))
            if accessory.isSeparatorRequired {
                stackView.addArrangedSubview(makeSeparatorView())
            }
            stackView.addArrangedSubview(imageView)
            return imageView
        }

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
        ])
    }

    func makeAccessoryImageView(
        _ accessory: Accessory,
        theme: Theme,
        action: Selector
    ) -> UIImageView {
        return configure(UIImageView(image: accessory.image)) {
            $0.isUserInteractionEnabled = accessory.isUserInteractionEnabled
            $0.tintColor = theme.labelColor
            $0.contentMode = .center

            let tapGesture = configure(UITapGestureRecognizer(target: self, action: action)) {
                $0.numberOfTouchesRequired = 1
                $0.numberOfTapsRequired = 1
            }
            $0.addGestureRecognizer(tapGesture)

            $0.widthAnchor.constraint(greaterThanOrEqualToConstant: 32.0).isActive = true
            $0.widthAnchor.constraint(equalTo: $0.heightAnchor).isActive = true
        }
    }

    func makeSeparatorView() -> UIView {
        return configure(UIView()) {
            $0.backgroundColor = theme.separatorColor
            $0.widthAnchor.constraint(equalToConstant: 1.0).isActive = true
        }
    }

    func dismissIfAccessoryRequires(_ accessory: Accessory?) {
        guard let accessory = accessory, accessory.shouldDismissOnSelect else { return }
        dismiss(animated: true)
    }
}

public extension PassiveAlertView {
    func show(in view: UIView, animated: Bool = true) {
        if currentlyAnimating { return }
        if superview != nil { return print("Alert already visible, ignoring.") }

        currentlyAnimating = true

        delegate?.passiveAlertView(self, willShowIn: view)

        view.addSubview(self)

        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -26),
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
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
    func alertTapped(_ sender: UITapGestureRecognizer) {
        delegate?.didSelectPassiveAlertView(self)

        if shouldDismissOnSelect {
            dismiss(animated: true)
        }
    }

    func leadingAccessoryTapped(_ sender: UITapGestureRecognizer) {
        defer { dismissIfAccessoryRequires(self.leadingAccessory) }
        guard let delegate = delegate else { return }

        // Call through to the correct delegate method based on whether the accessory can be selected
        if leadingAccessory?.isUserInteractionEnabled ?? false {
            delegate.didSelectPassiveAlertViewLeadingAccessory(self)
        } else {
            alertTapped(sender)
        }
    }

    func trailingAccessoryTapped(_ sender: UITapGestureRecognizer) {
        defer { dismissIfAccessoryRequires(trailingAccessory) }
        guard let delegate = delegate else { return }

        // Call through to the correct delegate method based on whether the accessory can be selected
        if trailingAccessory?.isUserInteractionEnabled ?? false {
            delegate.didSelectPassiveAlertViewTrailingAccessory(self)
        } else {
            alertTapped(sender)
        }
    }
}
