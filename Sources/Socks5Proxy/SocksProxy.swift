//
//  SocksProxy.swift
//  Arion
//
//  Created by Ruven on 22.11.20.
//

import Foundation
import Network
import os

class SocksProxy {
    
    let id: UUID
    
    private let socket: NWConnection    
    private let queue = DispatchQueue(label: "SocksProxy", qos: .userInitiated)
    private let streamProvider: SocksStreamProvider
    private let protocolHandler = SocksProtocolHandler()
    private var client: SocksStreamHandler? = nil
    
    private let notifyConnectionCancelled: ((UUID) -> Void)
    
    private let logger = Logger(subsystem: "com.ruvens.Socks5Proxy", category: "SocksProxy")
    
    init(id: UUID, connection: NWConnection, streamProvider: SocksStreamProvider, notifyConnectionCancelled: @escaping ((UUID) -> Void)) {
        self.id = id
        self.streamProvider = streamProvider
        self.notifyConnectionCancelled = notifyConnectionCancelled
        socket = connection
        socket.stateUpdateHandler = { [weak self] state in
            switch state {
            case .waiting(let error):
                self?.logger.error("SocksProxy waiting: \(error.localizedDescription)")
                self?.cancel()
            case .failed(let error):
                self?.logger.error("SocksProxy failed: \(error.localizedDescription)")
                self?.cancel()
            case .cancelled:
                self?.client?.stop()
                self?.client = nil
                if let notify = self?.notifyConnectionCancelled {
                    notify(self!.id)
                }
            default:
                break
            }
        }
    }
    
    func start() {
        logger.debug("SocksProxy started. ID: \(self.id)")
        socket.start(queue: queue)
        receive()
    }
    
    private func cancel() {
        socket.cancel()
    }
    
    private func receive() {
        socket.receive(minimumIncompleteLength: 1, maximumLength: 65536) {
            (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                self.queue.async {
                    self.handleResponse(response: self.protocolHandler.handleData(frame: data))
                }
                if self.socket.state == .ready && !isComplete {
                    self.receive()
                }
            } else if let error = error {
                self.logger.error("SocksProxy receiving failed: \(error.localizedDescription)")
            } else if isComplete {
                self.logger.debug("SocksProxy completed connection: \(self.id)")
                self.cancel()
            } else {
                self.logger.error("SocksProxy failed to unwrap received data")
                self.cancel()
            }
        }
    }
    
    private func send(data: Data) {
        socket.send(content: data, completion: .contentProcessed( { error in
            if error != nil {
                self.logger.error("SocksProxy sending failed. Length: \(data.count) Data: \(data as NSData)")
            }
        }))
    }
    
    private func handleResponse(response: SocksProtocolResponse) {
        switch response {
        case .method(let response):
            send(data: response)
        case .request(let response, let endpoint):
            streamProvider.getSocksStreamsHandler(endpoint: endpoint) { handler in
                self.client = handler
                self.client?.cancellationHandler = { [weak self] in
                    self?.cancel()
                }
                self.client?.relayDataHandler = { [weak self] data in
                    self?.send(data: data)
                }
                self.send(data: response)
            }
        case .stream(let data):
            client?.relay(data: data)
        case .error(let error, let response):
            logger.error("SocksProxy protocol response error \(error.localizedDescription)")
            if let failureResponse = response {
                send(data: failureResponse)
            }
            cancel()
        }
        
    }
    
    deinit {
        logger.debug("SocksProxy deinitializing")
    }
}

