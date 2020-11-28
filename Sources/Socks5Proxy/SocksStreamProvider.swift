//
//  SocksClientProvider.swift
//  Arion
//
//  Created by Ruven Schneider on 28.11.20.
//

import Foundation
import Network

public protocol SocksStreamProvider {
    
   func getSocksStreamsHandler(endpoint: NWEndpoint, relayDataHandler: @escaping  ((Data) -> Void), cancellationHandler: @escaping  (() -> Void)) -> SocksStreamHandler

}

public class EchoSocksStreamProvider: SocksStreamProvider {
    
    public func getSocksStreamsHandler(endpoint: NWEndpoint, relayDataHandler: @escaping  ((Data) -> Void), cancellationHandler: @escaping  (() -> Void)) -> SocksStreamHandler {
        return EchoSocksStreamHandler(endpoint: endpoint, relayDataHandler: relayDataHandler, cancellationHandler: cancellationHandler)
    }
    
}
