const std = @import("std");
const expect = @import("std").testing.expect;

const Set = struct {
    red: u8,
    green: u8,
    blue: u8,
};

pub fn parseSet(buffer: []const u8) !Set {
    var set = Set{ .red = 0, .green = 0, .blue = 0 };
    var iter = std.mem.splitSequence(u8, buffer, ", ");
    while (iter.next()) |entry| {
        const spaceIdx = std.mem.indexOfScalar(u8, entry, ' ') orelse return error.NoSpace;
        const count = try std.fmt.parseInt(u8, entry[0..spaceIdx], 10);
        const color = entry[spaceIdx + 1 ..];
        if (std.mem.eql(u8, color, "red")) {
            set.red += count;
        } else if (std.mem.eql(u8, color, "green")) {
            set.green += count;
        } else if (std.mem.eql(u8, color, "blue")) {
            set.blue += count;
        } else {
            std.debug.print("bad color {s}", .{color});
            return error.InvalidColor;
        }
    }
    return set;
}

const SetIterator = struct {
    source: std.mem.SplitIterator(u8, .sequence),
    fn next(self: *SetIterator) !?Set {
        if (self.source.next()) |buffer| {
            return try parseSet(buffer);
        }
        return null;
    }
};

fn parseSets(buffer: []const u8) SetIterator {
    return SetIterator{
        .source = std.mem.splitSequence(u8, buffer, "; "),
    };
}

const Game = struct {
    id: u16,
    setIterator: SetIterator,
};

fn parseGame(buffer: []const u8) !Game {
    if (!std.mem.startsWith(u8, buffer, "Game ")) {
        return error.WrongPrefix;
    }
    const colonPos = std.mem.indexOf(u8, buffer, ": ") orelse return error.MissingColon;
    return Game{
        .id = try std.fmt.parseInt(u16, buffer[5..colonPos], 10),
        .setIterator = parseSets(buffer[colonPos + 2 ..]),
    };
}

fn part1(input: []const u8) !void {
    var sum: u16 = 0;
    var linesIter = std.mem.splitScalar(u8, input, '\n');
    while (linesIter.next()) |line| {
        var game = try parseGame(line);
        if (while (try game.setIterator.next()) |set| {
            if (set.red > 12 or set.green > 13 or set.blue > 14) {
                break false;
            }
        } else true) {
            sum += game.id;
        }
    }
    std.debug.print("{d}\n", .{sum});
}

fn part2(input: []const u8) !void {
    var sum: u32 = 0;
    var linesIter = std.mem.splitScalar(u8, input, '\n');
    while (linesIter.next()) |line| {
        var game = try parseGame(line);
        var minSet = (try game.setIterator.next()) orelse return error.NoSets;
        while (try game.setIterator.next()) |set| {
            if (set.red > minSet.red) {
                minSet.red = set.red;
            }
            if (set.green > minSet.green) {
                minSet.green = set.green;
            }
            if (set.blue > minSet.blue) {
                minSet.blue = set.blue;
            }
        }
        const power: u16 = @as(u16, minSet.red) * @as(u16, minSet.green) * @as(u16, minSet.blue);
        sum += power;
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
