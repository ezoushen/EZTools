// View.swift

import Foundation
import SwiftUI

class HostingController<Content: View & ViewComponent>: UIHostingController<Content> {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        rootView.viewDidAppear(view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rootView.viewWillAppear(view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rootView.viewDidLoad(view)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        rootView.viewWillLayoutSubviews(view)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        rootView.viewDidLayoutSubviews(view)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        rootView.viewDidDisappear(view)
    }
}

public protocol ViewHost: AnyObject { }

public protocol ViewComponent {
    associatedtype ViewModel: AppArchitecture.ViewModel = EmptyViewModel
    
    static func setupAppearance()
    
    var viewModel: ViewModel { get }
    
    func asViewController() -> UIViewController
    
    func viewDidLoad(_ view: UIView)
    
    func viewDidAppear(_ view: UIView)
    
    func viewWillAppear(_ view: UIView)
    
    func viewDidDisappear(_ view: UIView)
    
    func viewDidLayoutSubviews(_ view: UIView)
    
    func viewWillLayoutSubviews(_ view: UIView)
}

public extension ViewComponent {
    static func setupAppearance() { }
    
    func viewDidLoad(_ view: UIView) { }
    
    func viewDidAppear(_ view: UIView) { }
    
    func viewWillAppear(_ view: UIView) { }
    
    func viewDidDisappear(_ view: UIView) { }
    
    func viewDidLayoutSubviews(_ view: UIView) { }
    
    func viewWillLayoutSubviews(_ view: UIView) { }
}

public extension ViewComponent where ViewModel == EmptyViewModel {
    var viewModel: ViewModel {
        .init()
    }
}

public final class EmptyView: UIViewController, ViewComponent {
    public typealias ViewModel = EmptyViewModel
}

fileprivate class ViewController<View: ViewComponent & SwiftUI.View>: UIViewController {
    let hostingController: HostingController<View>
    
    init(_ hostingController: HostingController<View>) {
        hostingController.view.backgroundColor = .clear
        hostingController.view.clipsToBounds = true
        
        self.hostingController = hostingController
        
        super.init(nibName: nil, bundle: nil)
        
        view.backgroundColor = .clear
        attachChild(hostingController)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        hostingController.view.sizeToFit()
        view.frame.size = hostingController.view.frame.size
    }
}

extension ViewComponent where Self: View {
    public func asViewController() -> UIViewController {
        let hostingController = HostingController(rootView: self)
        return ViewController(hostingController)
    }
}

extension ViewComponent where Self: UIViewController {
    public func asViewController() -> UIViewController {
        self
    }
}

extension ViewComponent where Self: UIView {
    public func asViewController() -> UIViewController {
        let viewController = UIViewController()
        let view = viewController.view!
        view.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        return viewController
    }
}

extension UIWindow: ViewComponent {
    public var viewModel: EmptyViewModel {
        .init()
    }
    
    public typealias ViewModel = EmptyViewModel
}

extension UIWindow: ViewHost {
    static var rootWindow: UIWindow!
}

extension UIViewController: ViewHost { }

extension UIViewController {
    @objc open func attachChild(_ viewController: UIViewController, in viewport: UIView? = nil) {
        let view: UIView = viewport ?? self.view
        
        addChild(viewController)
        viewController.view.frame.size = view.frame.size
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
    }
    
    @objc open func detachFromParent() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}

extension UIViewController: UIAdaptivePresentationControllerDelegate { }
