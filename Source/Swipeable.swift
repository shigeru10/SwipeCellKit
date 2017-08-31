//
//  Swipeable.swift
//
//  Created by Jeremy Koch
//  Copyright © 2017 Jeremy Koch. All rights reserved.
//

import UIKit

// MARK: - Internal 

protocol Swipeable {
    associatedtype ActionsView
    var actionsView: ActionsView? { get }
    
    var state: SwipeState { get }
    
    var frame: CGRect { get }
}

extension SwipeTableViewCell: Swipeable {
    typealias ActionsView = SwipeActionsTableView
}
extension SwipeCollectionViewCell: Swipeable {
    typealias ActionsView = SwipeActionsCollectionView
}

enum SwipeState: Int {
    case center = 0
    case left
    case right
    case dragging
    case animatingToCenter
    
    init(orientation: SwipeActionsOrientation) {
        self = orientation == .left ? .left : .right
    }
    
    var isActive: Bool { return self != .center }
}
