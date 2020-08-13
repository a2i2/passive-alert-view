import UIKit

// MARK: - PassiveAlertViewDelegate

public protocol PassiveAlertViewDelegate: AnyObject {
    func passiveAlertView(_ alertView: PassiveAlertView, willShowIn view: UIView)
    func passiveAlertView(_ alertView: PassiveAlertView, didShowIn view: UIView)
    func passiveAlertView(_ alertView: PassiveAlertView, willDismissFrom view: UIView)
    func passiveAlertView(_ alertView: PassiveAlertView, didDismissFrom view: UIView)
    func didSelectPassiveAlertView(_ alertView: PassiveAlertView)
    func didSelectPassiveAlertViewLeadingAccessory(_ alertView: PassiveAlertView)
    func didSelectPassiveAlertViewTrailingAccessory(_ alertView: PassiveAlertView)
}

/// Default implementations so they're all optional
public extension PassiveAlertViewDelegate {
    func passiveAlertView(_ alertView: PassiveAlertView, willShowIn view: UIView) {}
    func passiveAlertView(_ alertView: PassiveAlertView, didShowIn view: UIView) {}
    func passiveAlertView(_ alertView: PassiveAlertView, willDismissFrom view: UIView) {}
    func passiveAlertView(_ alertView: PassiveAlertView, didDismissFrom view: UIView) {}
    func didSelectPassiveAlertView(_ alertView: PassiveAlertView) {}
    func didSelectPassiveAlertViewLeadingAccessory(_ alertView: PassiveAlertView) {}
    func didSelectPassiveAlertViewTrailingAccessory(_ alertView: PassiveAlertView) {}
}

// MARK: - PassiveAlertView

public class PassiveAlertView: UIView {
    private var currentlyAnimating = false
    private var dismissAfterFinishedAnimating = false
    private var dismissAnimatedAfterFinishedAnimating = false
    private var dismissDurationAfterFinishedAnimating: TimeInterval = .zero

    public weak var delegate: PassiveAlertViewDelegate?
    public var animator: PassiveAlertViewAnimator?

    private let theme: Theme
    private let leadingAccessory: Accessory?
    private let trailingAccessory: Accessory?

    private var leadingImageView: UIImageView?
    private var trailingImageView: UIImageView?

    private lazy var contentLabel: InsetLabel = {
        let label = InsetLabel()
        label.isUserInteractionEnabled = true
        label.textColor = theme.labelColor
        label.font = .preferredFont(forTextStyle: .body)
        label.contentInsets = .init(top: 5, left: 12, bottom: 5, right: 12)
        return label
    }()

    public init(
        leadingAccessory: Accessory? = .none,
        content: String,
        trailingAccessory: Accessory? = .none,
        theme: Theme = .default
    ) {
        self.theme = theme
        self.leadingAccessory = leadingAccessory
        self.trailingAccessory = trailingAccessory

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

        addSubview(stackView)

        let alertTapGesture = UITapGestureRecognizer(target: self, action: #selector(alertTapped(_:)))
        alertTapGesture.numberOfTouchesRequired = 1
        alertTapGesture.numberOfTapsRequired = 1
        contentLabel.addGestureRecognizer(alertTapGesture)

        if let accessory = leadingAccessory {
            let imageView = makeAccessoryImageView(accessory,
                                                   theme: theme,
                                                   action: #selector(leadingAccessoryTapped(_:)))
            stackView.insertArrangedSubview(imageView, at: 0)
            if accessory.isSeparatorRequired {
                stackView.insertArrangedSubview(makeSeparatorView(), at: 1)
            }
            leadingImageView = imageView
        }

        if let accessory = trailingAccessory {
            let imageView = makeAccessoryImageView(accessory,
                                                   theme: theme,
                                                   action: #selector(trailingAccessoryTapped(_:)))
            if accessory.isSeparatorRequired {
                stackView.addArrangedSubview(makeSeparatorView())
            }
            stackView.addArrangedSubview(imageView)
            trailingImageView = imageView
        }

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
        ])
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension PassiveAlertView {
    func makeAccessoryImageView(
        _ accessory: Accessory,
        theme: Theme,
        action: Selector
    ) -> UIImageView {
        let tapGesture = UITapGestureRecognizer(target: self, action: action)
        tapGesture.numberOfTouchesRequired = 1
        tapGesture.numberOfTapsRequired = 1

        let imageView = UIImageView(image: accessory.image)
        imageView.isUserInteractionEnabled = accessory.isUserInteractionEnabled
        imageView.tintColor = theme.labelColor
        imageView.contentMode = .center
        imageView.addGestureRecognizer(tapGesture)

        imageView.widthAnchor.constraint(greaterThanOrEqualToConstant: 32.0).isActive = true
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true

        return imageView
    }

    func makeSeparatorView() -> UIView {
        let view = UIView()
        view.backgroundColor = theme.separatorColor
        view.widthAnchor.constraint(equalToConstant: 1.0).isActive = true
        return view
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
    func alertTapped(_ sender: UITapGestureRecognizer) {
        delegate?.didSelectPassiveAlertView(self)
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
