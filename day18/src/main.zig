const std = @import("std");
const expect = @import("std").testing.expect;

const test_input_str =
    \\R 6 (#70c710)
    \\D 5 (#0dc571)
    \\L 2 (#5713f0)
    \\D 2 (#d2c081)
    \\R 2 (#59c680)
    \\D 2 (#411b91)
    \\L 5 (#8ceee2)
    \\U 2 (#caa173)
    \\L 1 (#1b58a2)
    \\U 2 (#caa171)
    \\R 2 (#7807d2)
    \\U 3 (#a77fa3)
    \\L 2 (#015232)
    \\U 2 (#7a21e3)
;

const Dir = enum {
    Left,
    Right,
    Up,
    Down,
};

const Instruction = struct {
    const Self = @This();
    dir: Dir,
    dist: u32,

    fn parse(input: []const u8) !Self {
        if (input.len < 3 or input[1] != ' ') return error.InvalidInstruction;
        const dir: Dir = switch (input[0]) {
            'R' => .Right,
            'L' => .Left,
            'U' => .Up,
            'D' => .Down,
            else => return error.InvalidInstruction,
        };
        const p = std.mem.indexOfScalar(u8, input[2..], ' ') orelse return error.InvalidInstruction;
        const dist = try std.fmt.parseUnsigned(u32, input[2 .. p + 2], 10);
        return Self{
            .dir = dir,
            .dist = dist,
        };
    }

    fn fromHex(h: u24) !Instruction {
        const dist: u32 = h >> 4;
        const dir: Dir = switch (h & 0xF) {
            0 => .Right,
            2 => .Left,
            3 => .Up,
            1 => .Down,
            else => return error.InvalidInstruction,
        };
        return Instruction{ .dir = dir, .dist = dist };
    }
};

const test_input = &[_]Instruction{
    .{ .dir = .Right, .dist = 6 },
    .{ .dir = .Down, .dist = 5 },
    .{ .dir = .Left, .dist = 2 },
    .{ .dir = .Down, .dist = 2 },
    .{ .dir = .Right, .dist = 2 },
    .{ .dir = .Down, .dist = 2 },
    .{ .dir = .Left, .dist = 5 },
    .{ .dir = .Up, .dist = 2 },
    .{ .dir = .Left, .dist = 1 },
    .{ .dir = .Up, .dist = 2 },
    .{ .dir = .Right, .dist = 2 },
    .{ .dir = .Up, .dist = 3 },
    .{ .dir = .Left, .dist = 2 },
    .{ .dir = .Up, .dist = 2 },
};

fn parse(input: []const u8) ![]const Instruction {
    var list = std.ArrayList(Instruction).init(allocator);
    errdefer list.deinit();
    var it = std.mem.splitScalar(u8, input, '\n');
    while (it.next()) |line| {
        try list.append(try Instruction.parse(line));
    }
    return try list.toOwnedSlice();
}

test "parse" {
    try std.testing.expectEqualDeep(@as([]const Instruction, test_input), try parse(test_input_str));
}

const Pos = struct { x: i64, y: i64 };

fn next(pos: Pos, dir: Dir, dist: u32) Pos {
    return switch (dir) {
        .Left => Pos{ .x = pos.x - dist, .y = pos.y },
        .Right => Pos{ .x = pos.x + dist, .y = pos.y },
        .Up => Pos{ .x = pos.x, .y = pos.y - dist },
        .Down => Pos{ .x = pos.x, .y = pos.y + dist },
    };
}

fn area(input: []const Instruction) i64 {
    var pos: Pos = .{ .x = 0, .y = 0 };
    var a: i64 = 0;
    var length: i64 = 0;
    var rightTurns: i64 = 0;
    var prevDir = input[input.len - 1].dir;
    for (input) |inst| {
        const nextPos = next(pos, inst.dir, inst.dist);
        a += pos.x * nextPos.y - nextPos.x * pos.y; // shoelace algorithm
        length += inst.dist;
        rightTurns += switch (prevDir) {
            .Left => switch (inst.dir) {
                .Left => 0,
                .Right => unreachable,
                .Up => 1,
                .Down => -1,
            },
            .Right => switch (inst.dir) {
                .Left => unreachable,
                .Right => 0,
                .Up => -1,
                .Down => 1,
            },
            .Up => switch (inst.dir) {
                .Left => -1,
                .Right => 1,
                .Up => 0,
                .Down => unreachable,
            },
            .Down => switch (inst.dir) {
                .Left => 1,
                .Right => -1,
                .Up => unreachable,
                .Down => 0,
            },
        };
        pos = nextPos;
        prevDir = inst.dir;
    }
    // std.debug.print("rt={d}, l={d}, a={d}\n", .{ rightTurns, length, a });
    a += @divTrunc(rightTurns, 2);
    if (a < 0) a = -a;
    a += @intCast(length);
    a = @divTrunc(a, 2);
    return a;
}

test "area" {
    try expect(area(test_input) == 62);
}

fn part1(input: []const u8) !i64 {
    return area(try parse(input));
}

test "part1" {
    try expect(try part1(test_input_str) == 62);
}

const test_input2 = &[_]Instruction{
    .{ .dir = .Right, .dist = 461937 },
    .{ .dir = .Down, .dist = 56407 },
    .{ .dir = .Right, .dist = 356671 },
    .{ .dir = .Down, .dist = 863240 },
    .{ .dir = .Right, .dist = 367720 },
    .{ .dir = .Down, .dist = 266681 },
    .{ .dir = .Left, .dist = 577262 },
    .{ .dir = .Up, .dist = 829975 },
    .{ .dir = .Left, .dist = 112010 },
    .{ .dir = .Down, .dist = 829975 },
    .{ .dir = .Left, .dist = 491645 },
    .{ .dir = .Up, .dist = 686074 },
    .{ .dir = .Left, .dist = 5411 },
    .{ .dir = .Up, .dist = 500254 },
};

fn parse2(input: []const u8) ![]const Instruction {
    var list = std.ArrayList(Instruction).init(allocator);
    errdefer list.deinit();
    var it = std.mem.splitScalar(u8, input, '\n');
    while (it.next()) |line| {
        const h = try std.fmt.parseUnsigned(u24, line[line.len - 7 .. line.len - 1], 16);
        try list.append(try Instruction.fromHex(h));
    }
    return try list.toOwnedSlice();
}

test "parse2" {
    try std.testing.expectEqualDeep(@as([]const Instruction, test_input2), try parse2(test_input_str));
}

fn part2(input: []const u8) !i64 {
    return area(try parse2(input));
}

test "part2" {
    try expect(try part2(test_input_str) == 952408144115);
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
    std.debug.print("{d}\n", .{try part1(input_string)});
    std.debug.print("{d}\n", .{try part2(input_string)});
}
