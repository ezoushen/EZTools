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
}

public extension Gesture {
    typealias Configuration = (GestureRecognizer) -> Void
    
    init(_ block: (GestureRecognizer) -> Void) {
        self = Self.init()
        block(recognizer)
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
    
    public init() {
        recognizer = .init()
    }
    
    init<G: Gesture>(_ gesture: G) {
        self.recognizer = gesture.recognizer
    }
}

public struct TapGesture: Gesture {
    public let recognizer = UITapGestureRecognizer()
    
    public init() { }
}

public struct SwipeGesture: Gesture {
    public let recognizer = UISwipeGestureRecognizer()
    
    public init() { }
}

public struct LongPressGesture: Gesture {
    public let recognizer = UILongPressGestureRecognizer()
    
    public init() { }
}

public struct PanGesture: Gesture {
    public let recognizer = UIPanGestureRecognizer()
    
    public init() { }
}

public struct PinchGesture: Gesture {
    public let recognizer = UIPinchGestureRecognizer()
    
    public init() { }
}

public struct EdgeGesture: Gesture {
    public let recognizer = UIScreenEdgePanGestureRecognizer()
    
    public init() { }
}

public struct ForceTouchGesture: Gesture {
    public let recognizer = UIForceTouchGestureRecognizer()
    
    public init() { }
}

public enum GestureType {
    case tap((UITapGestureRecognizer) -> Void = { _ in })
    case pinch((UIPinchGestureRecognizer) -> Void = { _ in })
    case longPress((UILongPressGestureRecognizer) -> Void = { _ in })
    case edge((UIScreenEdgePanGestureRecognizer) -> Void = { _ in })
    case swipe((UISwipeGestureRecognizer) -> Void = { _ in })
    case pan((UIPanGestureRecognizer) -> Void = { _ in })
    case forceTouch((UIForceTouchGestureRecognizer) -> Void = { _ in })
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
        case .tap(let block):          return { block($0 as! UITapGestureRecognizer) }
        case .pinch(let block):        return { block($0 as! UIPinchGestureRecognizer) }
        case .longPress(let block):    return { block($0 as! UILongPressGestureRecognizer) }
        case .edge(let block):         return { block($0 as! UIScreenEdgePanGestureRecognizer) }
        case .swipe(let block):        return { block($0 as! UISwipeGestureRecognizer) }
        case .pan(let block):          return { block($0 as! UIPanGestureRecognizer) }
        case .forceTouch(let block):   return { block($0 as! UIForceTouchGestureRecognizer)}
        }
    }
}

public final class GestureSubscription<S: Subscriber, G: Gesture>: NSObject, Subscription, UIGestureRecognizerDelegate where S.Input == G, S.Failure == Never {
    private var subscriber: S?
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
        let gesture = gesture.recognizer
        gesture.delegate = self
        gesture.addTarget(self, action: #selector(handler))
        view?.addGestureRecognizer(gesture)
    }
    
    public func request(_ demand: Subscribers.Demand) { }
    
    public func cancel() {
        gesture.recognizer.reset()
        gesture.recognizer.removeTarget(self, action: #selector(handler))
        view?.removeGestureRecognizer(gesture.recognizer)
        view = nil
        subscriber = nil
    }
    
    @objc
    private func handler() {
        _ = subscriber?.receive(gesture)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

public extension CBPublishers where Base: UIView {
    private func publishGesture<G: Gesture>(type: G.Type, configuration: G.Configuration) -> GesturePublisher<G> {
        GesturePublisher(view: base, gesture: G(configuration))
    }
    
    func gesture(_ gestureType: GestureType) -> GesturePublisher<AnyGesture> {
        publishGesture(type: AnyGesture.self, configuration: gestureType.configuration)
    }
    
    func tapGesture(_ configuration: TapGesture.Configuration = { _ in }) -> GesturePublisher<TapGesture> {
        publishGesture(type: TapGesture.self, configuration: configuration)
    }
    
    func panGesture(_ configuration: PanGesture.Configuration = { _ in }) -> GesturePublisher<PanGesture> {
        publishGesture(type: PanGesture.self, configuration: configuration)
    }
    
    func swipeGesture(_ configuration: SwipeGesture.Configuration = { $0.direction = [.right, .left, .up, .down] }) -> GesturePublisher<SwipeGesture> {
        publishGesture(type: SwipeGesture.self, configuration: configuration)
    }
    
    func swipeGesture(_ directions: UISwipeGestureRecognizer.Direction...) -> GesturePublisher<SwipeGesture> {
        swipeGesture{ $0.direction = .init(directions) }
    }
    
    func edgeGesture(_ configuration: EdgeGesture.Configuration = { _ in }) -> GesturePublisher<EdgeGesture> {
        publishGesture(type: EdgeGesture.self, configuration: configuration)
    }
    
    func edgeGesture(_ edges: UIRectEdge...) -> GesturePublisher<EdgeGesture> {
        edgeGesture{ $0.edges = UIRectEdge(edges) }
    }
    
    func longPressGesture(_ configuration: LongPressGesture.Configuration = { _ in }) -> GesturePublisher<LongPressGesture> {
        publishGesture(type: LongPressGesture.self, configuration: configuration)
    }
    
    func pinchGesture(_ configuration: PinchGesture.Configuration = { _ in }) -> GesturePublisher<PinchGesture> {
        publishGesture(type: PinchGesture.self, configuration: configuration)
    }
    
    func forceTouchGesture(threshold: CGFloat = 1.0, _ configuration: ForceTouchGesture.Configuration = { _ in }) -> GesturePublisher<ForceTouchGesture> {
        publishGesture(type: ForceTouchGesture.self, configuration: {
            $0.threshold = threshold
            configuration($0)
        })
    }
}
