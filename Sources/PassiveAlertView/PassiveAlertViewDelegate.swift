import UIKit

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
