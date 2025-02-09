//
//  SocksProxyManager.swift
//  Arion
//
//  Created by Ruven on 22.11.20.
//

import Foundation
import Network
import os

public class SocksProxyManager {
    
    public var connectionLimit = 200
    
    private let listener: NWListener
    private var sockets: [UUID: SocksProxy] = [:]
    
    private let queue = DispatchQueue(label: "SocksProxyManager", qos: .userInitiated)
    private let logger = Logger(subsystem: "com.ruvens.Socks5Proxy", category: "SocksProxyManager")
    
    private let streamProvider: SocksStreamProvider
    
    public init(streamProvider: SocksStreamProvider) throws {
        self.streamProvider = streamProvider
        let tcpconfig: NWParameters = .tcp
        tcpconfig.acceptLocalOnly = true
        listener = try NWListener(using: tcpconfig, on: 1080)
        listener.newConnectionHandler = handleNewConnection
        listener.newConnectionLimit = connectionLimit
        
        logger.debug("SocksProxyManager: Socks5 Server started listening @localhost:1080")
        listener.start(queue: queue)
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        logger.debug("SocksyProxy Manager has \(self.sockets.count) active proxy connections")
        let newSocketID = UUID()
        let proxy = SocksProxy(id: newSocketID, connection: connection, streamProvider: streamProvider, notifyConnectionCancelled: removeSocket)
        sockets[proxy.id] = proxy
        proxy.start()
    }
    
    private func removeSocket(id: UUID) {
        sockets.removeValue(forKey: id)
        logger.debug("SocksProxyManager: Removed \(id). \(self.sockets.count) active connections remaining")
    }
}
