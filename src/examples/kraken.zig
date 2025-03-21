const std = @import("std");

pub fn serialize_request(req: SubscriptionRequest, buffer: []u8) ![]u8 {
    var stream = std.io.fixedBufferStream(buffer);
    const writer = stream.writer();

    try std.json.stringify(req, .{}, writer);
    return stream.getWritten();
}

pub fn deserialize_request(allocator: std.mem.Allocator, json_str: []const u8) !WsMessage {
    const parsed = try std.json.parseFromSlice(
        WsMessage,
        allocator,
        json_str,
        .{},
    );
    defer parsed.deinit();

    return parsed.value;
}

pub fn parseOrderbookMessage(json_str: []const u8, allocator: std.mem.Allocator) !?WsMessage {
    var raw_json = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer raw_json.deinit();

    const raw_value = raw_json.value;
    const channel_str = if (raw_value.object.get("channel")) |c| c.string else "";
    if (!std.mem.eql(u8, channel_str, "book")) {
        return null;
    }
    const type_str = if (raw_value.object.get("type")) |t| t.string else "";

    const message_type: MessageType = std.meta.stringToEnum(MessageType, type_str) orelse
        return null;

    std.debug.print("Message type: {}\n", .{message_type});
    return switch (message_type) {
        .snapshot => {
            const snapshot_json = try std.json.parseFromValue(UpdateMessage, allocator, raw_value, .{});
            return .{ .snapshot = snapshot_json.value };
        },
        .update => {
            const update_json = try std.json.parseFromValue(UpdateMessage, allocator, raw_value, .{});
            return .{ .update = update_json.value };
        },
    };
}

pub const SubscriptionRequest = struct {
    method: []const u8,
    params: struct {
        channel: []const u8,
        symbol: []const []const u8,
    },
};

const MessageType = enum { snapshot, update };

pub const WsMessage = union(MessageType) {
    snapshot: UpdateMessage,
    update: UpdateMessage,
};

pub const Order = struct {
    price: f64,
    qty: f64,
};

pub const UpdateData = struct {
    symbol: []const u8,
    bids: []const Order,
    asks: []const Order,
    checksum: u64,
    timestamp: ?[]const u8 = null,
};

pub const UpdateMessage = struct {
    channel: []const u8,
    type: []const u8,
    data: []const UpdateData,
};
