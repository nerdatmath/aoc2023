const std = @import("std");
const expect = @import("std").testing.expect;

fn part1() !void {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var buffer: [1 << 16]u8 = undefined;
    const bytes_read = try file.readAll(&buffer);
    const input = buffer[0..bytes_read];
    var linesIter = std.mem.splitScalar(u8, input, '\n');
    var sum: u16 = 0;
    while (linesIter.next()) |line| {
        const firstIndex = std.mem.indexOfAny(u8, line, "0123456789") orelse return error.NoDigits;
        const lastIndex = std.mem.lastIndexOfAny(u8, line, "0123456789").?;
        const n: u8 = (line[firstIndex] - '0') * 10 + (line[lastIndex] - '0');
        sum += n;
    }
    std.debug.print("{d}\n", .{sum});
}

const WrittenDigit = struct { text: []const u8, value: u8 };

const WrittenDigits = [_]WrittenDigit{
    .{ .text = "one", .value = 1 },
    .{ .text = "two", .value = 2 },
    .{ .text = "three", .value = 3 },
    .{ .text = "four", .value = 4 },
    .{ .text = "five", .value = 5 },
    .{ .text = "six", .value = 6 },
    .{ .text = "seven", .value = 7 },
    .{ .text = "eight", .value = 8 },
    .{ .text = "nine", .value = 9 },
    .{ .text = "0", .value = 0 },
    .{ .text = "1", .value = 1 },
    .{ .text = "2", .value = 2 },
    .{ .text = "3", .value = 3 },
    .{ .text = "4", .value = 4 },
    .{ .text = "5", .value = 5 },
    .{ .text = "6", .value = 6 },
    .{ .text = "7", .value = 7 },
    .{ .text = "8", .value = 8 },
    .{ .text = "9", .value = 9 },
};

fn firstDigit(line: []const u8) ?u8 {
    var idx: ?usize = null;
    var value: ?u8 = null;
    for (WrittenDigits) |writtenDigit| {
        if (std.mem.indexOf(u8, line, writtenDigit.text)) |i| {
            if (i <= (idx orelse i)) {
                idx = i;
                value = writtenDigit.value;
            }
        }
    }
    return value;
}

test "firstDigit" {
    try expect(firstDigit("blahsevenblah") == 7);
    try expect(firstDigit("blahtwonesevenblah") == 2);
    try expect(firstDigit("blahnothing") == null);
}

fn lastDigit(line: []const u8) ?u8 {
    var idx: ?usize = null;
    var value: ?u8 = null;
    for (WrittenDigits) |writtenDigit| {
        if (std.mem.lastIndexOf(u8, line, writtenDigit.text)) |i| {
            if (i >= (idx orelse i)) {
                idx = i;
                value = writtenDigit.value;
            }
        }
    }
    return value;
}

test "lastDigit" {
    try expect(lastDigit("blahsevenblah") == 7);
    try expect(lastDigit("blah6twoneblah") == 1);
    try expect(lastDigit("blahnothing") == null);
}

fn digits(line: []const u8) ?u8 {
    if (firstDigit(line)) |d1| {
        if (lastDigit(line)) |d2| {
            return d1 * 10 + d2;
        }
    }
    return null;
}

fn part2() !void {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var buffer: [1 << 16]u8 = undefined;
    const bytes_read = try file.readAll(&buffer);
    const input = buffer[0..bytes_read];
    var linesIter = std.mem.splitScalar(u8, input, '\n');
    var sum: u16 = 0;
    while (linesIter.next()) |line| {
        sum += digits(line) orelse return error.NoDigits;
    }
    std.debug.print("{d}\n", .{sum});
}

pub fn main() !void {
    try part1();
    try part2();
}
