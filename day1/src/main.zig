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

fn matchString(text: []const u8, value: u8, buffer: []const u8) ?u8 {
    if (std.mem.startsWith(u8, buffer, text)) {
        return value;
    }
    return null;
}

fn matchWrittenDigit(buffer: []const u8) ?u8 {
    return matchString("one", 1, buffer) orelse
        matchString("two", 2, buffer) orelse
        matchString("three", 3, buffer) orelse
        matchString("four", 4, buffer) orelse
        matchString("five", 5, buffer) orelse
        matchString("six", 6, buffer) orelse
        matchString("seven", 7, buffer) orelse
        matchString("eight", 8, buffer) orelse
        matchString("nine", 9, buffer);
}

fn matchAnyDigit(buffer: []const u8) ?u8 {
    return matchDigit(buffer) orelse matchWrittenDigit(buffer);
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
        sum += digits(line, matchAnyDigit) orelse return error.NoDigits;
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
