const std = @import("std");
const alphazig = @import("alphazig");
const testing = std.testing;
const concurrency = alphazig.concurrency;

const Engine = alphazig.Engine;
const Coroutine = concurrency.Coroutine;
const Context = concurrency.Context;
const Channel = concurrency.Channel;
const EmptyArgs = concurrency.EmptyArgs;
pub fn main() !void {
    concurrency.run(mainRoutine);
}
pub fn mainRoutine(_: *Context, _: EmptyArgs) !void {
    // ctx.add(1);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var engine = Engine.init(allocator);
    defer engine.deinit();

    const candlestick_receiver = try engine.spawnActor(CandlestickReceiver, CanclestickReveiverMessage, .{
        .id = "candlestick_receiver",
    });
    // try engine.send("candlesticks", CandlesticksMessage{ .candlestick = .{ .open = 1.0, .high = 2.0, .low = 3.0, .close = 4.0 } });
    try candlestick_receiver.send(CanclestickReveiverMessage{ .candlestick = .{ .open = 1.0, .high = 2.0, .low = 3.0, .close = 4.0 } });

    const candlestick_sender = try engine.spawnActor(CandlestickSender, CandlestickSenderMessage, .{
        .id = "candlestick_sender",
    });
    try candlestick_sender.send(CandlestickSenderMessage{ .start_sending = .{} });
    // candlestick_receiver.deinit();
    // candlesticks_actor.send(.{ .candlestick = .{ .open = 1.0, .high = 2.0, .low = 3.0, .close = 4.0 } });
    // candlesticks_actor.start_receiving();
    // var chan = try Channel.init(i32, 0);
    // defer chan.deinit();
    // try chan.retain();

    // var new_ctx = Context.init(null);
    // Coroutine.spawn(&new_ctx, testSender, .{ .chan = chan });
    // Coroutine.spawn(&new_ctx, testReceiver, .{ .chan = chan });
    // Coroutine.spawn(&new_ctx, testReceiver, .{ .chan = chan });
}

// pub fn testReceiver(_: *Context, args: struct { chan: Channel }) !void {
//     while (true) {
//         var value: i32 = undefined;
//         try args.chan.receive(&value);
//         std.debug.print("Received: {}\n", .{value});
//     }
// }
// pub fn testSender(_: *Context, args: struct { chan: Channel }) !void {
//     _ = args.chan;

//     var value: i32 = 1;
//     while (true) {
//         std.time.sleep(1000000000);
//         value += 1;
//         _ = try args.chan.broadcast(value);
//         std.debug.print("Sent: {}\n", .{value});
//     }
// }

// This is an example of a message that can be sent to the CandlesticksActor.
pub const CanclestickReveiverMessage = union(enum) {
    candlestick: Candlestick,
};

pub const Candlestick = struct {
    open: f64,
    high: f64,
    low: f64,
    close: f64,
};

pub const CandlestickReceiver = struct {
    candlesticks: std.ArrayList(Candlestick),

    pub fn init(arena: *std.heap.ArenaAllocator) !*@This() {
        const allocator = arena.allocator();
        const self = try allocator.create(@This());
        self.* = .{
            .candlesticks = std.ArrayList(Candlestick).init(allocator),
        };
        return self;
    }

    pub fn receive(_: *@This(), message: *const CanclestickReveiverMessage) void {
        switch (message.*) {
            .candlestick => |candlestick| {
                std.debug.print("Received Candlestick:\n  open: {}\n  high: {}\n  low: {}\n  close: {}\n", .{ candlestick.open, candlestick.high, candlestick.low, candlestick.close });
            },
        }
    }
};

pub const CandlestickSenderMessage = union(enum) {
    start_sending: struct {},
};

pub const CandlestickSender = struct {
    
    pub fn init(arena: *std.heap.ArenaAllocator) !*@This() {
        const allocator = arena.allocator();
        const self = try allocator.create(@This());
        return self;
    }

    pub fn receive(_: *@This(), message: *const CandlestickSenderMessage) void {
        switch (message.*) {
            .start_sending => {
                std.debug.print("Received StartSendingMessage\n", .{});
            },
        }
    }
};
