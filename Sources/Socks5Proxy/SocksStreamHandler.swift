//
//  SocksStreamHandler.swift
//  Arion
//
//  Created by Ruven on 25.11.20.
//

import Foundation
import Network
import os

public protocol SocksStreamHandler {
    
    func start(completion: @escaping () -> Void)
    func relay(data: Data)
    func stop()
    
}

class EchoSocksStreamHandler: SocksStreamHandler {
    
    private let socket: NWConnection
    private let queue = DispatchQueue(label: "EchoSocksClient", qos: .userInitiated)
    
    private let cancellationHandler: (() -> Void)
    private let relayDataHandler: ((Data) -> Void)
    private var startReadyHandler: (() -> Void)? = nil
    
    private let logger = Logger(subsystem: "com.ruvens.Socks5Proxy", category: "EchoSocksClient")
    
    required init(endpoint: NWEndpoint, relayDataHandler: @escaping ((Data) -> Void), cancellationHandler: @escaping (() -> Void)) {
        self.relayDataHandler = relayDataHandler
        self.cancellationHandler = cancellationHandler
        
        let tcpconfig: NWParameters = .tcp
        tcpconfig.preferNoProxies = true
        socket = NWConnection(to: endpoint, using: tcpconfig)
        socket.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                if let notifyStartComplete = self?.startReadyHandler {
                    notifyStartComplete()
                }
            case .waiting(let error):
                self?.logger.error("SocksProxy waiting: \(error.localizedDescription)")
                self?.socket.cancel()
            case .failed(let error):
                self?.logger.error("SocksProxy failed: \(error.localizedDescription)")
                self?.socket.cancel()
            case .cancelled:
                self?.cancellationHandler()
            default:
                break
            }
        }
        socket.start(queue: queue)
    }
    
    func start(completion: @escaping () -> Void) {
        startReadyHandler = completion
        socket.start(queue: queue)
        receive()
    }
    
    func stop() {
        if socket.state != .cancelled {
            socket.cancel()
        }
    }
    
    private func receive() {
        socket.receive(minimumIncompleteLength: 1, maximumLength: 65536) {
            (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                self.relayDataHandler(data)
                if self.socket.state == .ready && !isComplete {
                    self.receive()
                }
            } else if let error = error {
                self.logger.error("EchoSocksClient receiving failed: \(error.localizedDescription)")
            } else if isComplete {
                self.logger.debug("EchoSocksClient completed connection")
                self.stop()
            } else {
                self.logger.error("EchoSocksClient failed to unwrap received data")
                self.stop()
                
            }
        }
    }
    
    private func send(data: Data) {
        socket.send(content: data, completion: .contentProcessed( { error in
            if error != nil {
                self.logger.error("EchoSocksClient sending failed. Length: \(data.count) Data: \(data as NSData)")
            }
        }))
    }
    
    func relay(data: Data) {
        send(data: data)
    }
    
    deinit {
        logger.debug("EchoClient deinitializing")
    }
}
