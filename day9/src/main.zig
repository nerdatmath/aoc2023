const std = @import("std");
const expect = @import("std").testing.expect;

const test_input_str =
    \\0 3 6 9 12 15
    \\1 3 6 10 15 21
    \\10 13 16 21 30 45
;

const test_input = &[_][]const int{
    &[_]int{ 0, 3, 6, 9, 12, 15 },
    &[_]int{ 1, 3, 6, 10, 15, 21 },
    &[_]int{ 10, 13, 16, 21, 30, 45 },
};

const int = i64;

fn parse(input: []const u8) ![]const []const int {
    var inputsList = std.ArrayList([]int).init(allocator);
    errdefer inputsList.deinit();
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var list = std.ArrayList(int).init(allocator);
        errdefer list.deinit();
        var words = std.mem.splitScalar(u8, line, ' ');
        while (words.next()) |word| {
            try list.append(try std.fmt.parseInt(int, word, 10));
        }
        try inputsList.append(try list.toOwnedSlice());
    }
    return try inputsList.toOwnedSlice();
}

test "parse" {
    try std.testing.expectEqualDeep(@as([]const []const int, test_input), try parse(test_input_str));
}

fn nextValue(values: []const int) !int {
    var diffs: []int = try allocator.alloc(int, values.len - 1);
    defer allocator.free(diffs);
    var allzero: bool = true;
    for (diffs, 0..) |*d, i| {
        d.* = values[i + 1] - values[i];
        if (d.* != 0) {
            allzero = false;
        }
    }
    // std.debug.print("diffs={d}\n", .{diffs});
    const step = if (allzero) 0 else try nextValue(diffs);
    // std.debug.print("step={d}\n", .{step});
    return values[values.len - 1] + step;
}

test "nextValue" {
    try expect(try nextValue(test_input[0]) == 18);
    try expect(try nextValue(test_input[1]) == 28);
    try expect(try nextValue(test_input[2]) == 68);
}

fn part1(nss: []const []const int) !int {
    var sum: int = 0;
    for (nss) |ns| {
        sum += try nextValue(ns);
    }
    return sum;
}

test "part1" {
    try expect(try part1(test_input) == 114);
}

fn previousValue(values: []const int) !int {
    var diffs: []int = try allocator.alloc(int, values.len - 1);
    defer allocator.free(diffs);
    var allzero: bool = true;
    for (diffs, 0..) |*d, i| {
        d.* = values[i + 1] - values[i];
        if (d.* != 0) {
            allzero = false;
        }
    }
    // std.debug.print("diffs={d}\n", .{diffs});
    const step = if (allzero) 0 else try previousValue(diffs);
    // std.debug.print("step={d}\n", .{step});
    return values[0] - step;
}

test "previousValue" {
    try expect(try previousValue(test_input[0]) == -3);
    try expect(try previousValue(test_input[1]) == 0);
    try expect(try previousValue(test_input[2]) == 5);
}

fn part2(nss: []const []const int) !int {
    var sum: int = 0;
    for (nss) |ns| {
        sum += try previousValue(ns);
    }
    return sum;
}

test "part2" {
    try expect(try part2(test_input) == 2);
}

var buffer: [1 << 20]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
const allocator = fba.allocator();
pub fn main() !void {
    var input = init: {
        const file = try std.fs.cwd().openFile("input.txt", .{});
        defer file.close();
        break :init try file.readToEndAlloc(allocator, 1 << 16);
    };
    var nss = try parse(input);
    std.debug.print("{d}\n", .{try part1(nss)});
    std.debug.print("{d}\n", .{try part2(nss)});
}
