const reg = @import("registry.zig");
const act = @import("actor.zig");
const msg = @import("message.zig");
const std = @import("std");

const Allocator = std.mem.Allocator;
const Registry = reg.Registry;
const ActorInterface = act.ActorInterface;
// const MessageInterface = msg.MessageInterface;

pub const Engine = struct {
    Registry: Registry,
    allocator: Allocator,

    pub fn init(allocator: Allocator) Engine {
        return .{
            .Registry = Registry.init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Engine) void {
        self.Registry.deinit();
    }

    pub fn spawnActor(self: *Engine, comptime ActorType: type, comptime MsgType: type, id: []const u8, allocator: std.mem.Allocator) !void {
        const actorInstance = try ActorType.init(allocator);
        const wrapper = act.makeReceiveWrapper(ActorType, MsgType);
        const iface = ActorInterface.init(actorInstance, wrapper);
        try self.Registry.add(id, iface);
    }

    pub fn send(self: *Engine, id: []const u8, message: *const anyopaque) void {
        const actor = self.Registry.get(id);
        if (actor) |a| {
            a.receive(message);
        }
    }

    // pub fn request(self: *Engine, id: []const u8, message: MessageInterface) void {
    //     const actor = self.Registry.get(id);
    //     if (actor) |a| {
    //         a.receive(message);
    //     }
    // }
};
