const std = @import("std");
const expect = @import("std").testing.expect;

const test_input =
    \\O....#....
    \\O.OO#....#
    \\.....##...
    \\OO.#O....O
    \\.O.....O#.
    \\O.#..O.#.#
    \\..O..#O..O
    \\.......O..
    \\#....###..
    \\#OO..#....
;

const maxSize = 100;

const Col = std.StaticBitSet(maxSize);
const Field = [maxSize]Col;

const emptyField = [_]Col{Col.initEmpty()} ** maxSize;

const Board = struct {
    const Self = @This();
    size: usize,
    blocks: Field,
    rounds: Field,
    fn initEmpty(size: usize) Self {
        return .{
            .size = size,
            .blocks = emptyField,
            .rounds = emptyField,
        };
    }
    fn eql(self: Self, other: Self) bool {
        if (self.size != other.size) return false;
        for (0..self.size) |i| {
            if (!self.rounds[i].eql(other.rounds[i])) return false;
        }
        for (0..self.size) |i| {
            if (!self.blocks[i].eql(other.blocks[i])) return false;
        }
        return true;
    }
    fn roll(self: *Self) void {
        for (&self.rounds, 0..) |*r, i| {
            r.* = rollColumn(self.size, r.*, self.blocks[i]);
        }
    }
    fn rollColumn(size: usize, rounds: Col, blocks: Col) Col {
        var top: usize = 0;
        var out = Col.initEmpty();
        for (0..size) |i| {
            if (blocks.isSet(i)) {
                top = i + 1;
            } else if (rounds.isSet(i)) {
                out.set(top);
                top = top + 1;
            }
        }
        return out;
    }

    fn load(self: Self) u64 {
        var l: u64 = 0;
        for (self.rounds) |r| {
            var it = r.iterator(.{});
            while (it.next()) |i| {
                l += self.size - i;
            }
        }
        return l;
    }

    fn rotate(self: *Self) void {
        self.blocks = rotateField(self.size, self.blocks);
        self.rounds = rotateField(self.size, self.rounds);
    }

    fn rotateField(size: usize, f: Field) Field {
        var out = emptyField;
        for (0..size) |j| {
            var it = f[j].iterator(.{});
            while (it.next()) |i| {
                out[size - i - 1].set(j);
            }
        }
        return out;
    }

    fn spinCycle(self: *Self) void {
        // var writer = std.io.getStdErr().writer();
        for (0..4) |_| {
            self.roll();
            // self.print(writer) catch unreachable;
            // writer.writeByte('\n') catch unreachable;
            self.rotate();
            // self.print(writer) catch unreachable;
            // writer.writeByteNTimes('-', 10) catch unreachable;
            // writer.writeByte('\n') catch unreachable;
        }
    }

    fn print(self: Self, writer: anytype) !void {
        for (0..self.size) |j| {
            for (0..self.size) |i| {
                try writer.writeByte(if (self.rounds[i].isSet(j)) 'O' else if (self.blocks[i].isSet(j)) '#' else '.');
            }
            try writer.writeByte('\n');
        }
    }
};

fn parse(reader: anytype) !Board {
    var out = Board.initEmpty(0);
    var i: usize = 0;
    var j: usize = 0;
    while (reader.readByte()) |ch| {
        switch (ch) {
            '\n' => {
                out.size = i;
                j += 1;
                i = 0;
            },
            'O' => {
                out.rounds[i].set(j);
                i += 1;
            },
            '#' => {
                out.blocks[i].set(j);
                i += 1;
            },
            '.' => {
                i += 1;
            },
            else => return error.InvalidCharacter,
        }
    } else |err| {
        switch (err) {
            error.EndOfStream => {},
            else => return err,
        }
    }
    return out;
}

fn part1(reader: anytype) !u64 {
    var board = try parse(reader);
    board.roll();
    return board.load();
}

test "part1" {
    var fbs = std.io.fixedBufferStream(test_input);
    try expect(try part1(fbs.reader()) == 136);
}

fn allEqual(n: u64, ns: []const u64) bool {
    for (ns) |n1| {
        if (n1 != n) return false;
    } else return true;
}

fn repeats(n: usize, items: []const u64) usize {
    if (n > items.len)
        return 0;
    var count: usize = 0;
    const pat = items[items.len - n .. items.len];
    while ((count + 1) * n <= items.len) : (count += 1) {
        if (!std.mem.eql(u64, items[items.len - (count + 1) * n .. items.len - count * n], pat)) break;
    }
    return count;
}

fn part2(reader: anytype) !u64 {
    var board = try parse(reader);
    var loads = [_]u64{0} ** 10000;
    for (&loads, 1..) |*l, i| {
        board.spinCycle();
        l.* = board.load();
        for (1..200) |n| {
            if (repeats(n, loads[0..i]) > 20) {
                // std.debug.print("cycle found (length {d}): {d}\n", .{ n, loads[i - n .. i] });
                // assume we will continue in this cycle
                return loads[i - n + (1_000_000_000 - i - 1) % n];
            }
        }
    }
    return error.DidntSettle;
}

test "part2" {
    var fbs = std.io.fixedBufferStream(test_input);
    try expect(try part2(fbs.reader()) == 64);
}

var buffer: [1 << 24]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
const allocator = fba.allocator();
pub fn main() !void {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    std.debug.print("{d}\n", .{try part1(file.reader())});
    try file.seekTo(0);
    std.debug.print("{d}\n", .{try part2(file.reader())});
}
