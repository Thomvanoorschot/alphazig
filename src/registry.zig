const std = @import("std");
const act = @import("actor.zig");

const ActorInterface = act.ActorInterface;
const StringHashMap = std.StringHashMap;

pub const Registry = struct {
    actorsIDMap: StringHashMap(ActorInterface),
    actorsMessageTypeMap: StringHashMap(ActorInterface),

    pub fn init(allocator: std.mem.Allocator) Registry {
        return .{
            .actorsIDMap = StringHashMap(ActorInterface).init(allocator),
            .actorsMessageTypeMap = StringHashMap(ActorInterface).init(allocator),
        };
    }

    pub fn deinit(self: *Registry) void {
        self.actorsIDMap.deinit();
        self.actorsMessageTypeMap.deinit();
    }

    pub fn getByID(self: *Registry, id: []const u8) ?ActorInterface {
        return self.actorsIDMap.get(id);
    }

    // TODO This obviously needs to return a slice of actors
    pub fn getByMessageType(self: *Registry, messageType: []const u8) ?ActorInterface {
        return self.actorsMessageTypeMap.get(messageType);
    }

    pub fn add(self: *Registry, id: []const u8, listenToMessageTypes: []const []const u8, actor: ActorInterface) !void {
        try self.actorsIDMap.put(id, actor);
        for (listenToMessageTypes) |messageType| {
            try self.actorsMessageTypeMap.put(messageType, actor);
        }
    }
};
