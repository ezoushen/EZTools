// UIViewController+Combine.swift

import Combine
import UIKit

private var innerClassKey: UInt32 = 0

private class ViewControllerSwizzler<T: UIViewController> {
    unowned let viewController: T

    init(_ viewController: T) {
        self.viewController = viewController
    }

    private func isa() -> AnyClass? {
        let value = objc_getAssociatedObject(viewController, &innerClassKey) as? NSNumber
        ?? NSNumber(booleanLiteral: false)
        guard value == false else { return object_getClass(viewController) }
        guard let clazz = objc_allocateClassPair(
            object_getClass(viewController),
            "CombineCocoa_\(String(describing: T.self))",
            0)
        else { return object_getClass(viewController) }

        objc_registerClassPair(clazz)
        object_setClass(viewController, clazz)
        objc_setAssociatedObject(
            viewController,
            &innerClassKey,
            NSNumber(booleanLiteral: true),
            .OBJC_ASSOCIATION_RETAIN)

        return clazz
    }

    lazy var viewDidLoadSubject: PassthroughSubject<Void, Never> = {
        let subject = PassthroughSubject<Void, Never>()

        typealias Imp = @convention(c) (AnyObject, Selector) -> Void
        typealias Block = @convention(block) (AnyObject) -> Void

        let clazz: AnyClass = isa()!
        let selector: Selector = #selector(T.viewDidLoad)
        let method = class_getInstanceMethod(clazz, selector)!
        let originIMP = method_getImplementation(method)
        let originBlock = unsafeBitCast(originIMP, to: Imp.self)
        let block: Block = { object in
            subject.send()
            originBlock(object, selector)
        }

        method_setImplementation(method, imp_implementationWithBlock(block))

        return subject
    }()

    lazy var viewWillAppearSubject: PassthroughSubject<Bool, Never> = {
        let subject = PassthroughSubject<Bool, Never>()

        typealias Imp = @convention(c) (AnyObject, Selector, Bool) -> Void
        typealias Block = @convention(block) (AnyObject, Bool) -> Void

        let clazz: AnyClass = isa()!
        let selector: Selector = #selector(T.viewWillAppear(_:))
        let method = class_getInstanceMethod(clazz, selector)!
        let originIMP = method_getImplementation(method)
        let originBlock = unsafeBitCast(originIMP, to: Imp.self)
        let block: Block = { object, animated in
            subject.send(animated)
            originBlock(object, selector, animated)
        }

        method_setImplementation(method, imp_implementationWithBlock(block))

        return subject
    }()
    lazy var viewDidAppearSubject: PassthroughSubject<Bool, Never> = {
        let subject = PassthroughSubject<Bool, Never>()

        typealias Imp = @convention(c) (AnyObject, Selector, Bool) -> Void
        typealias Block = @convention(block) (AnyObject, Bool) -> Void

        let clazz: AnyClass = isa()!
        let selector: Selector = #selector(T.viewDidAppear(_:))
        let method = class_getInstanceMethod(clazz, selector)!
        let originIMP = method_getImplementation(method)
        let originBlock = unsafeBitCast(originIMP, to: Imp.self)
        let block: Block = { object, animated in
            subject.send(animated)
            originBlock(object, selector, animated)
        }

        method_setImplementation(method, imp_implementationWithBlock(block))

        return subject
    }()

    lazy var viewWillDisappearSubject: PassthroughSubject<Bool, Never> = {
        let subject = PassthroughSubject<Bool, Never>()

        typealias Imp = @convention(c) (AnyObject, Selector, Bool) -> Void
        typealias Block = @convention(block) (AnyObject, Bool) -> Void

        let clazz: AnyClass = isa()!
        let selector: Selector = #selector(T.viewWillDisappear(_:))
        let method = class_getInstanceMethod(clazz, selector)!
        let originIMP = method_getImplementation(method)
        let originBlock = unsafeBitCast(originIMP, to: Imp.self)
        let block: Block = { object, animated in
            subject.send(animated)
            originBlock(object, selector, animated)
        }

        method_setImplementation(method, imp_implementationWithBlock(block))

        return subject
    }()
    lazy var viewDidDisappearSubject: PassthroughSubject<Bool, Never> = {
        let subject = PassthroughSubject<Bool, Never>()

        typealias Imp = @convention(c) (AnyObject, Selector, Bool) -> Void
        typealias Block = @convention(block) (AnyObject, Bool) -> Void

        let clazz: AnyClass = isa()!
        let selector: Selector = #selector(T.viewDidDisappear(_:))
        let method = class_getInstanceMethod(clazz, selector)!
        let originIMP = method_getImplementation(method)
        let originBlock = unsafeBitCast(originIMP, to: Imp.self)
        let block: Block = { object, animated in
            subject.send(animated)
            originBlock(object, selector, animated)
        }

        method_setImplementation(method, imp_implementationWithBlock(block))

        return subject
    }()

    lazy var viewWillLayoutSubviewsSubject: PassthroughSubject<Void, Never> = {
        let subject = PassthroughSubject<Void, Never>()

        typealias Imp = @convention(c) (AnyObject, Selector) -> Void
        typealias Block = @convention(block) (AnyObject) -> Void

        let clazz: AnyClass = isa()!
        let selector: Selector = #selector(T.viewWillLayoutSubviews)
        let method = class_getInstanceMethod(clazz, selector)!
        let originIMP = method_getImplementation(method)
        let originBlock = unsafeBitCast(originIMP, to: Imp.self)
        let block: Block = { object in
            subject.send()
            originBlock(object, selector)
        }

        method_setImplementation(method, imp_implementationWithBlock(block))

        return subject
    }()
    lazy var viewDidLayoutSubviewsSubject: PassthroughSubject<Void, Never> = {
        let subject = PassthroughSubject<Void, Never>()

        typealias Imp = @convention(c) (AnyObject, Selector) -> Void
        typealias Block = @convention(block) (AnyObject) -> Void

        let clazz: AnyClass = isa()!
        let selector: Selector = #selector(T.viewDidLayoutSubviews)
        let method = class_getInstanceMethod(clazz, selector)!
        let originIMP = method_getImplementation(method)
        let originBlock = unsafeBitCast(originIMP, to: Imp.self)
        let block: Block = { object in
            subject.send()
            originBlock(object, selector)
        }

        method_setImplementation(method, imp_implementationWithBlock(block))

        return subject
    }()

    lazy var willMoveToParentViewControllerSubject: PassthroughSubject<UIViewController?, Never> = {
        let subject = PassthroughSubject<UIViewController?, Never>()

        typealias Imp = @convention(c) (AnyObject, Selector, UIViewController?) -> Void
        typealias Block = @convention(block) (AnyObject, UIViewController?) -> Void

        let clazz: AnyClass = isa()!
        let selector: Selector = #selector(T.viewDidLayoutSubviews)
        let method = class_getInstanceMethod(clazz, selector)!
        let originIMP = method_getImplementation(method)
        let originBlock = unsafeBitCast(originIMP, to: Imp.self)
        let block: Block = { object, parent in
            subject.send(parent)
            originBlock(object, selector, parent)
        }

        method_setImplementation(method, imp_implementationWithBlock(block))

        return subject
    }()
    lazy var didMoveToParentViewControllerSubject: PassthroughSubject<UIViewController?, Never> = {
        let subject = PassthroughSubject<UIViewController?, Never>()

        typealias Imp = @convention(c) (AnyObject, Selector, UIViewController?) -> Void
        typealias Block = @convention(block) (AnyObject, UIViewController?) -> Void

        let clazz: AnyClass = isa()!
        let selector: Selector = #selector(T.didMove(toParent:))
        let method = class_getInstanceMethod(clazz, selector)!
        let originIMP = method_getImplementation(method)
        let originBlock = unsafeBitCast(originIMP, to: Imp.self)
        let block: Block = { object, parent in
            subject.send(parent)
            originBlock(object, selector, parent)
        }

        method_setImplementation(method, imp_implementationWithBlock(block))

        return subject
    }()

    lazy var didReceiveMemoryWarningSubject: PassthroughSubject<Void, Never> = {
        let subject = PassthroughSubject<Void, Never>()

        typealias Imp = @convention(c) (AnyObject, Selector) -> Void
        typealias Block = @convention(block) (AnyObject) -> Void

        let clazz: AnyClass = isa()!
        let selector: Selector = #selector(T.didReceiveMemoryWarning)
        let method = class_getInstanceMethod(clazz, selector)!
        let originIMP = method_getImplementation(method)
        let originBlock = unsafeBitCast(originIMP, to: Imp.self)
        let block: Block = { object in
            subject.send()
            originBlock(object, selector)
        }

        method_setImplementation(method, imp_implementationWithBlock(block))

        return subject
    }()
}

private var swizzlerKey: UInt32 = 0
public extension CBPublishers where Base: UIViewController {
    private func swizzler() -> ViewControllerSwizzler<Base> {
        guard let swizzler = objc_getAssociatedObject(base, &swizzlerKey)
                as? ViewControllerSwizzler<Base> else {
                    let swizzler = ViewControllerSwizzler<Base>(base)
                    objc_setAssociatedObject(base, &swizzlerKey, swizzler, .OBJC_ASSOCIATION_RETAIN)
                    return swizzler
                }
        return swizzler
    }

    func viewDidLoad() -> AnyPublisher<Void, Never> {
        swizzler().viewDidLoadSubject.eraseToAnyPublisher()
    }

    func viewWillAppear() -> AnyPublisher<Bool, Never> {
        swizzler().viewWillAppearSubject.eraseToAnyPublisher()
    }

    func viewDidAppear() -> AnyPublisher<Bool, Never> {
        swizzler().viewDidAppearSubject.eraseToAnyPublisher()
    }

    func viewWillDisappear() -> AnyPublisher<Bool, Never> {
        swizzler().viewWillDisappearSubject.eraseToAnyPublisher()
    }

    func viewDidDisappear() -> AnyPublisher<Bool, Never> {
        swizzler().viewDidDisappearSubject.eraseToAnyPublisher()
    }

    func viewWillLayoutSubviews() -> AnyPublisher<Void, Never> {
        swizzler().viewWillLayoutSubviewsSubject.eraseToAnyPublisher()
    }

    func viewDidLayoutSubviews() -> AnyPublisher<Void, Never> {
        swizzler().viewDidLayoutSubviewsSubject.eraseToAnyPublisher()
    }

    func willMoveToParentViewController() -> AnyPublisher<UIViewController?, Never> {
        swizzler().willMoveToParentViewControllerSubject.eraseToAnyPublisher()
    }

    func didMoveToParentViewController() -> AnyPublisher<UIViewController?, Never> {
        swizzler().didMoveToParentViewControllerSubject.eraseToAnyPublisher()
    }

    func didReceiveMemoryWarning() -> AnyPublisher<Void, Never> {
        swizzler().didReceiveMemoryWarningSubject.eraseToAnyPublisher()
    }
}
