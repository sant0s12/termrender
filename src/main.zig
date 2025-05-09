const std = @import("std");
const term = @import("term.zig");

const Drawable = @import("Drawable.zig");
const TermBuffer = @import("TermBuffer.zig");
const Player = @import("game_objects/Player.zig");
const Box = @import("game_objects/Box.zig");

const Vec2f = @import("math.zig").Vec2f;
const EPS = @import("math.zig").EPS;

const assert = @import("std").debug.assert;

const stdout = std.io.getStdOut().writer().any();
const stdin = std.io.getStdIn().reader();

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

        for (self.gameObjects.items) |*game_object| {
            // Move object logic here, add collissions
            const dir_vec = game_object.tick();

            var new_position = game_object.position().* + dir_vec;

            // Check for collisions with other objects
            for (self.gameObjects.items) |*other_object| {
                if (other_object == game_object) continue;

                const bbox1 = game_object.bbox().toWorld(game_object.position());
                const bbox2 = other_object.bbox().toWorld(other_object.position());

                if (bbox1.intersect(&bbox2)) |_| {
                    // Check horizontal exit
                    if (@abs(bbox1.top_left[0] - bbox2.top_left[0]) >
                        @abs(bbox1.bottom_right[0] - bbox2.bottom_right[0]))
                    {
                        new_position[0] = bbox2.top_left[0] - bbox1.toLocal(game_object.position()).bottom_right[0] - 1;
                        std.debug.print("Right\n", .{});
                    } else {
                        new_position[0] = bbox2.bottom_right[0] + 1;
                        std.debug.print("Left\n", .{});
                    }

                    // Check vertical exit
                    // if (@abs(intersection.top_left[1] - bbox2.top_left[1]) <
                    //     @abs(intersection.bottom_right[1] - bbox2.bottom_right[1]))
                    // {
                    //     new_position[1] = intersection.top_left[1] - game_object.bbox().top_left[1];
                    // } else {
                    //     new_position[1] = intersection.bottom_right[1];
                    // }

                }
            }

            // Check end of screen
            new_position = std.math.clamp(new_position, Vec2f{ 0, 0 }, Vec2f{ cols_f, rows_f } - game_object.bbox().bottom_right);

            // Set speed to 0 if colliding with something
            if (new_position[0] != game_object.position()[0] + dir_vec[0]) {
                game_object.speed()[0] = 0;
            }

            if (new_position[1] != game_object.position()[1] + dir_vec[1]) {
                game_object.speed()[1] = 0;
            }

            game_object.position().* = new_position;
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

    var player = Player.init(&buffer, Vec2f{ 0, 0 });
    var box = Box.init(&buffer, Vec2f{ 5, 5 }, 5, 5);

    try game_state.gameObjects.append(Drawable.init(&player));
    try game_state.gameObjects.append(Drawable.init(&box));

    var read_buff: [3]u8 = undefined;
    while (true) {
        // Read input
        if (try stdin.read(&read_buff) > 0) {
            switch (read_buff[0]) {
                'a' => player.speed[0] -= 0.5,
                's' => player.speed[1] += 0.5,
                'd' => player.speed[0] += 0.5,
                ' ' => player.speed[1] -= 0.5,
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
        for (game_state.gameObjects.items) |game_object| {
            game_object.draw();
        }

        std.time.sleep(10 * std.time.ns_per_ms);
    }

    try buffer.clearTerm();
}
