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
    
    func read() {
        debugPrint(#function)
        
        guard NFCTagReaderSession.readingAvailable else {
            self.hasError = true
            return
        }
        
        let session = NFCTagReaderSession(pollingOption: .iso18092, delegate: self)
        session?.alertMessage = "スキャン中だよ！"
        session?.begin()
    }
    
}

extension TopViewModel: NFCTagReaderSessionDelegate {
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        debugPrint(#function)
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        debugPrint(#function)
        debugPrint("error: \(error.localizedDescription)")
        
        if let readerError = error as? NFCReaderError {
            if readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead
                && readerError.code != .readerSessionInvalidationErrorUserCanceled {
                
                self.hasError = true
                return
            }
        }
        
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        debugPrint(#function)
        
        if 1 < tags.count {
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "複数のタグが検出されてしまったので、もう一度やってください。"
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                session.restartPolling()
            }
            return
        }
        
        let tag = tags.first!
        
        session.connect(to: tag) { error in
            
            if let _ = error {
                session.invalidate(errorMessage: "失敗したので、もう一度やってください")
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
            
            debugPrint(feliCaTag)
            
            let idm = feliCaTag.currentIDm.map { String(format: "%.2hhx", $0) }.joined()
            let systemCode = feliCaTag.currentSystemCode.map { String(format: "%.2hhx", $0) }.joined()
            
            debugPrint("IDm: \(idm)")
            debugPrint("System Code: \(systemCode)")
            
            session.alertMessage = "Read success!\nIDm: \(idm)\nSystem Code: \(systemCode)"
            session.invalidate()
        }
    }
}
