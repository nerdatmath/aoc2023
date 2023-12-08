const std = @import("std");
const expect = @import("std").testing.expect;

fn parsePrefixedNumbers(allocator: std.mem.Allocator, prefix: []const u8, buffer: []const u8) ![]u64 {
    var list = std.ArrayList(u64).init(allocator);
    defer list.deinit();
    if (!std.mem.startsWith(u8, buffer, prefix)) {
        return error.BadParse;
    }
    var iter = std.mem.tokenizeScalar(u8, buffer[prefix.len..], ' ');
    while (iter.next()) |word| {
        const id = try std.fmt.parseInt(u64, word, 10);
        try list.append(id);
    }
    return list.toOwnedSlice();
}

const Puzzle = struct {
    // all slices are owned.
    times: []u64,
    distances: []u64,
};

fn parse(allocator: std.mem.Allocator, input: []const u8) !Puzzle {
    var groupsIter = std.mem.splitSequence(u8, input, "\n");
    return Puzzle{
        .times = try parsePrefixedNumbers(allocator, "Time: ", groupsIter.next() orelse return error.NoLines),
        .distances = try parsePrefixedNumbers(allocator, "Distance: ", groupsIter.next() orelse return error.NoLines),
    };
}

const test_input =
    \\Time:      7  15   30
    \\Distance:  9  40  200
;

test "parse" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const puzzle = try parse(allocator, test_input);
    try std.testing.expectEqualSlices(u64, &[_]u64{ 7, 15, 30 }, puzzle.times);
    try std.testing.expectEqualSlices(u64, &[_]u64{ 9, 40, 200 }, puzzle.distances);
}

fn parsePrefixedNumberIgnoreSpaces(allocator: std.mem.Allocator, prefix: []const u8, buffer: []const u8) !u64 {
    _ = allocator;
    if (!std.mem.startsWith(u8, buffer, prefix)) {
        return error.BadParse;
    }
    var buf: [16]u8 = undefined;
    const buflen = buffer.len - prefix.len - std.mem.replace(u8, buffer[prefix.len..], " ", "", &buf);
    return std.fmt.parseInt(u64, buf[0..buflen], 10);
}

const Puzzle2 = struct {
    time: u64,
    distance: u64,
};

fn parse2(allocator: std.mem.Allocator, input: []const u8) !Puzzle2 {
    var groupsIter = std.mem.splitSequence(u8, input, "\n");
    return Puzzle2{
        .time = try parsePrefixedNumberIgnoreSpaces(allocator, "Time: ", groupsIter.next() orelse return error.NoLines),
        .distance = try parsePrefixedNumberIgnoreSpaces(allocator, "Distance: ", groupsIter.next() orelse return error.NoLines),
    };
}

test "parse2" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const puzzle = try parse2(allocator, test_input);
    try expect(puzzle.time == 71530);
    try expect(puzzle.distance == 940200);
}

fn ceilSqrt(n: u64) u32 {
    return std.math.sqrt(n - 1) + 1;
}

test "ceilSqrt" {
    try expect(ceilSqrt(1) == 1);
    try expect(ceilSqrt(2) == 2);
    try expect(ceilSqrt(3) == 2);
    try expect(ceilSqrt(4) == 2);
    try expect(ceilSqrt(5) == 3);
    try expect(ceilSqrt(9) == 3);
    try expect(ceilSqrt(10) == 4);
}

fn raceWays(time: u64, distance: u64) u32 {
    const q = ceilSqrt(time * time - 4 * distance);
    return if (time % 2 == q % 2) q - 1 else q;
}

test "raceWays" {
    try expect(raceWays(7, 9) == 4);
    try expect(raceWays(15, 40) == 8);
    try expect(raceWays(30, 200) == 9);
    try expect(raceWays(71530, 940200) == 71503);
}

fn part1(allocator: std.mem.Allocator, input: []u8) !void {
    const puzzle = try parse(allocator, input);
    var product: u64 = 1;
    for (0..puzzle.times.len) |i| {
        product *= raceWays(puzzle.times[i], puzzle.distances[i]);
    }
    std.debug.print("{d}\n", .{product});
}

fn part2(allocator: std.mem.Allocator, input: []u8) !void {
    const puzzle = try parse2(allocator, input);
    std.debug.print("{d}\n", .{raceWays(puzzle.time, puzzle.distance)});
}

pub fn main() !void {
    var buffer: [1 << 20]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    var input = init: {
        const file = try std.fs.cwd().openFile("input.txt", .{});
        defer file.close();
        break :init try file.readToEndAlloc(allocator, 1 << 16);
    };
    try part1(allocator, input);
    try part2(allocator, input);
}
