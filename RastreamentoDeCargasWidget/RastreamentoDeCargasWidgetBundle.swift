//
//  RastreamentoDeCargasWidgetBundle.swift
//  RastreamentoDeCargasWidget
//
//  Created by Lucas Dal Pra Brascher on 15/08/25.
//

import WidgetKit
import SwiftUI

@main
struct RastreamentoDeCargasWidgetBundle: WidgetBundle {
    var body: some Widget {
        RastreamentoDeCargasWidget()
        RastreamentoDeCargasWidgetControl()
        RastreamentoDeCargasWidgetLiveActivity()
    }
}
