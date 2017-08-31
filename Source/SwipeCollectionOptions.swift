//
//  SwipeCollectionOptions.swift
//  SwipeCellKit
//
//  Created by SuzukiShigeru on 2017/08/29.
//
//

import UIKit

/// The `SwipeCollectionOptions` class provides options for transistion and expansion behavior for swiped cell.
public struct SwipeCollectionOptions {
    /// The transition style. Transition is the style of how the action buttons are exposed during the swipe.
    public var transitionStyle: SwipeTransitionStyle = .border
    
    /// The expansion style. Expansion is the behavior when the cell is swiped past a defined threshold.
    public var expansionStyle: SwipeExpansionStyle?
    
    /// The object that is notified when expansion changes.
    ///
    /// - note: If an `expansionCollectionDelegate` is not provided, and the expanding action is configured with a clear background, the system automatically uses the default `ScaleAndAlphaExpansion` to show/hide underlying actions.
    public var expansionCollectionDelegate: SwipeExpanding?
    
    /// The background color behind the action buttons.
    public var backgroundColor: UIColor?
    
    /// The largest allowable button width.
    ///
    /// - note: By default, the value is set to the collection view divided by the number of action buttons minus some additional padding. If the value is set to 0, then word wrapping will not occur and the buttons will grow as large as needed to fit the entire title/image.
    public var maximumButtonWidth: CGFloat?
    
    /// The smallest allowable button width.
    ///
    /// - note: By default, the system chooses an appropriate size.
    public var minimumButtonWidth: CGFloat?
    
    /// The vertical alignment mode used for when a button image and title are present.
    public var buttonVerticalAlignment: SwipeVerticalAlignment = .centerFirstBaseline
    
    /// The amount of space, in points, between the border and the button image or title.
    public var buttonPadding: CGFloat?
    
    /// The amount of space, in points, between the button image and the button title.
    public var buttonSpacing: CGFloat?
    
    /// Constructs a new `SwipeCollectionOptions` instance with default options.
    public init() {}
}
