const std = @import("std");
const expect = @import("std").testing.expect;

const test_input_str =
    \\...#......
    \\.......#..
    \\#.........
    \\..........
    \\......#...
    \\.#........
    \\.........#
    \\..........
    \\.......#..
    \\#...#.....
;

const Input = []const []const u8;

const test_input = @as(Input, &[_][]const u8{
    "...#......",
    ".......#..",
    "#.........",
    "..........",
    "......#...",
    ".#........",
    ".........#",
    "..........",
    ".......#..",
    "#...#.....",
});

fn parse(input: []const u8) !Input {
    var list = std.ArrayList([]const u8).init(allocator);
    errdefer list.deinit();
    var it = std.mem.splitScalar(u8, input, '\n');
    while (it.next()) |line| {
        try list.append(line);
    }
    return try list.toOwnedSlice();
}

test "parse" {
    try std.testing.expectEqualDeep(test_input, try parse(test_input_str));
}

const Int = u64;

fn sumOfDistances(input: []const Int, factor: Int) Int {
    var pos: Int = 0;
    var sum: Int = 0;
    var sumOfPos: Int = 0;
    var count: Int = 0;
    for (input) |c| {
        if (c == 0) pos += factor else pos += 1;
        for (0..c) |_| {
            sumOfPos += pos;
            sum += count * pos;
            count += 1;
        }
    }
    return sum * 2 - (sumOfPos * (count - 1));
}

test "sumOfDistances" {
    try expect(sumOfDistances(&[_]Int{ 2, 1, 0, 1 }, 2) == 13);
    try expect(sumOfDistances(&[_]Int{ 1, 0, 1, 2 }, 2) == 13);
}

fn columns(input: Input) ![]const Int {
    var out = try allocator.alloc(Int, input[0].len);
    for (out) |*x| {
        x.* = 0;
    }
    for (input) |row| {
        for (row, 0..) |ch, i| {
            if (ch == '#') out[i] += 1;
        }
    }
    return out;
}

test "columns" {
    try std.testing.expectEqualSlices(
        Int,
        &[_]Int{ 2, 1, 0, 1, 1, 0, 1, 2, 0, 1 },
        try columns(test_input),
    );
}

fn rows(input: Input) ![]const Int {
    var out = try allocator.alloc(Int, input.len);
    for (input, 0..) |row, i| {
        out[i] = 0;
        for (row) |ch| {
            if (ch == '#') out[i] += 1;
        }
    }
    return out;
}

test "rows" {
    try std.testing.expectEqualSlices(
        Int,
        &[_]Int{ 1, 1, 1, 0, 1, 1, 1, 0, 1, 2 },
        try rows(test_input),
    );
}

fn sumOfDistances2d(input: Input, factor: Int) !Int {
    return sumOfDistances(try columns(input), factor) + sumOfDistances(try rows(input), factor);
}

test "sumOfDistances2d" {
    try expect(try sumOfDistances2d(test_input, 2) == 374);
    try expect(try sumOfDistances2d(test_input, 10) == 1030);
    try expect(try sumOfDistances2d(test_input, 100) == 8410);
}

fn part1(input: Input) !Int {
    return sumOfDistances2d(input, 2);
}

fn part2(input: Input) !Int {
    return sumOfDistances2d(input, 1000000);
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
