const std = @import("std");
const expect = @import("std").testing.expect;

const PartNumber = struct {
    number: u16,
    row: u8,
    col: u8,
    len: u8,
};

const Symbol = struct {
    char: u8,
    row: u8,
    col: u8,
};

fn isdigit(char: u8) bool {
    return '0' <= char and char <= '9';
}

fn issymbol(char: u8) bool {
    return !isdigit(char) and char != '.';
}

fn parseSchematic(partsList: *std.ArrayList(PartNumber), symbolsList: *std.ArrayList(Symbol), input: []const u8) !void {
    var linesIter = std.mem.splitScalar(u8, input, '\n');
    var row: u8 = 1;
    while (linesIter.next()) |line| : (row += 1) {
        var pn: ?PartNumber = null;
        for (line, 1..) |char, col| {
            if (isdigit(char)) {
                var partnumber = pn orelse PartNumber{ .number = 0, .row = row, .col = @intCast(col), .len = 0 };
                partnumber.number = partnumber.number * 10 + (char - '0');
                partnumber.len += 1;
                pn = partnumber;
                continue;
            }
            if (pn) |partnumber| {
                try partsList.append(partnumber);
                // std.debug.print("PartNumber {}\n", .{partnumber});
                pn = null;
            }
            if (issymbol(char)) {
                const symbol: Symbol = .{ .char = char, .row = row, .col = @intCast(col) };
                try symbolsList.append(symbol);
                // std.debug.print("Symbol {}\n", .{symbol});
            }
        }
        if (pn) |partnumber| {
            try partsList.append(partnumber);
            // std.debug.print("PartNumber {}\n", .{partnumber});
            pn = null;
        }
    }
}

fn adjacent(pn: PartNumber, s: Symbol) bool {
    if (pn.row + 1 < s.row or pn.row > s.row + 1) {
        return false;
    }
    return (pn.col <= s.col + 1 and pn.col + pn.len >= s.col);
}

test "adjacent" {
    try expect(adjacent(.{ .number = 467, .row = 1, .col = 1, .len = 3 }, .{ .row = 2, .col = 4 }));
}

fn part1(parts: []const PartNumber, symbols: []const Symbol) !void {
    var sum: u32 = 0;
    for (parts) |pn| {
        if (for (symbols) |s| {
            if (adjacent(pn, s)) {
                break true;
            }
        } else false) {
            sum += pn.number;
        }
    }
    std.debug.print("{d}\n", .{sum});
}

fn part2(parts: []const PartNumber, symbols: []const Symbol) !void {
    var sum: u32 = 0;
    for (symbols) |s| {
        if (s.char != '*') {
            continue;
        }
        var pn1opt: ?PartNumber = null;
        for (parts) |pn| {
            if (adjacent(pn, s)) {
                if (pn1opt) |pn1| {
                    // std.debug.print("gear {} {} {}\n", .{ s, pn1, pn });
                    const gearratio: u32 = @as(u32, pn1.number) * @as(u32, pn.number);
                    sum += gearratio;
                    break;
                }
                pn1opt = pn;
            }
        }
    }
    std.debug.print("{d}\n", .{sum});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var buffer: [1 << 16]u8 = undefined;
    const bytes_read = try file.readAll(&buffer);
    const input = buffer[0..bytes_read];
    var partsList = std.ArrayList(PartNumber).init(allocator);
    var symbolsList = std.ArrayList(Symbol).init(allocator);
    defer partsList.deinit();
    defer symbolsList.deinit();
    try parseSchematic(&partsList, &symbolsList, input);
    try part1(partsList.items, symbolsList.items);
    try part2(partsList.items, symbolsList.items);
}
