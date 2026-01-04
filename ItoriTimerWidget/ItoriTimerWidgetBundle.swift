//
//  ItoriTimerWidgetBundle.swift
//  ItoriTimerWidget
//
//  Created on 12/24/24.
//

import WidgetKit
import SwiftUI

@main
struct ItoriTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            TimerLiveActivity()
        }
    }
}
