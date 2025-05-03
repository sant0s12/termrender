const std = @import("std");
const term = @import("term.zig");

const Drawable = @import("Drawable.zig");
const TermBuffer = @import("TermBuffer.zig");
const Player = @import("game_objects/Player.zig");

const assert = @import("std").debug.assert;

const stdout = std.io.getStdOut().writer().any();
const stdin = std.io.getStdIn().reader();

const GameState = struct {
    allocator: std.mem.Allocator,
    gameObjects: std.ArrayList(Drawable),

    pub fn init(allocator: std.mem.Allocator) GameState {
        return GameState{ .allocator = allocator, .gameObjects = std.ArrayList(Drawable).init(allocator) };
    }

    pub fn getObjectAt(self: *GameState, x: f32, y: f32) ?Drawable {
        for (self.gameObjects.items) |game_object| {
            if (game_object.intrsect(x, y)) {
                return game_object;
            }
        }

        return null;
    }

    pub fn tick(self: *GameState) void {
         for (self.gameObjects.items) |game_object| {
             game_object.tick();
         }
    }
};

pub fn main() !void {
    term.uncookTerm();
    defer term.cookTerm();

    try term.hideCursor(&stdout);
    defer term.showCursor(&stdout) catch unreachable;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var game_state: GameState = GameState.init(allocator);

    var buffer: TermBuffer = try TermBuffer.init(&stdout);
    var player = Drawable.init(@constCast(&@as(Player, .{ .termBuffer = &buffer })));

    try game_state.gameObjects.append(player);

    var read_buff: [3]u8 = undefined;
    while (true) {
        // Read input
        if (try stdin.read(&read_buff) > 0) {
            switch (read_buff[0]) {
                'a' => player.speed()[0].* -= 0.5,
                's' => player.speed()[1].* += 0.5,
                'd' => player.speed()[0].* += 0.5,
                ' ' => player.speed()[1].* -= 1.5,
                'q' => break,
                else => {},
            }

            @memset(&read_buff, 0);
        }

        try buffer.updateSize();
        try buffer.clearTerm();

        //Tick
        game_state.tick();

        // Draw stuff
        player.draw();

        std.time.sleep(10 * std.time.ns_per_ms);
    }

    try buffer.clearTerm();
}
