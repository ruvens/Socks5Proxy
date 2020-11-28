//
//  SocksProtocolHandler.swift
//  Arion
//
//  Created by Ruven on 25.11.20.
//

import Foundation
import Network

enum SocksProtocolState {
    case method
    case request
    case streaming
    case destroyed
}

enum SocksProtocolResponse {
    case method(Data)
    case request(Data, NWEndpoint)
    case stream(Data)
    case error(SocksProtocolError, Data?)
}

enum SocksProtocolError: Error {
    case protocolViolation
    case invalidSocksVersion(Int)
    case unsupportedAuthenticationMethod
    case invalidRequestContent(String)
    case unsupportedRequestCommand(Int)
    case invalidState
}


class SocksProtocolHandler {
    
    private var state: SocksProtocolState = .method
    
    func handleData(frame: Data) -> SocksProtocolResponse {
        switch state {
        case .method:
            return handleMethod(frame: frame)
        case .request:
            return handleRequest(frame: frame)
        case .streaming:
            return .stream(frame)
        default:
            return .error(.invalidState, nil)
        }
    }
    
    private func handleMethod(frame: Data) -> SocksProtocolResponse {
        var data = frame
        
        let version = data.unpackInt(type: UInt8.self)
        guard version == 5 else {
            return .error(.invalidSocksVersion(Int(version)), nil)
        }
        
        let numMethods = data.unpackInt(type: UInt8.self)
        var methods: [UInt8] = []
        for _ in 0..<numMethods {
            methods.append(data.unpackInt(type: UInt8.self))
        }
        
        if methods.contains(0) {
            state = .request
            return .method(Data(hex: "0500"))
        } else {
            return .error(.unsupportedAuthenticationMethod, Data(hex: "05FF"))
        }
    }
    
    private func handleRequest(frame: Data) -> SocksProtocolResponse {
        var data = frame
        
        let version = data.unpackInt(type: UInt8.self)
        guard version == 5 else {
            return .error(.invalidSocksVersion(Int(version)), Data(hex: "05010001000000000000"))
        }
        
        let command = data.unpackInt(type: UInt8.self)
        if command == 1 { // CONNECT
            _ = data.unpackInt(type: UInt8.self)
            let addressType = data.unpackInt(type: UInt8.self)
            
            var destAddress: String = ""
            switch addressType {
            case 1:
                guard let address = data.unpackData(count: 4).toIpString() else {
                    return .error(.invalidRequestContent("SocksProxy: Could not parse IPv4 address"), Data(hex: "05080001000000000000"))
                }
                destAddress = address
            case 3:
                let length = data.unpackInt(type: UInt8.self)
                guard let address = String(bytes: data.unpackData(count: Int(length)).bytes, encoding: .utf8) else {
                    return .error(.invalidRequestContent("SocksProxy: Could not parse domain name address"), Data(hex: "05080001000000000000"))
                }
                destAddress = address
            case 4:
                guard let address = data.unpackData(count: 16).toIpString() else {
                    return .error(.invalidRequestContent("SocksProxy: Could not parse IPv6 address"), Data(hex: "05080001000000000000"))
                }
                destAddress = address
            default:
                return .error(.invalidRequestContent("SocksProxy: Invalid address type"), Data(hex: "05080001000000000000"))
            }
            
            let port = data.unpackInt(type: UInt16.self)
            guard let nwPort = NWEndpoint.Port(rawValue: port) else {
                return .error(.invalidRequestContent("SocksProxy: Could not parse port"), Data(hex: "05010001000000000000"))
            }

            state = .streaming
            return .request(Data(hex: "05000001000000000000"), NWEndpoint.hostPort(host: NWEndpoint.Host(destAddress), port: nwPort))
        } else {
            return .error(.unsupportedRequestCommand(Int(command)), Data(hex: "05070001000000000000"))
        }
    }
    
}
