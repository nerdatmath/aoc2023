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

const Int = u64;

const Input = struct {
    rows: []const Int,
    cols: []const Int,
};

const test_input = Input{
    .rows = &[_]Int{ 1, 1, 1, 0, 1, 1, 1, 0, 1, 2 },
    .cols = &[_]Int{ 2, 1, 0, 1, 1, 0, 1, 2, 0, 1 },
};

fn parse(input: []const u8) !Input {
    var rowsList = std.ArrayList(Int).init(allocator);
    var colsList = std.ArrayList(Int).init(allocator);
    var it = std.mem.splitScalar(u8, input, '\n');
    var j: usize = 0;
    while (it.next()) |line| : (j += 1) {
        try rowsList.append(0);
        for (line, 0..) |ch, i| {
            if (colsList.items.len == i) try colsList.append(0);
            if (ch == '#') {
                rowsList.items[j] += 1;
                colsList.items[i] += 1;
            }
        }
    }
    return Input{ .rows = try rowsList.toOwnedSlice(), .cols = try colsList.toOwnedSlice() };
}

test "parse" {
    try std.testing.expectEqualDeep(test_input, try parse(test_input_str));
}

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

fn sumOfDistances2d(input: Input, factor: Int) !Int {
    return sumOfDistances(input.cols, factor) + sumOfDistances(input.rows, factor);
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
