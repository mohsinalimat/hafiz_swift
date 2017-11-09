//
//  LayerView.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 11/5/17.
//  Copyright © 2017 Ramy Eldesoky. All rights reserved.
//

import UIKit

class LayerView : UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest( point, with: event )
        if view == self{
            return nil //transparent layer, relay to lower layers
        }
        return view // child views can handle the touch hits
    }
}
