// Gesture+Combine.swift

import Combine
import UIKit

public struct GesturePublisher<G: Gesture>: Publisher {
    public typealias Output = G
    public typealias Failure = Never
    private let view: UIView
    private let gesture: G
    
    init(view: UIView, gesture: G) {
        self.view = view
        self.gesture = gesture
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, GesturePublisher.Failure == S.Failure, GesturePublisher.Output == S.Input {
        let subscription = GestureSubscription(
            subscriber: subscriber,
            view: view,
            gesture: gesture
        )
        subscriber.receive(subscription: subscription)
    }
}

extension Publisher where Output: Gesture {
    public func when(_ states: UIGestureRecognizer.State...) -> Publishers.Filter<Self>{
        filter {
            states.contains($0.recognizer.state)
        }
    }
}

extension Publisher where Output: UIGestureRecognizer {
    public func when(_ states: UIGestureRecognizer.State...) -> Publishers.Filter<Self>{
        filter {
            states.contains($0.state)
        }
    }
}

public protocol GestureProtocol {
    init()
}

public protocol Gesture: GestureProtocol {
    associatedtype GestureRecognizer: UIGestureRecognizer
    var recognizer: GestureRecognizer { get }
    var delegate: GestureRecognizerDelegate { get }
}

public extension Gesture {
    typealias Configuration = (GestureRecognizerDelegate, GestureRecognizer) -> Void
    
    init(_ block: Configuration) {
        self = Self.init()
        block(delegate, recognizer)
    }
}

public extension Gesture {
    static var tap: TapGesture                  { .init() }
    static var swipe: SwipeGesture              { .init() }
    static var longPress: LongPressGesture      { .init() }
    static var panGesture: PanGesture           { .init() }
    static var pinchGesture: PinchGesture       { .init() }
    static var edgeGesture: EdgeGesture         { .init() }
}

public struct AnyGesture: Gesture {
    
    public let recognizer: UIGestureRecognizer
    
    public let delegate: GestureRecognizerDelegate
    
    public init() {
        recognizer = .init()
        delegate = GestureRecognizerDelegateProxy()
    }
    
    init<G: Gesture>(_ gesture: G) {
        self.recognizer = gesture.recognizer
        self.delegate = gesture.delegate
    }
}

public struct TapGesture: Gesture {
    public let recognizer = UITapGestureRecognizer()
    
    public let delegate: GestureRecognizerDelegate = GestureRecognizerDelegateProxy()
    
    public init() { }
}

public struct SwipeGesture: Gesture {
    public let recognizer = UISwipeGestureRecognizer()
    
    public let delegate: GestureRecognizerDelegate = GestureRecognizerDelegateProxy()
    
    public init() { }
}

public struct LongPressGesture: Gesture {
    public let recognizer = UILongPressGestureRecognizer()
    
    public let delegate: GestureRecognizerDelegate = GestureRecognizerDelegateProxy()
    
    public init() { }
}

public struct PanGesture: Gesture {
    public let recognizer = UIPanGestureRecognizer()
    
    public let delegate: GestureRecognizerDelegate = GestureRecognizerDelegateProxy()
    
    public init() { }
}

public struct PinchGesture: Gesture {
    public let recognizer = UIPinchGestureRecognizer()
    
    public let delegate: GestureRecognizerDelegate = GestureRecognizerDelegateProxy()
    
    public init() { }
}

public struct EdgeGesture: Gesture {
    public let recognizer = UIScreenEdgePanGestureRecognizer()
    
    public let delegate: GestureRecognizerDelegate = GestureRecognizerDelegateProxy()
    
    public init() { }
}

public struct ForceTouchGesture: Gesture {
    public let recognizer = UIForceTouchGestureRecognizer()
    
    public let delegate: GestureRecognizerDelegate = GestureRecognizerDelegateProxy()
    
    public init() { }
}

public enum GestureType {
    case tap((GestureRecognizerDelegate, UITapGestureRecognizer) -> Void = { _, _ in })
    case pinch((GestureRecognizerDelegate, UIPinchGestureRecognizer) -> Void = { _, _ in })
    case longPress((GestureRecognizerDelegate, UILongPressGestureRecognizer) -> Void = { _, _ in })
    case edge((GestureRecognizerDelegate, UIScreenEdgePanGestureRecognizer) -> Void = { _, _ in })
    case swipe((GestureRecognizerDelegate, UISwipeGestureRecognizer) -> Void = { _, _ in })
    case pan((GestureRecognizerDelegate, UIPanGestureRecognizer) -> Void = { _, _ in })
    case forceTouch((GestureRecognizerDelegate, UIForceTouchGestureRecognizer) -> Void = { _, _ in })
}

public extension GestureType {
    var gesture: AnyGesture {
        switch self {
        case .tap(let block):          return AnyGesture(TapGesture(block))
        case .pinch(let block):        return AnyGesture(PinchGesture(block))
        case .longPress(let block):    return AnyGesture(LongPressGesture(block))
        case .edge(let block):         return AnyGesture(EdgeGesture(block))
        case .swipe(let block):        return AnyGesture(SwipeGesture(block))
        case .pan(let block):          return AnyGesture(PanGesture(block))
        case .forceTouch(let block):   return AnyGesture(ForceTouchGesture(block))
        }
    }
    
    var configuration: AnyGesture.Configuration {
        switch self {
        case .tap(let block):          return { block($0, $1 as! UITapGestureRecognizer) }
        case .pinch(let block):        return { block($0, $1 as! UIPinchGestureRecognizer) }
        case .longPress(let block):    return { block($0, $1 as! UILongPressGestureRecognizer) }
        case .edge(let block):         return { block($0, $1 as! UIScreenEdgePanGestureRecognizer) }
        case .swipe(let block):        return { block($0, $1 as! UISwipeGestureRecognizer) }
        case .pan(let block):          return { block($0, $1 as! UIPanGestureRecognizer) }
        case .forceTouch(let block):   return { block($0, $1 as! UIForceTouchGestureRecognizer)}
        }
    }
}

public final class GestureSubscription<S: Subscriber, G: Gesture>: NSObject, Subscription, UIGestureRecognizerDelegate where S.Input == G, S.Failure == Never {
    private var subscriber: S
    private var gesture: G
        
    private weak var view: UIView?
    
    init(subscriber: S, view: UIView, gesture: G) {
        self.subscriber = subscriber
        self.view = view
        self.gesture = gesture
        
        super.init()
        
        self.configureGesture(gesture)
    }
    
    private func configureGesture(_ gesture: G) {
        let recognizer = gesture.recognizer
        recognizer.delegate = gesture.delegate.delegate
        recognizer.addTarget(self, action: #selector(handler))
        view?.addGestureRecognizer(recognizer)
    }
    
    public func request(_ demand: Subscribers.Demand) { }
    
    public func cancel() {
        perform(
            #selector(GestureSubscription.cleanup),
            on: .main,
            with: nil,
            waitUntilDone: Thread.isMainThread)
    }
    
    @objc
    private func cleanup() {
        gesture.recognizer.reset()
        gesture.recognizer.removeTarget(
            self, action: #selector(GestureSubscription.handler))
        view?.removeGestureRecognizer(gesture.recognizer)
        view = nil
    }
    
    @objc
    private func handler() {
        _ = subscriber.receive(gesture)
    }
}

public protocol GestureRecognizerDelegate: AnyObject {
    var delegate: UIGestureRecognizerDelegate { get }
    var shouldBegin: (_ gestureRecognizer: UIGestureRecognizer) -> Bool { get set }
    var shouldRequireFailureOf: (_ gestureRecognizer: UIGestureRecognizer, _ otherGestureRecognizer: UIGestureRecognizer) -> Bool { get set }
    var shouldBeRequiredToFailBy: (_ gestureRecognizer: UIGestureRecognizer, _ shouldBeRequiredToFailBy: UIGestureRecognizer) -> Bool { get set }
    var shouldReceiveTouch: (_ gestureRecognizer: UIGestureRecognizer, _ touch: UITouch) -> Bool { get set }
    var shouldReceivePress: (_ gestureRecognizer: UIGestureRecognizer, _ press: UIPress) -> Bool { get set }
    var shouldReceiveEvent: (_ gestureRecognizer: UIGestureRecognizer, _ event: UIEvent) -> Bool { get set }
    var shouldRecognizeSimultaneouslyWith: (_ gestureRecognizer: UIGestureRecognizer, _ otherGestureRecognizer: UIGestureRecognizer) -> Bool { get set }
}

class GestureRecognizerDelegateProxy: NSObject, GestureRecognizerDelegate, UIGestureRecognizerDelegate {
    var delegate: UIGestureRecognizerDelegate { self }
    
    var shouldBegin: (UIGestureRecognizer) -> Bool = { _ in true }
    
    var shouldRequireFailureOf: (UIGestureRecognizer, UIGestureRecognizer) -> Bool = { _, _ in false }
    
    var shouldBeRequiredToFailBy: (UIGestureRecognizer, UIGestureRecognizer) -> Bool = { _, _ in false }
    
    var shouldReceiveTouch: (UIGestureRecognizer, UITouch) -> Bool = { _, _ in true }
    
    var shouldReceivePress: (UIGestureRecognizer, UIPress) -> Bool = { _, _ in true }
    
    var shouldReceiveEvent: (UIGestureRecognizer, UIEvent) -> Bool = { _, _ in true }
    
    var shouldRecognizeSimultaneouslyWith: (UIGestureRecognizer, UIGestureRecognizer) -> Bool = { _, _ in true }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        shouldBegin(gestureRecognizer)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        shouldRequireFailureOf(gestureRecognizer, otherGestureRecognizer)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        shouldBeRequiredToFailBy(gestureRecognizer, otherGestureRecognizer)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        shouldReceiveTouch(gestureRecognizer, touch)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
        shouldReceivePress(gestureRecognizer, press)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive event: UIEvent) -> Bool {
        shouldReceiveEvent(gestureRecognizer, event)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        shouldRecognizeSimultaneouslyWith(gestureRecognizer, otherGestureRecognizer)
    }
}

public extension CBPublishers where Base: UIView {
    private func publishGesture<G: Gesture>(type: G.Type, configuration: G.Configuration) -> GesturePublisher<G> {
        GesturePublisher(view: base, gesture: G(configuration))
    }
    
    func gesture(_ gestureType: GestureType) -> GesturePublisher<AnyGesture> {
        publishGesture(type: AnyGesture.self, configuration: gestureType.configuration)
    }
    
    func tapGesture(_ configuration: TapGesture.Configuration = { _, _ in }) -> GesturePublisher<TapGesture> {
        publishGesture(type: TapGesture.self, configuration: configuration)
    }
    
    func panGesture(_ configuration: PanGesture.Configuration = { _, _ in }) -> GesturePublisher<PanGesture> {
        publishGesture(type: PanGesture.self, configuration: configuration)
    }
    
    func swipeGesture(_ configuration: SwipeGesture.Configuration = { _, gesture in gesture.direction = [.right, .left, .up, .down] }) -> GesturePublisher<SwipeGesture> {
        publishGesture(type: SwipeGesture.self, configuration: configuration)
    }
    
    func swipeGesture(_ directions: UISwipeGestureRecognizer.Direction...) -> GesturePublisher<SwipeGesture> {
        swipeGesture{ _, gesture in gesture.direction = .init(directions) }
    }
    
    func edgeGesture(_ configuration: EdgeGesture.Configuration = { _, _ in }) -> GesturePublisher<EdgeGesture> {
        publishGesture(type: EdgeGesture.self, configuration: configuration)
    }
    
    func edgeGesture(_ edges: UIRectEdge...) -> GesturePublisher<EdgeGesture> {
        edgeGesture{ _, gesture in gesture.edges = UIRectEdge(edges) }
    }
    
    func longPressGesture(_ configuration: LongPressGesture.Configuration = { _, _ in }) -> GesturePublisher<LongPressGesture> {
        publishGesture(type: LongPressGesture.self, configuration: configuration)
    }
    
    func pinchGesture(_ configuration: PinchGesture.Configuration = { _, _ in }) -> GesturePublisher<PinchGesture> {
        publishGesture(type: PinchGesture.self, configuration: configuration)
    }
    
    func forceTouchGesture(threshold: CGFloat = 1.0, _ configuration: ForceTouchGesture.Configuration = { _, _ in }) -> GesturePublisher<ForceTouchGesture> {
        publishGesture(type: ForceTouchGesture.self, configuration: {
            $1.threshold = threshold
            configuration($0, $1)
        })
    }
}
