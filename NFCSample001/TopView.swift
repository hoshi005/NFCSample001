//
//  TopView.swift
//  NFCSample001
//
//  Created by Susumu Hoshikawa on 2019/09/29.
//  Copyright © 2019 SH Lab, Inc. All rights reserved.
//

import SwiftUI

struct TopView: View {
    
    @ObservedObject(initialValue: TopViewModel()) var viewModel
    
    var body: some View {
        Button("読み取り開始") {
            self.viewModel.startPolling()
        }
        .alert(isPresented: $viewModel.hasError) {
            Alert(
                title: .init("エラー"),
                message: .init("エラーですね"),
                dismissButton: Alert.Button.default(.init("OK")) {
                    self.viewModel.hasError = false
                }
            )
        }
    }
}

struct TopView_Previews: PreviewProvider {
    static var previews: some View {
        TopView()
    }
}
