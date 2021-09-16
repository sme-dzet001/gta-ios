//
//  CircleTransition.swift
//  GTA
//
//  Created by Артем Хрещенюк on 15.09.2021.
//

import UIKit

class CircularTransition: NSObject {
    enum CircleTransitionMode {
        case present, dismiss, pop
    }
    
    var circle = UIView()
    var startingPoint = CGPoint.zero {
        didSet {
            circle.center = startingPoint
        }
    }
    var transitionMode: CircleTransitionMode = .present
    var circleColor = UIColor.red
    var duration  = 0.3
}

extension CircularTransition: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        if transitionMode == .present {
            if let presentedView = transitionContext.view(forKey: UITransitionContextViewKey.to) {
                let viewCenter = presentedView.center
                presentConfiguration(presentedView: presentedView, containerView: containerView)
                
                UIView.animate(withDuration: duration, animations: {
                    self.circle.transform = CGAffineTransform.identity
                    presentedView.transform = CGAffineTransform.identity
                    presentedView.alpha = 1
                    presentedView.center = viewCenter
                }) { success in
                    transitionContext.completeTransition(success)
                }
            }
        } else {
            let transitionModeKey = (transitionMode == .pop) ? UITransitionContextViewKey.to : UITransitionContextViewKey.from
            
            if let returningView = transitionContext.view(forKey: transitionModeKey) {
                let viewCenter = returningView.center
                let viewSize = returningView.frame.size
                popConfiguration(viewSize: viewSize, viewCenter: viewCenter)
                
                UIView.animate(withDuration: duration, animations: {
                    self.circle.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                    returningView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                    returningView.center = self.startingPoint
                    returningView.alpha = 0
                    
                    if self.transitionMode == .pop {
                        containerView.insertSubview(returningView, belowSubview: returningView)
                        containerView.insertSubview(self.circle, belowSubview: returningView)
                    }
                }) { success in
                    returningView.center = viewCenter
                    returningView.removeFromSuperview()
                    
                    self.circle.removeFromSuperview()
                    
                    transitionContext.completeTransition(success)
                }
            }
        }
    }
    
    func frameForCircle(viewCenter: CGPoint, viewSize: CGSize, startPoint: CGPoint) -> CGRect {
        let xLength = fmax(startingPoint.x, viewSize.width - startPoint.x)
        let yLength = fmax(startPoint.y, viewSize.height - startPoint.y)
        
        let offsetVector = sqrt(xLength * xLength + yLength * yLength) * 2
        let size = CGSize(width: offsetVector, height: offsetVector)
        
        return CGRect(origin: .zero, size: size)
    }
    
    private func presentConfiguration(presentedView: UIView, containerView: UIView) {
        circle = UIView()
        circle.frame = frameForCircle(viewCenter: presentedView.center, viewSize: presentedView.frame.size, startPoint: startingPoint)
        circle.layer.cornerRadius = circle.frame.size.height / 2
        circle.center = startingPoint
        circle.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        containerView.addSubview(circle)
        
        presentedView.center = startingPoint
        presentedView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        presentedView.alpha = 0
        containerView.addSubview(presentedView)
    }
    
    private func popConfiguration(viewSize: CGSize, viewCenter: CGPoint) {
        circle.frame = frameForCircle(viewCenter: viewCenter, viewSize: viewSize, startPoint: startingPoint)
        circle.layer.cornerRadius = circle.frame.size.height / 2
        circle.center = startingPoint
    }
}
