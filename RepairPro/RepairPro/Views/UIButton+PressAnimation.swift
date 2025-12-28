//
//  UIButton+PressAnimation.swift
//  RepairPro
//
//  Created by ec2-user on 28/12/2025.
//

import UIKit

extension UIButton {

    /// Simple press animation (tap feedback)
    func addPressAnimation() {
        addTarget(self, action: #selector(animateTap), for: .touchUpInside)
    }

    /// Animate, THEN execute completion (for navigation)
    func animateAndThen( completion: @escaping () -> Void) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        UIView.animate(withDuration: 0.08, animations: {
            self.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            self.alpha = 0.85
        }, completion: {_  in
            UIView.animate(withDuration: 0.12, animations: {
                self.transform = .identity
                self.alpha = 1
            }, completion: {_  in
                completion()
            })
        })
    }

    @objc private func animateTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        UIView.animate(withDuration: 0.08, animations: {
            self.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
            self.alpha = 0.9
        }, completion: {_  in
            UIView.animate(withDuration: 0.12) {
                self.transform = .identity
                self.alpha = 1
            }
        })
    }
}
