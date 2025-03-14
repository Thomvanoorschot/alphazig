const std = @import("std");
const alphazig = @import("alphazig");
const testing = std.testing;
const concurrency = alphazig.concurrency;
const obHolder = @import("orderbook_holder.zig");

const Allocator = std.mem.Allocator;
const Context = alphazig.Context;

const OrderbookHolder = obHolder.OrderbookHolder;
const OrderbookHolderMessage = obHolder.OrderbookHolderMessage;

pub const OrderbookHolderManagerMessage = union(enum) {
    spawn_holder: struct { id: []const u8 },
    start_all_holders: struct {},
};

pub const OrderbookHolderManager = struct {
    ctx: *Context,

    const Self = @This();
    pub fn init(ctx: *Context, allocator: Allocator) !*Self {
        const self = try allocator.create(Self);
        self.* = .{
            .ctx = ctx,
        };
        return self;
    }

    pub fn receive(self: *Self, message: *const OrderbookHolderManagerMessage) !void {
        switch (message.*) {
            .spawn_holder => |m| {
                const holder = try self.ctx.spawnChildActor(OrderbookHolder, OrderbookHolderMessage, .{
                    .id = m.id,
                });
                try holder.send(OrderbookHolderMessage{ .init = .{ .ticker = m.id } });
            },
            .start_all_holders => |_| {
                for (self.ctx.child_actors.items) |actor| {
                    try actor.send(OrderbookHolderMessage{ .start = .{} });
                }
            },
        }
    }
};
