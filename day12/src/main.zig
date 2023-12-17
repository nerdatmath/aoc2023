const std = @import("std");
const expect = @import("std").testing.expect;

const test_input_str =
    \\???.### 1,1,3
    \\.??..??...?##. 1,1,3
    \\?#?#?#?#?#?#?#? 1,3,1,6
    \\????.#...#... 4,1,1
    \\????.######..#####. 1,6,5
    \\?###???????? 3,2,1
;

const Int = u64;

const Bits = std.bit_set.IntegerBitSet(64);

const InputRow = struct {
    pattern: []const u8,
    target: []const u16,
};

fn parseRow(input: []const u8) !InputRow {
    const pos = std.mem.indexOfScalar(u8, input, ' ') orelse return error.NoSpace;
    var targetList = std.ArrayList(u16).init(allocator);
    var it = std.mem.splitScalar(u8, input[pos + 1 ..], ',');
    while (it.next()) |word| {
        try targetList.append(try std.fmt.parseInt(u16, word, 10));
    }
    return InputRow{
        .pattern = input[0..pos],
        .target = try targetList.toOwnedSlice(),
    };
}

const Input = []InputRow;

fn parse(input: []const u8) !Input {
    var list = std.ArrayList(InputRow).init(allocator);
    var it = std.mem.splitScalar(u8, input, '\n');
    while (it.next()) |row| {
        try list.append(try parseRow(row));
    }
    return list.toOwnedSlice();
}

fn skipDamaged(in: []const u8, c: u16) ?[]const u8 {
    if (in.len < c) return null;
    for (0..c) |i| {
        if (in[i] == '.') return null;
    }
    if (in.len == c) return "";
    if (in[c] == '#') return null;
    return in[c + 1 ..];
}

const InputRowContext = struct {
    pub fn hash(self: @This(), row: InputRow) u64 {
        _ = self;
        var hasher = std.hash.Wyhash.init(0);
        std.hash.autoHashStrat(&hasher, row, std.hash.Strategy.DeepRecursive);
        return hasher.final();
    }
    pub fn eql(self: @This(), a: InputRow, b: InputRow) bool {
        _ = self;
        return std.mem.eql(u8, a.pattern, b.pattern) and std.mem.eql(u16, a.target, b.target);
    }
};

const ArrangementsHash = std.HashMap(InputRow, u64, InputRowContext, std.hash_map.default_max_load_percentage);

fn arrangements(memo: *ArrangementsHash, in: []const u8, targets: []const u16) u64 {
    if (in.len == 0 and targets.len == 0) return 1;
    if (memo.get(InputRow{ .pattern = in, .target = targets })) |result| {
        return result;
    }
    var count: u64 = 0;
    defer memo.put(InputRow{ .pattern = in, .target = targets }, count) catch {
        @panic("out of mem");
    };
    if (in.len > 0 and in[0] != '#') {
        count += arrangements(memo, in[1..], targets);
    }
    if (targets.len > 0) {
        if (skipDamaged(in, targets[0])) |next| {
            count += arrangements(memo, next, targets[1..]);
        }
    }
    // std.debug.print("arrangements(\"{s}\", {d}) = {d}\n", .{ in, targets, count });
    return count;
}

test "arrangements" {
    var memo = ArrangementsHash.init(std.testing.allocator);
    defer memo.deinit();
    try expect(arrangements(&memo, "???.###", &[_]u16{ 1, 1, 3 }) == 1);
    try expect(arrangements(&memo, ".??..??...?##.", &[_]u16{ 1, 1, 3 }) == 4);
    try expect(arrangements(&memo, "?#?#?#?#?#?#?#?", &[_]u16{ 1, 3, 1, 6 }) == 1);
    try expect(arrangements(&memo, "????.#...#...", &[_]u16{ 4, 1, 1 }) == 1);
    try expect(arrangements(&memo, "????.######..#####.", &[_]u16{ 1, 6, 5 }) == 4);
    try expect(arrangements(&memo, "?###????????", &[_]u16{ 3, 2, 1 }) == 10);
}

fn arrangements2(memo: *ArrangementsHash, in: []const u8, targets: []const u16) u64 {
    const result = arrangements(memo, unfoldPattern(in), unfoldTargets(targets));
    std.debug.print("arrangements2(\"{s}\", {d}) = {d}\n", .{ in, targets, result });
    return result;
}

test "arrangements2" {
    var memo = ArrangementsHash.init(std.testing.allocator);
    defer memo.deinit();
    try expect(arrangements2(&memo, "???.###", &[_]u16{ 1, 1, 3 }) == 1);
    try expect(arrangements2(&memo, ".??..??...?##.", &[_]u16{ 1, 1, 3 }) == 16384);
    try expect(arrangements2(&memo, "?#?#?#?#?#?#?#?", &[_]u16{ 1, 3, 1, 6 }) == 1);
    try expect(arrangements2(&memo, "????.#...#...", &[_]u16{ 4, 1, 1 }) == 16);
    try expect(arrangements2(&memo, "????.######..#####.", &[_]u16{ 1, 6, 5 }) == 2500);
    try expect(arrangements2(&memo, "?###????????", &[_]u16{ 3, 2, 1 }) == 506250);
}

fn part1(input: Input) !Int {
    var memo = ArrangementsHash.init(allocator);
    defer memo.deinit();
    var sum: u64 = 0;
    for (input) |row| {
        memo.clearRetainingCapacity();
        sum += arrangements(&memo, row.pattern, row.target);
    }
    return sum;
}

test "part1" {
    try expect(try part1(try parse(test_input_str)) == 21);
}

fn unfoldPattern(pat: []const u8) []const u8 {
    return std.mem.join(allocator, "?", &[_][]const u8{ pat, pat, pat, pat, pat }) catch unreachable;
}

fn unfoldTargets(targets: []const u16) []const u16 {
    return std.mem.concat(allocator, u16, &[_][]const u16{ targets, targets, targets, targets, targets }) catch unreachable;
}

fn part2(input: Input) !Int {
    var memo = ArrangementsHash.init(allocator);
    defer memo.deinit();
    var sum: u64 = 0;
    for (input) |row| {
        memo.clearRetainingCapacity();
        sum += arrangements2(&memo, row.pattern, row.target);
    }
    return sum;
}

test "part2" {
    try expect(try part2(try parse(test_input_str)) == 525152);
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
