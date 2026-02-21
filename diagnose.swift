#!/usr/bin/env swift
import Foundation
import CoreWLAN
import Darwin

// 1. CoreWLAN info
print("=== CoreWLAN ===")
let client = CWWiFiClient.shared()
if let iface = client.interface() {
    print("Interface: \(iface.interfaceName ?? "nil")")
    print("SSID: \(iface.ssid() ?? "nil (needs location permission on macOS 14+)")")
    print("BSSID: \(iface.bssid() ?? "nil")")
    print("Power on: \(iface.powerOn())")
} else {
    print("No WiFi interface found")
}

// 2. All network interfaces via getifaddrs
print("\n=== Network Interfaces (getifaddrs) ===")
var ifaddrsPtr: UnsafeMutablePointer<ifaddrs>?
guard getifaddrs(&ifaddrsPtr) == 0, let first = ifaddrsPtr else {
    print("getifaddrs failed")
    exit(1)
}
defer { freeifaddrs(ifaddrsPtr) }

var cursor: UnsafeMutablePointer<ifaddrs>? = first
var seen = Set<String>()
while let addr = cursor {
    let name = String(cString: addr.pointee.ifa_name)
    let flags = Int32(addr.pointee.ifa_flags)
    let isUp = flags & IFF_UP != 0
    let isRunning = flags & IFF_RUNNING != 0

    if addr.pointee.ifa_addr?.pointee.sa_family == UInt8(AF_LINK), !seen.contains(name) {
        seen.insert(name)
        var bytesIn: UInt64 = 0
        var bytesOut: UInt64 = 0
        if let data = addr.pointee.ifa_data {
            let ifData = data.assumingMemoryBound(to: if_data.self).pointee
            bytesIn = UInt64(ifData.ifi_ibytes)
            bytesOut = UInt64(ifData.ifi_obytes)
        }
        let status = [isUp ? "UP" : "down", isRunning ? "RUNNING" : "idle"].joined(separator: " ")
        print("\(name): \(status) | in: \(bytesIn) out: \(bytesOut)")
    }

    // Also print IP addresses
    if addr.pointee.ifa_addr?.pointee.sa_family == UInt8(AF_INET) {
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        getnameinfo(addr.pointee.ifa_addr, socklen_t(addr.pointee.ifa_addr.pointee.sa_len),
                     &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
        let ip = String(cString: hostname)
        print("  \(name) IPv4: \(ip)")
    }

    cursor = addr.pointee.ifa_next
}

// 3. Check for hotspot IP range
print("\n=== Hotspot Detection Heuristics ===")
cursor = first
while let addr = cursor {
    if addr.pointee.ifa_addr?.pointee.sa_family == UInt8(AF_INET) {
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        getnameinfo(addr.pointee.ifa_addr, socklen_t(addr.pointee.ifa_addr.pointee.sa_len),
                     &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
        let ip = String(cString: hostname)
        let name = String(cString: addr.pointee.ifa_name)
        if ip.hasPrefix("172.20.10.") {
            print("HOTSPOT DETECTED on \(name) — IP \(ip) is in iPhone hotspot range (172.20.10.x)")
        }
    }
    cursor = addr.pointee.ifa_next
}
