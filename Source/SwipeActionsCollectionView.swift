//
//  SwipeActionsCollectionView.swift
//  SwipeCellKit
//
//  Created by SuzukiShigeru on 2017/08/31.
//
//

import UIKit

protocol SwipeActionsCollectionViewDelegate: class {
    func swipeActionsCollectionView(_ swipeActionsCollectionView: SwipeActionsCollectionView, didSelect action: SwipeAction)
}

class SwipeActionsCollectionView: UIView {
    weak var delegate: SwipeActionsCollectionViewDelegate?
    
    let transitionLayout: SwipeTransitionLayout
    var layoutContext: ActionsViewLayoutContext
    
    var feedbackGenerator: SwipeFeedback
    
    var expansionAnimator: SwipeAnimator?
    
    var expansionCollectionDelegate: SwipeExpanding? {
        return options.expansionCollectionDelegate ?? (expandableAction?.hasBackgroundColor == false ? ScaleAndAlphaExpansion.default : nil)
    }
    
    let orientation: SwipeActionsOrientation
    let actions: [SwipeAction]
    
    let options: SwipeCollectionOptions
    
    var buttons: [SwipeActionButton] = []
    
    var minimumButtonWidth: CGFloat = 0
    var maximumImageHeight: CGFloat {
        return actions.reduce(0, { initial, next in max(initial, next.image?.size.height ?? 0) })
    }
    
    var visibleWidth: CGFloat = 0 {
        didSet {
            let preLayoutVisibleWidths = transitionLayout.visibleWidthsForViews(with: layoutContext)
            
            layoutContext = ActionsViewLayoutContext.newContext(for: self)
            
            transitionLayout.container(view: self, didChangeVisibleWidthWithContext: layoutContext)
            
            setNeedsLayout()
            layoutIfNeeded()
            
            notifyVisibleWidthChanged(oldWidths: preLayoutVisibleWidths,
                                      newWidths: transitionLayout.visibleWidthsForViews(with: layoutContext))
        }
    }
    
    var preferredWidth: CGFloat {
        return minimumButtonWidth * CGFloat(actions.count)
    }
    
    var contentSize: CGSize {
        if options.expansionStyle?.elasticOverscroll != true || visibleWidth < preferredWidth {
            return CGSize(width: visibleWidth, height: bounds.height)
        } else {
            let scrollRatio = max(0, visibleWidth - preferredWidth)
            return CGSize(width: preferredWidth + (scrollRatio * 0.25), height: bounds.height)
        }
    }
    
    private(set) var expanded: Bool = false
    
    var expandableAction: SwipeAction? {
        return options.expansionStyle != nil ? actions.last : nil
    }
    
    init(maxSize: CGSize, options: SwipeCollectionOptions, orientation: SwipeActionsOrientation, actions: [SwipeAction]) {
        self.options = options
        self.orientation = orientation
        self.actions = actions.reversed()
        
        switch options.transitionStyle {
        case .border:
            transitionLayout = BorderTransitionLayout()
        case .reveal:
            transitionLayout = RevealTransitionLayout()
        default:
            transitionLayout = DragTransitionLayout()
        }
        
        self.layoutContext = ActionsViewLayoutContext(numberOfActions: actions.count, orientation: orientation)
        
        feedbackGenerator = SwipeFeedback(style: .light)
        feedbackGenerator.prepare()
        
        super.init(frame: .zero)
        
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = options.backgroundColor ?? #colorLiteral(red: 0.862745098, green: 0.862745098, blue: 0.862745098, alpha: 1)
        
        buttons = addButtons(for: self.actions, withMaximum: maxSize)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addButtons(for actions: [SwipeAction], withMaximum size: CGSize) -> [SwipeActionButton] {
        let buttons: [SwipeActionButton] = actions.map({ action in
            let actionButton = SwipeActionButton(action: action)
            actionButton.addTarget(self, action: #selector(actionTapped(button:)), for: .touchUpInside)
            actionButton.autoresizingMask = [.flexibleHeight, orientation == .right ? .flexibleRightMargin : .flexibleLeftMargin]
            actionButton.spacing = options.buttonSpacing ?? 8
            actionButton.contentEdgeInsets = buttonEdgeInsets(fromOptions: options)
            return actionButton
        })
        
        let maximum = options.maximumButtonWidth ?? (size.width - 30) / CGFloat(actions.count)
        minimumButtonWidth = buttons.reduce(options.minimumButtonWidth ?? 74, { initial, next in max(initial, next.preferredWidth(maximum: maximum)) })
        
        buttons.enumerated().forEach { (index, button) in
            let action = actions[index]
            let frame = CGRect(origin: .zero, size: CGSize(width: bounds.width, height: bounds.height))
            let wrapperView = SwipeActionButtonWrapperView(frame: frame, action: action, orientation: orientation, contentWidth: minimumButtonWidth)
            wrapperView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            wrapperView.addSubview(button)
            
            if let effect = action.backgroundEffect {
                let effectView = UIVisualEffectView(effect: effect)
                effectView.frame = wrapperView.frame
                effectView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                effectView.contentView.addSubview(wrapperView)
                addSubview(effectView)
            } else {
                addSubview(wrapperView)
            }
            
            button.frame = wrapperView.contentRect
            button.maximumImageHeight = maximumImageHeight
            button.verticalAlignment = options.buttonVerticalAlignment
            button.shouldHighlight = action.hasBackgroundColor
        }
        
        return buttons
    }
    
    func actionTapped(button: SwipeActionButton) {
        guard let index = buttons.index(of: button) else { return }
        
        delegate?.swipeActionsCollectionView(self, didSelect: actions[index])
    }
    
    func buttonEdgeInsets(fromOptions options: SwipeCollectionOptions) -> UIEdgeInsets {
        let padding = options.buttonPadding ?? 8
        return UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
    }
    
    func setExpanded(expanded: Bool, feedback: Bool = false) {
        guard self.expanded != expanded else { return }
        
        self.expanded = expanded
        
        if feedback {
            feedbackGenerator.impactOccurred()
            feedbackGenerator.prepare()
        }
        
        let timingParameters = expansionCollectionDelegate?.animationTimingParameters(buttons: buttons.reversed(), expanding: expanded)
        
        if expansionAnimator?.isRunning == true {
            expansionAnimator?.stopAnimation(true)
        }
        
        if #available(iOS 10, *) {
            expansionAnimator = UIViewPropertyAnimator(duration: timingParameters?.duration ?? 0.6, dampingRatio: 1.0)
        } else {
            expansionAnimator = UIViewSpringAnimator(duration: timingParameters?.duration ?? 0.6,
                                                     damping: 1.0,
                                                     initialVelocity: 1.0)
        }
        
        expansionAnimator?.addAnimations {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        
        expansionAnimator?.startAnimation(afterDelay: timingParameters?.delay ?? 0)
        
        notifyExpansion(expanded: expanded)
    }
    
    func notifyVisibleWidthChanged(oldWidths: [CGFloat], newWidths: [CGFloat]) {
        DispatchQueue.main.async {
            oldWidths.enumerated().forEach { index, oldWidth in
                let newWidth = newWidths[index]
                
                if oldWidth != newWidth {
                    let context = SwipeActionTransitioningContext(actionIdentifier: self.actions[index].identifier,
                                                                  button: self.buttons[index],
                                                                  newPercentVisible: newWidth / self.minimumButtonWidth,
                                                                  oldPercentVisible: oldWidth / self.minimumButtonWidth,
                                                                  wrapperView: self.subviews[index])
                    
                    self.actions[index].transitionDelegate?.didTransition(with: context)
                }
            }
        }
    }
    
    func notifyExpansion(expanded: Bool) {
        guard let expandedButton = buttons.last else { return }
        
        expansionCollectionDelegate?.actionButton(expandedButton, didChange: expanded, otherActionButtons: buttons.dropLast().reversed())
    }
    
    func createDeletionMask() -> UIView {
        let mask = UIView(frame: CGRect(x: min(0, frame.minX), y: 0, width: bounds.width * 2, height: bounds.height))
        mask.backgroundColor = UIColor.white
        return mask
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        for subview in subviews.enumerated() {
            transitionLayout.layout(view: subview.element, atIndex: subview.offset, with: layoutContext)
        }
        
        if expanded {
            subviews.last?.frame.origin.x = 0 + bounds.origin.x
        }
    }
}
