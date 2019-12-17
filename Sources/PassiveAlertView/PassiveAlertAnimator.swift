import UIKit

public protocol PassiveAlertViewAnimator: class {
    init(alertView: PassiveAlertView, animationDuration: TimeInterval)

    func show(completion: @escaping () -> Void)
    func hide(completion: @escaping () -> Void)
}

public class PassiveAlertViewFadeZoomAnimator: PassiveAlertViewAnimator {
    private let alertView: PassiveAlertView
    private let totalAnimationDuration: TimeInterval
    private let initialAnimationDuration: TimeInterval
    private let overZoomAnimationDuration: TimeInterval
    private let startingTransform = CGAffineTransform(scaleX: 0.1, y: 0.1)
    private let overZoomTransform = CGAffineTransform(scaleX: 1.1, y: 1.1)

    public required init(alertView: PassiveAlertView, animationDuration: TimeInterval = 0.3) {
        self.alertView = alertView
        totalAnimationDuration = animationDuration
        initialAnimationDuration = animationDuration * (2 / 3)
        overZoomAnimationDuration = animationDuration * (1 / 3)
    }

    public func show(completion: @escaping () -> Void) {
        alertView.alpha = 0.0
        alertView.transform = startingTransform
        alertView.isHidden = false

        UIView.animate(withDuration: totalAnimationDuration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.alertView.alpha = 1.0
        })

        UIView.animate(withDuration: initialAnimationDuration, delay: 0.0, options: .curveEaseIn, animations: {
            self.alertView.transform = self.overZoomTransform
        }, completion: { _ in
            UIView.animate(withDuration: self.overZoomAnimationDuration, delay: 0.0, options: .curveEaseOut, animations: {
                self.alertView.transform = .identity
            }) { _ in
                completion()
            }
        })
    }

    public func hide(completion: @escaping () -> Void) {
        UIView.animate(withDuration: totalAnimationDuration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.alertView.alpha = 0.0
            self.alertView.transform = self.startingTransform
        }, completion: { _ in
            completion()
        })
    }
}
