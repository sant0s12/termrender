const std = @import("std");
const term = @import("term.zig");

const Drawable = @import("Drawable.zig");
const TermBuffer = @import("TermBuffer.zig");
const Player = @import("game_objects/Player.zig");
const Box = @import("game_objects/Box.zig");

const Vec2f = @import("math.zig").Vec2f;

const assert = @import("std").debug.assert;

const stdout = std.io.getStdOut().writer().any();
const stdin = std.io.getStdIn().reader();

const EPS = 0.0001;

const GameState = struct {
    allocator: std.mem.Allocator,
    buffer: *TermBuffer,
    gameObjects: std.ArrayList(Drawable),

    pub fn init(allocator: std.mem.Allocator, buffer: *TermBuffer) GameState {
        return GameState{ .allocator = allocator, .buffer = buffer, .gameObjects = std.ArrayList(Drawable).init(allocator) };
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
        const cols_f = @as(f32, @floatFromInt(self.buffer.cols));
        const rows_f = @as(f32, @floatFromInt(self.buffer.rows));

        for (self.gameObjects.items) |game_object| {

            // Move object logic here, add collissions
            const dir_vec = game_object.tick();

            // Check end of screen

            // Traveling down
            if (dir_vec[1] > EPS and game_object.position()[1] + dir_vec[1] >= rows_f) {
                game_object.speed()[1] = EPS;

                // Traveling up
            } else if (dir_vec[1] < EPS and game_object.position()[1] + dir_vec[1] <= EPS) {
                game_object.speed()[1] = EPS;

                // Traveling right
            } else if (dir_vec[0] > EPS and game_object.position()[0] + dir_vec[0] >= cols_f) {
                game_object.speed()[0] = EPS;

                // Traveling left
            } else if (dir_vec[0] < EPS and game_object.position()[0] + dir_vec[0] <= EPS) {
                game_object.speed()[0] = EPS;
            }

            game_object.position().* += dir_vec;
            game_object.position().* = std.math.clamp(game_object.position().*, Vec2f{0, 0}, Vec2f{cols_f, rows_f});
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

    var buffer: TermBuffer = try TermBuffer.init(&stdout);
    var game_state: GameState = GameState.init(allocator, &buffer);

    var player = Drawable.init(@constCast(&Player{ .termBuffer = &buffer }));
    // const box = Drawable.init(@constCast(&Box{ .termBuffer = &buffer, .x = 100, .y = 50 }));

    try game_state.gameObjects.append(player);
    // try game_state.gameObjects.append(box);

    var read_buff: [3]u8 = undefined;
    while (true) {
        // Read input
        if (try stdin.read(&read_buff) > 0) {
            switch (read_buff[0]) {
                'a' => player.speed()[0] -= 0.5,
                's' => player.speed()[1] += 0.5,
                'd' => player.speed()[0] += 0.5,
                'w' => player.speed()[1] -= 0.5,
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
        // box.draw();

        std.time.sleep(10 * std.time.ns_per_ms);
    }

    try buffer.clearTerm();
}
