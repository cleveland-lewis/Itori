//
//  ItoriTimerWidgetBundle.swift
//  ItoriTimerWidget
//
//  Created on 12/24/24.
//

import SwiftUI
import WidgetKit

@main
struct ItoriTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            TimerLiveActivity()
        }
    }
}
