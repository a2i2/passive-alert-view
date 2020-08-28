import UIKit

public extension PassiveAlertView {
    struct Accessory {
        public static let defaultSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body)

        public let image: UIImage?
        public let isSeparatorRequired: Bool
        public var isUserInteractionEnabled: Bool
        public var shouldDismissOnSelect: Bool

        public init(
            named name: String,
            isSeparatorRequired separatorRequired: Bool = true,
            isUserInteractionEnabled userInteractionEnabled: Bool = false,
            shouldDismissOnSelect dismissOnSelect: Bool = false
        ) {
            self.init(image: UIImage(named: name),
                      isSeparatorRequired: separatorRequired,
                      isUserInteractionEnabled: userInteractionEnabled,
                      shouldDismissOnSelect: dismissOnSelect)
        }

        public init(
            systemName name: String,
            withConfiguration configuration: UIImage.Configuration? = Self.defaultSymbolConfiguration,
            isSeparatorRequired separatorRequired: Bool = true,
            isUserInteractionEnabled userInteractionEnabled: Bool = false,
            shouldDismissOnSelect dismissOnSelect: Bool = false
        ) {
            self.init(image: UIImage(systemName: name, withConfiguration: configuration),
                      isSeparatorRequired: separatorRequired,
                      isUserInteractionEnabled: userInteractionEnabled,
                      shouldDismissOnSelect: dismissOnSelect)
        }

        init(
            image: UIImage?,
            isSeparatorRequired separatorRequired: Bool = true,
            isUserInteractionEnabled userInteractionEnabled: Bool = false,
            shouldDismissOnSelect dismissOnSelect: Bool = false
        ) {
            self.image = image
            isSeparatorRequired = separatorRequired
            isUserInteractionEnabled = userInteractionEnabled || dismissOnSelect // dismissOnSelect forces user interaction
            shouldDismissOnSelect = dismissOnSelect
        }
    }
}

public extension PassiveAlertView.Accessory {
    static var close: Self = .init(systemName: "xmark",
                                   shouldDismissOnSelect: true)

    static var disclosure: Self = .init(systemName: "chevron.right",
                                        isSeparatorRequired: false,
                                        isUserInteractionEnabled: true)

    static var info: Self = .init(systemName: "info.circle",
                                  isUserInteractionEnabled: true)
}
