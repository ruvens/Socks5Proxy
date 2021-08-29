<h1 align="center">
  Socks5Proxy
</h1>

<h4 align="center">A simple Socks5 proxy in pure Swift</h4>

---

Local non-compliant Socks5 proxy server based on the Apple Network Framework.

**Some warnings**:
- Non-compliant Socks5 proxy server (e.g. does not support GSSAPI authentication)
- macOS >11.0 required 

### Motivation

This simple Socks5 proxy server was written to access tcp traffic from macOS applications. This proxy server is planned as the basis for a custom TOR proxy implementation to route tcp traffic through the TOR network.

### Getting Started

Socks5Proxy uses SwiftPM as its build tool. If you want to depend on Socks5Proxy in your own project, it's as simple as adding a dependencies clause to your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/ruvens/Socks5Proxy.git", from: "0.1.0")
]
```

### Usage

```swift
import Socks5Proxy

let streamProvider = EchoSocksStreamProvider()
let proxy = try? SocksProxyManager(streamProvider: streamProvider)

// Change the connection limit:
proxy.connectionLimit = 300 // default: 200
```

The package is build around the following classes:
- SocksProxyManager is the base class which starts the proxy upon initialization
- SocksStreamProvider is a factory providing handlers (SocksStreamHandler) for proxy requests. 
- SocksStreamHandler are responsible to connecting to the requested host and relaying data between this host and the SocksProxy

As default implementation an EchoSocksStreamProvider and an EchoSocksStreamHandler are provided within the package which purely relays the data unchanged between the SocksProxy and the requested external host.

### Extensions

The Socks5Proxy was designed to be extended into a TOR proxy.
Such an extensions requires the implementation of a TorSocksStreamProvider, which handles the creation of circuits through the TOR network and provides TOR streams as SocksStreamHandlers.

### Issues

Feel free to submit any issues [here](https://github.com/ruvens/Socks5Proxy/issues).

### References

- [SOCKS Protocol v5 Specification](https://tools.ietf.org/html/rfc1928)

### License

[MIT](https://github.com/ruvens/Socks5Proxy/blob/master/LICENSE.md)
