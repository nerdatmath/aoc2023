const std = @import("std");
const expect = @import("std").testing.expect;

fn parseSeeds(allocator: std.mem.Allocator, buffer: []const u8) ![]u64 {
    var list = std.ArrayList(u64).init(allocator);
    defer list.deinit();
    if (!std.mem.startsWith(u8, buffer, "seeds: ")) {
        return error.BadParse;
    }
    var iter = std.mem.splitScalar(u8, buffer[7..], ' ');
    while (iter.next()) |word| {
        const id = try std.fmt.parseInt(u64, word, 10);
        try list.append(id);
    }
    return list.toOwnedSlice();
}

test "parseSeeds" {
    const seeds = try parseSeeds(std.testing.allocator, "seeds: 79 14 55 13");
    defer std.testing.allocator.free(seeds);
    try std.testing.expectEqualSlices(u64, &[_]u64{ 79, 14, 55, 13 }, seeds);
}

const MapEntry = struct {
    dest: u64,
    source: u64,
    len: u64,
};

fn parseMapEntry(buffer: []const u8) !MapEntry {
    var entry: MapEntry = undefined;
    var iter = std.mem.splitScalar(u8, buffer, ' ');
    entry.dest = try std.fmt.parseInt(u64, iter.next() orelse return error.TooFewWords, 10);
    entry.source = try std.fmt.parseInt(u64, iter.next() orelse return error.TooFewWords, 10);
    entry.len = try std.fmt.parseInt(u64, iter.next() orelse return error.TooFewWords, 10);
    if (iter.next() != null) {
        return error.TooManyWords;
    }
    return entry;
}

test "parseMapEntry" {
    try std.testing.expectEqual(parseMapEntry("50 98 2"), MapEntry{ .dest = 50, .source = 98, .len = 2 });
}

fn mapEntryLessThanFn(context: void, a: MapEntry, b: MapEntry) bool {
    _ = context;
    return a.source < b.source;
}

const Map = []const MapEntry;

fn parseMap(allocator: std.mem.Allocator, buffer: []const u8) !Map {
    var list = std.ArrayList(MapEntry).init(allocator);
    var iter = std.mem.splitScalar(u8, buffer, '\n');
    if (iter.next() == null) {
        return error.NoMapTitle;
    }
    while (iter.next()) |line| {
        try list.append(try parseMapEntry(line));
    }
    std.sort.insertion(MapEntry, list.items, {}, comptime mapEntryLessThanFn);
    return list.toOwnedSlice();
}

test "parseMap" {
    const map = try parseMap(std.testing.allocator, "seed-to-soil map:\n50 98 2\n52 50 48");
    defer std.testing.allocator.free(map);
    try std.testing.expectEqualSlices(MapEntry, &[_]MapEntry{
        .{ .dest = 52, .source = 50, .len = 48 },
        .{ .dest = 50, .source = 98, .len = 2 },
    }, map);
}

const Puzzle = struct {
    // all slices are owned.
    seeds: []u64,
    maps: []Map,
};

fn parse(allocator: std.mem.Allocator, input: []const u8) !Puzzle {
    var groupsIter = std.mem.splitSequence(u8, input, "\n\n");
    return Puzzle{
        .seeds = try parseSeeds(allocator, groupsIter.next() orelse return error.NoLines),
        .maps = try maps: {
            var list = std.ArrayList(Map).init(allocator);
            defer list.deinit();
            while (groupsIter.next()) |group| {
                try list.append(try parseMap(allocator, group));
            }
            break :maps list.toOwnedSlice();
        },
    };
}

const test_input =
    \\seeds: 79 14 55 13
    \\
    \\seed-to-soil map:
    \\50 98 2
    \\52 50 48
    \\
    \\soil-to-fertilizer map:
    \\0 15 37
    \\37 52 2
    \\39 0 15
    \\
    \\fertilizer-to-water map:
    \\49 53 8
    \\0 11 42
    \\42 0 7
    \\57 7 4
    \\
    \\water-to-light map:
    \\88 18 7
    \\18 25 70
    \\
    \\light-to-temperature map:
    \\45 77 23
    \\81 45 19
    \\68 64 13
    \\
    \\temperature-to-humidity map:
    \\0 69 1
    \\1 0 69
    \\
    \\humidity-to-location map:
    \\60 56 37
    \\56 93 4
;

test "parse" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const puzzle = try parse(allocator, test_input);
    try std.testing.expectEqualSlices(u64, &[_]u64{ 79, 14, 55, 13 }, puzzle.seeds);
    try std.testing.expectEqualSlices(MapEntry, &[_]MapEntry{
        .{ .dest = 52, .source = 50, .len = 48 },
        .{ .dest = 50, .source = 98, .len = 2 },
    }, puzzle.maps[0]);
}

fn translate(n: u64, map: Map) u64 {
    for (map) |entry| {
        if (entry.source <= n and n < entry.source + entry.len) {
            return n - entry.source + entry.dest;
        }
    }
    return n;
}

test "translate" {
    const map: Map = &[_]MapEntry{
        .{ .dest = 50, .source = 98, .len = 2 },
        .{ .dest = 52, .source = 50, .len = 48 },
    };
    try expect(translate(79, map) == 81);
    try expect(translate(14, map) == 14);
}

fn part1(seeds: []u64, maps: []Map) !void {
    var low: u64 = std.math.maxInt(u64);
    for (seeds) |n| {
        var v = n;
        for (maps) |map| {
            v = translate(v, map);
        }
        if (v < low) {
            low = v;
        }
    }
    std.debug.print("{d}\n", .{low});
}

fn lowest(rangeStart: u64, rangeLen: u64, maps: []Map) u64 {
    if (maps.len == 0) {
        return rangeStart;
    }
    var low: u64 = std.math.maxInt(u64);
    var start = rangeStart;
    var len = rangeLen;
    for (maps[0]) |entry| {
        const entries = [_]MapEntry{
            .{ .source = 0, .dest = 0, .len = entry.source },
            entry,
        };
        for (entries) |e| {
            const offset = start - e.source;
            if (offset >= e.len) {
                continue;
            }
            const step = @min(len, e.len - offset);
            low = @min(low, lowest(e.dest + offset, step, maps[1..]));
            len -= step;
            start += step;
            if (len == 0) {
                return low;
            }
        }
    }
    low = @min(low, lowest(start, len, maps[1..]));
    return low;
}

test "lowest" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const puzzle = try parse(allocator, test_input);
    const low = lowest(79, 14, puzzle.maps);
    try std.testing.expect(low == 46);
}

fn part2(seeds: []u64, maps: []Map) !void {
    var low: u64 = std.math.maxInt(u64);
    for (0..seeds.len / 2) |i| {
        low = @min(low, lowest(seeds[i * 2], seeds[i * 2 + 1], maps));
    }
    std.debug.print("{d}\n", .{low});
}

pub fn main() !void {
    var buffer: [1 << 20]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    var puzzle = init: {
        const file = try std.fs.cwd().openFile("input.txt", .{});
        defer file.close();
        const input = try file.readToEndAlloc(allocator, 1 << 16);
        break :init try parse(allocator, input);
    };
    try part1(puzzle.seeds, puzzle.maps);
    try part2(puzzle.seeds, puzzle.maps);
}
