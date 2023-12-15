const std = @import("std");
const expect = @import("std").testing.expect;

const test_input_str =
    \\7-F7-
    \\.FJ|7
    \\SJLL7
    \\|F--J
    \\LJ.LJ
;

const test_input = &[_][]const u8{
    "7-F7-",
    ".FJ|7",
    "SJLL7",
    "|F--J",
    "LJ.LJ",
};

fn parse(input: []const u8) ![]const []const u8 {
    var list = std.ArrayList([]const u8).init(allocator);
    errdefer list.deinit();
    var it = std.mem.splitScalar(u8, input, '\n');
    while (it.next()) |line| {
        try list.append(line);
    }
    return try list.toOwnedSlice();
}

test "parse" {
    try std.testing.expectEqualDeep(@as([]const []const u8, test_input), try parse(test_input_str));
}

const Dir = enum {
    Left,
    Right,
    Up,
    Down,
};

const Pos = struct { x: i16, y: i16 };

fn next(pos: Pos, dir: Dir) Pos {
    return switch (dir) {
        .Left => Pos{ .x = pos.x - 1, .y = pos.y },
        .Right => Pos{ .x = pos.x + 1, .y = pos.y },
        .Up => Pos{ .x = pos.x, .y = pos.y - 1 },
        .Down => Pos{ .x = pos.x, .y = pos.y + 1 },
    };
}

fn at(pos: Pos, input: []const []const u8) !u8 {
    if (pos.y < 0 or pos.y >= input.len) return error.OutOfRange;
    const y: usize = @intCast(pos.y);
    if (pos.x < 0 or pos.x >= input[y].len) return error.OutOfRange;
    const x: usize = @intCast(pos.x);
    return input[y][x];
}

fn nextDir(dir: Dir, ch: u8) ?Dir {
    return switch (dir) {
        .Left => switch (ch) {
            'L' => .Up,
            '-' => .Left,
            'F' => .Down,
            else => null,
        },
        .Right => switch (ch) {
            'J' => .Up,
            '-' => .Right,
            '7' => .Down,
            else => null,
        },
        .Up => switch (ch) {
            '7' => .Left,
            '|' => .Up,
            'F' => .Right,
            else => null,
        },
        .Down => switch (ch) {
            'J' => .Left,
            '|' => .Down,
            'L' => .Right,
            else => null,
        },
    };
}

fn valid(pos: Pos, dir: Dir, input: []const []const u8) bool {
    const ch = at(next(pos, dir), input) catch return false;
    return nextDir(dir, ch) != null;
}

fn visit(comptime T: type, input: []const []const u8, f: fn (T, Pos, Dir, u8) void, x: T) !void {
    var pos = for (input, 0..) |line, j| {
        if (std.mem.indexOfScalar(u8, line, 'S')) |i| {
            break Pos{ .x = @intCast(i), .y = @intCast(j) };
        }
    } else return error.StartNotFound;
    var dir: Dir = undefined;
    if (valid(pos, .Left, input)) {
        dir = .Left;
    } else if (valid(pos, .Right, input)) {
        dir = .Right;
    } else if (valid(pos, .Up, input)) {
        dir = .Up;
    } else if (valid(pos, .Down, input)) {
        dir = .Down;
    } else {
        return error.NowhereToGo;
    }
    const startingDir = dir;
    f(x, pos, dir, 'S');
    pos = next(pos, dir);
    var ch = try at(pos, input);
    while (ch != 'S') {
        dir = nextDir(dir, ch) orelse return error.Unconnected;
        f(x, pos, dir, ch);
        pos = next(pos, dir);
        ch = try at(pos, input);
    }
    f(x, pos, startingDir, ch);
}

fn inc(x: *usize, pos: Pos, dir: Dir, ch: u8) void {
    _ = ch;
    _ = dir;
    _ = pos;
    x.* += 1;
}

fn length(input: []const []const u8) !usize {
    var l: usize = 0;
    try visit(*usize, input, inc, &l);
    return l - 1;
}

test "length" {
    try expect(try length(test_input) == 16);
}

fn part1(input: []const []const u8) !usize {
    return (try length(input) + 1) / 2;
}

test "part1" {
    try expect(try part1(test_input) == 8);
}

const test_input_str2 =
    \\FF7FSF7F7F7F7F7F---7
    \\L|LJ||||||||||||F--J
    \\FL-7LJLJ||||||LJL-77
    \\F--JF--7||LJLJ7F7FJ-
    \\L---JF-JLJ.||-FJLJJ7
    \\|F|F-JF---7F7-L7L|7|
    \\|FFJF7L7F-JF7|JL---7
    \\7-L-JL7||F7|L7F-7F7|
    \\L.L7LFJ|||||FJL7||LJ
    \\L7JLJL-JLJLJL--JLJ.L
;

const Part2State = struct {
    area: i16,
    length: usize,
    rightTurns: i16,
    prevDir: ?Dir,
};

fn part2Update(st: *Part2State, pos: Pos, dir: Dir, ch: u8) void {
    _ = ch;
    if (st.prevDir) |prevDir| {
        const nextPos = next(pos, dir);
        st.area += pos.x * nextPos.y - nextPos.x * pos.y; // shoelace algorithm
        st.length += 1;
        st.rightTurns += switch (prevDir) {
            .Left => switch (dir) {
                .Left => 0,
                .Right => unreachable,
                .Up => 1,
                .Down => -1,
            },
            .Right => switch (dir) {
                .Left => unreachable,
                .Right => 0,
                .Up => -1,
                .Down => 1,
            },
            .Up => switch (dir) {
                .Left => -1,
                .Right => 1,
                .Up => 0,
                .Down => unreachable,
            },
            .Down => switch (dir) {
                .Left => 1,
                .Right => -1,
                .Up => unreachable,
                .Down => 0,
            },
        };
    }
    st.prevDir = dir;
}

fn part2(input: []const []const u8) !i16 {
    var st = Part2State{
        .area = 0,
        .length = 0,
        .rightTurns = 0,
        .prevDir = null,
    };
    try visit(*Part2State, input, part2Update, &st);
    var area = st.area + @divTrunc(st.rightTurns, 2);
    if (area < 0) area = -area;
    area -= @intCast(st.length);
    area = @divTrunc(area, 2);
    return area;
}

test "part2" {
    const input = try parse(test_input_str2);
    try expect(try part2(input) == 10);
}

var buffer: [1 << 20]u8 = undefined;
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
