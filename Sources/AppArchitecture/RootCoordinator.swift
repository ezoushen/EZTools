//
//  RootCoordinator.swift
//
//
//  Created by EZOU on 2023/8/30.
//

import Combine
import Foundation
import UIKit

public protocol RootCoordinator: Coordinator
where RootController == UIWindow, View == EmptyView {
    var window: UIWindow { get }
    func route() -> ResultPublisher
}

public extension RootCoordinator where Controller == UIWindow {
    func makeController(from viewController: UIViewController) -> Controller {
        window
    }
}

public extension RootCoordinator {
    func route(with viewModel: View.ViewModel) -> ResultPublisher {
        route()
    }
    
    func active() -> AnyCancellable {
        if window.isKeyWindow {
            UIWindow.rootWindow = window
        }
        
        return route().sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }
}
