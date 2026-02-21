import Foundation
import Combine

// MARK: - ResetCycle

public enum ResetCycle: String, Codable, CaseIterable, Sendable {
    case daily
    case weekly
    case monthly
    case manual
}

// MARK: - ConnectionState

public enum ConnectionState: Codable, Sendable, Equatable {
    case disconnected
    case connected(hotspotName: String, interfaceName: String)
}

// MARK: - HotspotProfile

public final class HotspotProfile: ObservableObject, Identifiable, Codable {
    public let id: UUID
    @Published public var name: String
    @Published public var dataLimitBytes: Int64?
    @Published public var alertThresholds: [Double]
    @Published public var resetCycle: ResetCycle
    @Published public var resetDay: Int?
    @Published public var currentUsageBytes: Int64
    @Published public var lastResetDate: Date

    public init(
        id: UUID = UUID(),
        name: String,
        dataLimitBytes: Int64? = nil,
        alertThresholds: [Double] = [0.5, 0.75, 0.9],
        resetCycle: ResetCycle = .monthly,
        resetDay: Int? = nil,
        currentUsageBytes: Int64 = 0,
        lastResetDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.dataLimitBytes = dataLimitBytes
        self.alertThresholds = alertThresholds
        self.resetCycle = resetCycle
        self.resetDay = resetDay
        self.currentUsageBytes = currentUsageBytes
        self.lastResetDate = lastResetDate
    }

    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case id, name, dataLimitBytes, alertThresholds, resetCycle, resetDay, currentUsageBytes, lastResetDate
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        dataLimitBytes = try container.decodeIfPresent(Int64.self, forKey: .dataLimitBytes)
        alertThresholds = try container.decode([Double].self, forKey: .alertThresholds)
        resetCycle = try container.decode(ResetCycle.self, forKey: .resetCycle)
        resetDay = try container.decodeIfPresent(Int.self, forKey: .resetDay)
        currentUsageBytes = try container.decode(Int64.self, forKey: .currentUsageBytes)
        lastResetDate = try container.decode(Date.self, forKey: .lastResetDate)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(dataLimitBytes, forKey: .dataLimitBytes)
        try container.encode(alertThresholds, forKey: .alertThresholds)
        try container.encode(resetCycle, forKey: .resetCycle)
        try container.encodeIfPresent(resetDay, forKey: .resetDay)
        try container.encode(currentUsageBytes, forKey: .currentUsageBytes)
        try container.encode(lastResetDate, forKey: .lastResetDate)
    }
}

// MARK: - UsageSession

public final class UsageSession: ObservableObject, Identifiable, Codable {
    public let id: UUID
    @Published public var profileId: UUID
    @Published public var hotspotName: String
    @Published public var startDate: Date
    @Published public var endDate: Date?
    @Published public var bytesDown: Int64
    @Published public var bytesUp: Int64

    public init(
        id: UUID = UUID(),
        profileId: UUID,
        hotspotName: String,
        startDate: Date = Date(),
        endDate: Date? = nil,
        bytesDown: Int64 = 0,
        bytesUp: Int64 = 0
    ) {
        self.id = id
        self.profileId = profileId
        self.hotspotName = hotspotName
        self.startDate = startDate
        self.endDate = endDate
        self.bytesDown = bytesDown
        self.bytesUp = bytesUp
    }

    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case id, profileId, hotspotName, startDate, endDate, bytesDown, bytesUp
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        profileId = try container.decode(UUID.self, forKey: .profileId)
        hotspotName = try container.decode(String.self, forKey: .hotspotName)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        bytesDown = try container.decode(Int64.self, forKey: .bytesDown)
        bytesUp = try container.decode(Int64.self, forKey: .bytesUp)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(profileId, forKey: .profileId)
        try container.encode(hotspotName, forKey: .hotspotName)
        try container.encode(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encode(bytesDown, forKey: .bytesDown)
        try container.encode(bytesUp, forKey: .bytesUp)
    }
}
