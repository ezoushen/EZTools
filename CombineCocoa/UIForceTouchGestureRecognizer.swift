// UIForceTouchGestureRecognizer.swift

import UIKit.UIGestureRecognizerSubclass

public class UIForceTouchGestureRecognizer: UIGestureRecognizer {

    public var numberOfTouchesRequired: Int = 1
    public private(set) var force: CGFloat = 0
    public private(set) var maximumPossibleForce: CGFloat = 0
    public var fractionCompleted: CGFloat {
        guard maximumPossibleForce > 0 else {
            return 0
        }
        return force / maximumPossibleForce
    }
    public var threshold: CGFloat = 1.0
    
    private var recognized: Bool = false
    
    init(threshold: CGFloat = 1.0) {
        self.threshold = threshold
        super.init(target: nil, action: nil)
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        setForce(for: touches)
        state = .possible
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        setForce(for: touches)

        if recognized {
            state = .changed
        } else if fractionCompleted >= threshold {
            recognized = true
            state = .began
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)

        setForce(for: touches)

        state = .ended
        recognized = false
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)

        setForce(for: touches)

        state = .cancelled
        recognized = false
    }

    private func setForce(for touches: Set<UITouch>) {
        guard touches.count == numberOfTouchesRequired, let touch = touches.first else {
            state = .failed
            return
        }

        force = touch.force
        maximumPossibleForce = touch.maximumPossibleForce
    }
}
