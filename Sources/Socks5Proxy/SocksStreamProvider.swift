//
//  SocksClientProvider.swift
//  Arion
//
//  Created by Ruven on 28.11.20.
//

import Foundation
import Network

public protocol SocksStreamProvider {
    func getSocksStreamsHandler(endpoint: NWEndpoint, completion: @escaping (SocksStreamHandler) -> Void)
}

public class EchoSocksStreamProvider: SocksStreamProvider {
    
    public init() { }
    
    public func getSocksStreamsHandler(endpoint: NWEndpoint, completion: @escaping (SocksStreamHandler) -> Void) {
        completion(EchoSocksStreamHandler(endpoint: endpoint))
    }
    
}
