//
//  ListLabelStyleModifier.swift
//  SendbirdPackages
//
//  Created by Tez Park on 8/26/25.
//

import SwiftUI

struct ListLabelStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 14.5, *) {
            content.labelStyle(.titleAndIcon)
        } else {
            content.labelStyle(CompatTitleAndIconLabelStyle())
        }
    }
}
