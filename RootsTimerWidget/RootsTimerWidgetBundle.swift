//
//  RootsTimerWidgetBundle.swift
//  RootsTimerWidget
//
//  Created on 12/24/24.
//

import WidgetKit
import SwiftUI

@main
struct RootsTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            TimerLiveActivity()
        }
    }
}
