// ViewPresenter.swift

import Foundation
import UIKit

public class ViewTransitionHandler<Controller: ViewHost, RootController: ViewHost> {
    public typealias Presentation = (_ viewController: Controller, _ parentViewController: RootController, _ animated: Bool, _ completion: (() -> Void)?) -> Void
    public typealias Dismissal = (_ viewController: Controller, _ animated: Bool, _ completion: (() -> Void)?) -> Void
    
    let _present: Presentation
    let _dismiss: Dismissal

    private var _isPresenting: Bool = false
    private var _isDismissing: Bool = false
    private var _pendingPresent: (Controller, RootController, Bool, (() -> Void)?)? = nil
    private var _pendingDismiss: (Controller, Bool, (() -> Void)?)? = nil

    public required init(present: @escaping Presentation, dismiss: @escaping Dismissal) {
        self._present = present
        self._dismiss = dismiss
    }
    
    public func present(viewController: Controller, parentViewController: RootController, animated: Bool = true, completion: (() -> Void)? = nil) {
        if _isDismissing {
            _pendingPresent = (viewController, parentViewController, animated, completion)
        } else if !_isPresenting {
            _isPresenting = true
            _present(viewController, parentViewController, animated) { [weak self] in
                completion?()
                guard let self else { return }
                _isPresenting = false
                guard let (viewController, animated, completion) = _pendingDismiss else { return }
                dismiss(viewController: viewController, 
                        animated: animated,
                        completion: completion)
            }
        }
    }
    
    public func dismiss(viewController: Controller, animated: Bool = true, completion: (() -> Void)? = nil) {
        if _isPresenting {
            _pendingDismiss = (viewController, animated, completion)
        } else if !_isDismissing {
            _isDismissing = true
            _dismiss(viewController, animated) { [weak self] in
                completion?()
                guard let self else { return }
                _isDismissing = false
                guard let (viewController, parentViewController, animated, completion) =
                        _pendingPresent else { return }
                present(viewController: viewController,
                        parentViewController: parentViewController,
                        animated: animated,
                        completion: completion)
            }
        }
    }
}

extension ViewTransitionHandler 
where Controller: UIViewController, RootController: UINavigationController
{
    public static var navigationController: Self {
        .init { controller, parentViewController, animated, completion in
            CATransaction.emit(completion: completion) {
                parentViewController.pushViewController(controller, animated: animated)
            }
        } dismiss: { controller, animated, completion in
            CATransaction.emit(completion: completion) {
                controller.navigationController?.popViewController(animated: animated)
            }
        }
    }
}

extension ViewTransitionHandler
where Controller: UIViewController, RootController: UIViewController
{
    private static var defaultPresentation: Presentation {
        { viewController, parentViewController, animated, completion in
            parentViewController.present(viewController, animated: animated, completion: completion)
        }
    }
    
    private static var defaultDismissal: Dismissal {
        { viewController, animated, completion in
            if let navigationController = viewController.navigationController,
               navigationController.children.first != viewController
            {
                CATransaction.emit(completion: completion) {
                    navigationController.popViewController(animated: animated)
                }
            } else {
                viewController.dismiss(animated: animated, completion: completion)
            }
        }
    }
    
    public static var `default`: Self {
        .init(present: defaultPresentation, dismiss: defaultDismissal)
    }
    
    public static func `default`(present: @escaping Presentation) -> Self {
        .init {
            present($0, $1, $2, $3)
        } dismiss: {
            defaultDismissal($0, $1, $2)
        }
    }
    
    public static func `default`(dismiss: @escaping Dismissal) -> Self {
        .init {
            defaultPresentation($0, $1, $2, $3)
        } dismiss: {
            dismiss($0, $1, $2)
        }
    }
    
    public static func modalFullscreen(dismiss: Dismissal? = nil) -> Self {
        .init { viewController, parentViewController, animated, completion in
            viewController.modalPresentationStyle = .fullScreen
            parentViewController.present(viewController, animated: animated, completion: completion)
        } dismiss: { viewController, animated, completion in
            (dismiss ?? defaultDismissal)(viewController, animated, completion)
        }
    }
}

extension ViewTransitionHandler
where Controller: UIViewController, RootController: UIWindow
{
    public static var window: Self {
        .init { viewController, parentViewController, animated, completion in
            parentViewController.rootViewController = viewController
            completion?()
        } dismiss: { viewController, animated, completion in
            completion?()
        }
    }
}

extension CATransaction {
    public static func emit(completion: (() -> Void)?, transaction: () -> Void) {
        begin()
        setCompletionBlock(completion)
        transaction()
        commit()
    }
}
