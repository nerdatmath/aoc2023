const std = @import("std");
const expect = @import("std").testing.expect;

const Matcher: type = *const fn ([]const u8) ?u8;

fn matchDigit(buffer: []const u8) ?u8 {
    if (buffer.len < 1) {
        return null;
    }
    const ch = buffer[0];
    if ('0' <= ch and ch <= '9') {
        return ch - '0';
    }
    return null;
}

fn firstMatch(buffer: []const u8, match: Matcher) ?u8 {
    var pos: usize = 0;
    while (pos < buffer.len) : (pos += 1) {
        if (match(buffer[pos..])) |value| {
            return value;
        }
    }
    return null;
}

fn lastMatch(buffer: []const u8, match: Matcher) ?u8 {
    var pos: usize = 0;
    while (pos < buffer.len) : (pos += 1) {
        if (match(buffer[buffer.len - pos - 1 ..])) |value| {
            return value;
        }
    }
    return null;
}

fn digits(buffer: []const u8, match: Matcher) ?u8 {
    if (firstMatch(buffer, match)) |d1| {
        if (lastMatch(buffer, match)) |d2| {
            return d1 * 10 + d2;
        }
    }
    return null;
}

fn part1(input: []const u8) !void {
    var linesIter = std.mem.splitScalar(u8, input, '\n');
    var sum: u16 = 0;
    while (linesIter.next()) |line| {
        sum += digits(line, matchDigit) orelse return error.NoDigits;
    }
    std.debug.print("{d}\n", .{sum});
}

const WrittenDigit = struct {
    text: []const u8,
    value: u8,
    fn match(self: WrittenDigit, buffer: []const u8) ?u8 {
        if (std.mem.startsWith(u8, buffer, self.text)) {
            return self.value;
        }
        return null;
    }
};

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

fn matchWrittenDigit(buffer: []const u8) ?u8 {
    for (WrittenDigits) |writtenDigit| {
        if (writtenDigit.match(buffer)) |value| {
            return value;
        }
    }
    return null;
}

test "firstMatch, matchWrittenDigit" {
    try expect(firstMatch("blahsevenblah", matchWrittenDigit) == 7);
    try expect(firstMatch("blahtwonesevenblah", matchWrittenDigit) == 2);
    try expect(firstMatch("blahnothing", matchWrittenDigit) == null);
}

test "lastMatch, matchWrittenDigit" {
    try expect(lastMatch("blahsevenblah", matchWrittenDigit) == 7);
    try expect(lastMatch("blah6twoneblah", matchWrittenDigit) == 1);
    try expect(lastMatch("blahnothing", matchWrittenDigit) == null);
}

fn part2(input: []const u8) !void {
    var linesIter = std.mem.splitScalar(u8, input, '\n');
    var sum: u16 = 0;
    while (linesIter.next()) |line| {
        sum += digits(line, matchWrittenDigit) orelse return error.NoDigits;
    }
    std.debug.print("{d}\n", .{sum});
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var buffer: [1 << 16]u8 = undefined;
    const bytes_read = try file.readAll(&buffer);
    const input = buffer[0..bytes_read];
    try part1(input);
    try part2(input);
}
