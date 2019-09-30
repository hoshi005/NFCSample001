//
//  TopViewModel.swift
//  NFCSample001
//
//  Created by Susumu Hoshikawa on 2019/09/29.
//  Copyright © 2019 SH Lab, Inc. All rights reserved.
//

import Foundation
import Combine
import CoreNFC

class TopViewModel: NSObject, ObservableObject {
    
    @Published var hasError = false
    
    func startPolling() {
        print(#function)
        
        guard NFCTagReaderSession.readingAvailable else {
            self.hasError = true
            return
        }
        
        // スキャン開始.
        // このタイミングで読み取り用のUIが表示される.
        // .iso18092 はFeliCa.
        if let session = NFCTagReaderSession(pollingOption: .iso18092, delegate: self) {
            session.alertMessage = "スキャン中だよ！"
            session.begin()
        } else {
            self.hasError = true
        }
    }
}

extension TopViewModel: NFCTagReaderSessionDelegate {
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print(#function)
    }
    
    
    /// 明示的にsessionを終了した時にも呼び出されるので注意.
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print(#function)
        print("error: \(error.localizedDescription)")
        
        if let readerError = error as? NFCReaderError {
            if readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead
                && readerError.code != .readerSessionInvalidationErrorUserCanceled {
                
                self.hasError = true
                return
            }
        }
        
    }
    
    /// タグ検出時に呼び出される.
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        print(#function)
        
        if 1 < tags.count {
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "複数のタグが検出されてしまったので、もう一度やってください。"
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                session.restartPolling()
            }
            return
        }
        
        let tag = tags.first!
        
        // タグへの接続.
        session.connect(to: tag) { error in
            
            if let error = error {
                session.invalidate(errorMessage: "失敗したので、もう一度やってください. \(error.localizedDescription)")
                return
            }
            
            guard case .feliCa(let feliCaTag) = tag else {
                let retryInterval = DispatchTimeInterval.milliseconds(500)
                session.alertMessage = "これはFeliCaではないみたい。もう一回試してね。"
                DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                    session.restartPolling()
                }
                return
            }
            
//            let idm = feliCaTag.currentIDm.map { String(format: "%.2hhx", $0) }.joined()
//            let systemCode = feliCaTag.currentSystemCode.map { String(format: "%.2hhx", $0) }.joined()
//
//            debugPrint("IDm: \(idm)")
//            debugPrint("System Code: \(systemCode)")
//
//            session.alertMessage = "Read success!\nIDm: \(idm)\nSystem Code: \(systemCode)"
//            session.invalidate()
            
            // サービスコードの定義.
            let historyServiceCode = Data([0x09, 0x0f].reversed())
            
            // FeliCaコマンドの「Request Service」を実行.
            feliCaTag.requestService(nodeCodeList: [historyServiceCode]) { nodes, error in
                
                if let error = error {
                    session.invalidate(errorMessage: "失敗したので、もう一度やってください. \(error.localizedDescription)")
                    return
                }
                
                // Request Service のレスポンスが FF FF であればサービスが存在している.
                guard let data = nodes.first, data != Data([0xff, 0xff]) else {
                    session.invalidate(errorMessage: "サービスが存在しない.")
                    return
                }
                
                let blockList = (0..<12).map { Data([0x80, UInt8($0)]) }
                
                feliCaTag.readWithoutEncryption(
                    serviceCodeList: [historyServiceCode],
                    blockList: blockList
                ) { status1, status2, dataList, error in
                    
                    if let error = error {
                        session.invalidate(errorMessage: "失敗したので、もう一度やってください. \(error.localizedDescription)")
                        return
                    }
                    
                    guard status1 == 0x00, status2 == 0x00 else {
                        session.invalidate(errorMessage: "ステータスフラグエラー: \(status1)/\(status2)")
                        return
                    }
                    
                    session.invalidate()
                    
                    dataList.forEach { data in
                        print("=============================================")
                        print("年: ", Int(data[4] >> 1) + 2000)
                        print("月: ", ((data[4] & 1) == 1 ? 8 : 0) + Int(data[5] >> 5))
                        print("日: ", Int(data[5] & 0x1f))
                        print("入場駅コード: ", data[6...7].map { String(format: "%02x", $0) }.joined())
                        print("出場駅コード: ", data[8...9].map { String(format: "%02x", $0) }.joined())
                        print("入場地域コード: ", String(Int(data[15] >> 6), radix: 16))
                        print("出場地域コード: ", String(Int((data[15] & 0x30) >> 4), radix: 16))
                        print("残高: ", Int(data[10]) + Int(data[11]) << 8)
                    }
                }
            }
        }
    }
}
