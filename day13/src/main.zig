const std = @import("std");
const expect = @import("std").testing.expect;

const test_input_str =
    \\#.##..##.
    \\..#.##.#.
    \\##......#
    \\##......#
    \\..#.##.#.
    \\..##..##.
    \\#.#.##.#.
    \\
    \\#...##..#
    \\#....#..#
    \\..##..###
    \\#####.##.
    \\#####.##.
    \\..##..###
    \\#....#..#
;

const Pattern = struct {
    width: usize,
    data: []const u64,
};

const Input = []const Pattern;

const test_input = @as(Input, &[_]Pattern{
    .{
        .width = 9,
        .data = &[_]u64{
            0b101100110,
            0b001011010,
            0b110000001,
            0b110000001,
            0b001011010,
            0b001100110,
            0b101011010,
        },
    },
    .{
        .width = 9,
        .data = &[_]u64{
            0b100011001,
            0b100001001,
            0b001100111,
            0b111110110,
            0b111110110,
            0b001100111,
            0b100001001,
        },
    },
});

fn parsePattern(input: []const u8) !Pattern {
    var list = std.ArrayList(u64).init(allocator);
    errdefer list.deinit();
    var it = std.mem.splitScalar(u8, input, '\n');
    var width: ?usize = null;
    while (it.next()) |word| {
        if (width) |w| {
            if (word.len != w) return error.DifferentWidths;
        } else {
            width = word.len;
        }
        var data: u64 = 0;
        for (word) |ch| {
            const bit: u1 = switch (ch) {
                '#' => 1,
                '.' => 0,
                else => return error.InvalidCharacter,
            };
            data = data << 1 | bit;
        }
        try list.append(data);
    }
    if (width == null) return error.NoRows;
    return Pattern{
        .width = width.?,
        .data = try list.toOwnedSlice(),
    };
}

fn parse(input: []const u8) !Input {
    var list = std.ArrayList(Pattern).init(allocator);
    errdefer list.deinit();
    var it = std.mem.splitSequence(u8, input, "\n\n");
    while (it.next()) |pat| {
        try list.append(try parsePattern(pat));
    }
    return list.toOwnedSlice();
}

test "parse" {
    try std.testing.expectEqualDeep(test_input, try parse(test_input_str));
}

fn transpose(pat: Pattern) !Pattern {
    var list = try std.ArrayList(u64).initCapacity(allocator, pat.width);
    errdefer list.deinit();
    for (0..pat.width) |i| {
        var data: u64 = 0;
        for (pat.data) |d| {
            data = data << 1 | (1 & (d >> @intCast(pat.width - i - 1)));
        }
        list.appendAssumeCapacity(data);
    }
    return Pattern{
        .width = pat.data.len,
        .data = try list.toOwnedSlice(),
    };
}

test "transpose" {
    try std.testing.expectEqualDeep(
        Pattern{ .width = 4, .data = &[_]u64{ 0b1001, 0b1110, 0b0001 } },
        try transpose(Pattern{ .width = 3, .data = &[_]u64{ 0b110, 0b010, 0b010, 0b101 } }),
    );
}

fn findMirror(pat: Pattern, smudges: u64) ?usize {
    for (1..pat.data.len) |m| {
        var n: u64 = 0;
        for (0..@min(m, pat.data.len - m)) |i| {
            const diff = pat.data[m - i - 1] ^ pat.data[m + i];
            n += @popCount(diff);
            if (n > smudges) break;
        }
        if (n == smudges) return m;
    } else return null;
}

test "findMirror" {
    try expect(findMirror(try transpose(test_input[0]), 0) == 5);
    try expect(findMirror(test_input[1], 0) == 4);
    try expect(findMirror(test_input[0], 1) == 3);
    try expect(findMirror(test_input[1], 1) == 1);
}

fn mirrorScore(input: Input, smudges: u64) !u64 {
    var sum: u64 = 0;
    for (input, 1..) |pat, i| {
        _ = i;
        if (findMirror(try transpose(pat), smudges)) |n| {
            sum += n;
        }
        if (findMirror(pat, smudges)) |n| {
            sum += n * 100;
        }
    }
    return sum;
}

fn part1(input: Input) !u64 {
    return mirrorScore(input, 0);
}

test "part1" {
    try expect(try part1(test_input) == 405);
}

fn part2(input: Input) !u64 {
    return mirrorScore(input, 1);
}

test "part2" {
    try expect(try part2(test_input) == 400);
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
