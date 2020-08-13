import UIKit

// MARK: - PassiveAlertView Themeing

public extension PassiveAlertView {
    class Theme {
        public let shape: Shape
        public let background: Background
        public let labelColor: UIColor
        public let separatorColor: UIColor
        public let shadowStyle: Shadow

        public init(
            shape: Shape,
            background: Background,
            labelColor: UIColor,
            separatorColor: UIColor,
            shadowStyle: Shadow
        ) {
            self.shape = shape
            self.background = background
            self.labelColor = labelColor
            self.separatorColor = separatorColor
            self.shadowStyle = shadowStyle
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
            /// Not yet implemented
            case blur(effect: UIBlurEffect, prominence: Bool = true)

            case solid(UIColor)

            /// Not yet implemented
            case gradient(CAGradientLayer)
        }

        /// Not yet implemented
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
        shadowStyle: .with(color: .black, radius: 5.0)
    )
}
