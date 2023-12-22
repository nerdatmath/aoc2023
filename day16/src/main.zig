const std = @import("std");
const expect = @import("std").testing.expect;

const test_input_str =
    \\.|...\....
    \\|.-.\.....
    \\.....|-...
    \\........|.
    \\..........
    \\.........\
    \\..../.\\..
    \\.-.-/..|..
    \\.|....-|.\
    \\..//.|....
;

const test_input = Map{
    .size = 10,
    .tiles = [0]u8{} ++
        [_]u8{ '.', '|', '.', '.', '.', '\\', '.', '.', '.', '.' } ++ [_]u8{'.'} ** (maxSize - 10) ++
        [_]u8{ '|', '.', '-', '.', '\\', '.', '.', '.', '.', '.' } ++ [_]u8{'.'} ** (maxSize - 10) ++
        [_]u8{ '.', '.', '.', '.', '.', '|', '-', '.', '.', '.' } ++ [_]u8{'.'} ** (maxSize - 10) ++
        [_]u8{ '.', '.', '.', '.', '.', '.', '.', '.', '|', '.' } ++ [_]u8{'.'} ** (maxSize - 10) ++
        [_]u8{ '.', '.', '.', '.', '.', '.', '.', '.', '.', '.' } ++ [_]u8{'.'} ** (maxSize - 10) ++
        [_]u8{ '.', '.', '.', '.', '.', '.', '.', '.', '.', '\\' } ++ [_]u8{'.'} ** (maxSize - 10) ++
        [_]u8{ '.', '.', '.', '.', '/', '.', '\\', '\\', '.', '.' } ++ [_]u8{'.'} ** (maxSize - 10) ++
        [_]u8{ '.', '-', '.', '-', '/', '.', '.', '|', '.', '.' } ++ [_]u8{'.'} ** (maxSize - 10) ++
        [_]u8{ '.', '|', '.', '.', '.', '.', '-', '|', '.', '\\' } ++ [_]u8{'.'} ** (maxSize - 10) ++
        [_]u8{ '.', '.', '/', '/', '.', '|', '.', '.', '.', '.' } ++ [_]u8{'.'} ** (maxSize - 10) ++
        [_]u8{'.'} ** (maxSize * (maxSize - 10)),
};

const Dir = enum {
    up,
    dn,
    lt,
    rt,
};

const Pos = struct {
    const Self = @This();
    x: usize,
    y: usize,
    fn index(self: Self) usize {
        return @as(usize, self.y) * maxSize + self.x;
    }
    fn step(self: Self, dir: Dir) ?Self {
        return switch (dir) {
            .up => if (self.y > 0) .{ .x = self.x, .y = self.y - 1 } else null,
            .dn => if (self.y < maxSize - 1) .{ .x = self.x, .y = self.y + 1 } else null,
            .lt => if (self.x > 0) .{ .x = self.x - 1, .y = self.y } else null,
            .rt => if (self.x < maxSize - 1) .{ .x = self.x + 1, .y = self.y } else null,
        };
    }
};

const maxSize = 120;

const Map = struct {
    const Self = @This();
    size: usize,
    tiles: [maxSize * maxSize]u8,
    fn at(self: Self, pos: Pos) ?u8 {
        if (pos.x >= self.size or pos.y >= self.size) return null;
        return self.tiles[pos.index()];
    }
};

fn parse(input: []const u8) !Map {
    var map = Map{ .size = 0, .tiles = [_]u8{'.'} ** (maxSize * maxSize) };
    var it = std.mem.splitScalar(u8, input, '\n');
    var pos = Pos{ .x = 0, .y = 0 };
    while (it.next()) |line| : (pos.y += 1) {
        map.size = line.len;
        pos.x = 0;
        for (line) |ch| {
            map.tiles[pos.index()] = ch;
            pos.x += 1;
        }
    }
    return map;
}

test "parse" {
    try std.testing.expectEqualDeep(test_input, try parse(test_input_str));
}

fn run(startPos: Pos, startDir: Dir, map: Map) !usize {
    const State = struct { pos: Pos, dir: Dir };
    var states = try std.BoundedArray(State, 1000).init(0);
    try states.append(State{ .pos = startPos, .dir = startDir });
    const SeenBitSet = std.StaticBitSet(maxSize * maxSize);
    var seen = std.EnumArray(Dir, SeenBitSet).initFill(SeenBitSet.initEmpty());
    while (states.popOrNull()) |st| {
        if (map.at(st.pos)) |ch| {
            {
                const bitPos = st.pos.index();
                var seenBS = seen.getPtr(st.dir);
                if (seenBS.isSet(bitPos)) continue;
                seenBS.set(bitPos);
            }
            const nextDirections: []const Dir = switch (ch) {
                '.' => &.{st.dir},
                '/' => switch (st.dir) {
                    .up => &.{.rt},
                    .dn => &.{.lt},
                    .lt => &.{.dn},
                    .rt => &.{.up},
                },
                '\\' => switch (st.dir) {
                    .up => &.{.lt},
                    .dn => &.{.rt},
                    .lt => &.{.up},
                    .rt => &.{.dn},
                },
                '|' => &.{ .up, .dn },
                '-' => &.{ .lt, .rt },
                else => return error.UnexpectedTile,
            };
            for (nextDirections) |dir|
                if (st.pos.step(dir)) |pos|
                    try states.append(State{ .pos = pos, .dir = dir });
        }
    }
    var totalSeen = SeenBitSet.initEmpty();
    for (std.enums.values(Dir)) |dir| {
        totalSeen.setUnion(seen.get(dir));
    }
    return totalSeen.count();
}

fn part1(map: Map) !usize {
    return try run(.{ .x = 0, .y = 0 }, .rt, map);
}

test "part1" {
    try expect(try part1(test_input) == 46);
}

fn part2(map: Map) !u64 {
    var max: usize = 0;
    for (0..map.size) |i| {
        max = @max(max, try run(.{ .x = 0, .y = i }, .rt, map));
        max = @max(max, try run(.{ .x = map.size - 1, .y = i }, .lt, map));
        max = @max(max, try run(.{ .x = i, .y = 0 }, .dn, map));
        max = @max(max, try run(.{ .x = i, .y = map.size - 1 }, .up, map));
    }
    return max;
}

test "part2" {
    try expect(try part2(test_input) == 51);
}

var buffer: [1 << 24]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
const allocator = fba.allocator();
pub fn main() !void {
    var input_string = init: {
        const file = try std.fs.cwd().openFile("input.txt", .{});
        defer file.close();
        break :init try file.readToEndAlloc(allocator, 1 << 16);
    };
    const input = try parse(input_string);
    std.debug.print("{d}\n", .{try part1(input)});
    std.debug.print("{d}\n", .{try part2(input)});
}
