import UIKit

public protocol PassiveAlertViewAnimator: class {
    init(alertView: PassiveAlertView)

    func show(completion: @escaping () -> Void)
    func hide(completion: @escaping () -> Void)
}

public class PassiveAlertViewFadeZoomAnimator: PassiveAlertViewAnimator {
    let alertView: PassiveAlertView

    public required init(alertView: PassiveAlertView) {
        self.alertView = alertView
    }

    public func show(completion: @escaping () -> Void) {
        alertView.alpha = 0.0
        alertView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        alertView.isHidden = false

        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.alertView.alpha = 1.0
        })

        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
            self.alertView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }, completion: { _ in
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
                self.alertView.transform = .identity
            }) { _ in
                completion()
            }
        })
    }

    public func hide(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.alertView.alpha = 0.0
            self.alertView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }, completion: { _ in
            completion()
        })
    }
}
