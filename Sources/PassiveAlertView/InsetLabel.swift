import UIKit

class InsetLabel: UILabel {
    var contentInsets: UIEdgeInsets = .zero

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height += contentInsets.top + contentInsets.bottom
        size.width += contentInsets.left + contentInsets.right
        return size
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }
}
