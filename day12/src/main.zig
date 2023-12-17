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

const test_input = @as(Input, &[_]InputRow{
    .{ .pattern = "???.###", .target = &[_]u16{ 1, 1, 3 } },
    .{ .pattern = ".??..??...?##.", .target = &[_]u16{ 1, 1, 3 } },
    .{ .pattern = "?#?#?#?#?#?#?#?", .target = &[_]u16{ 1, 3, 1, 6 } },
    .{ .pattern = "????.#...#...", .target = &[_]u16{ 4, 1, 1 } },
    .{ .pattern = "????.######..#####.", .target = &[_]u16{ 1, 6, 5 } },
    .{ .pattern = "?###????????", .target = &[_]u16{ 3, 2, 1 } },
});

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

const Input = []const InputRow;

fn parse(input: []const u8) !Input {
    var list = std.ArrayList(InputRow).init(allocator);
    var it = std.mem.splitScalar(u8, input, '\n');
    while (it.next()) |row| {
        try list.append(try parseRow(row));
    }
    return list.toOwnedSlice();
}

test "parse" {
    try std.testing.expectEqualDeep(test_input, try parse(test_input_str));
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

fn arrangements(memo: *ArrangementsHash, row: InputRow) u64 {
    if (row.pattern.len == 0 and row.target.len == 0) return 1;
    if (memo.get(row)) |result| {
        return result;
    }
    var count: u64 = 0;
    defer memo.put(row, count) catch {
        @panic("out of mem");
    };
    if (row.pattern.len > 0 and row.pattern[0] != '#') {
        const newRow = InputRow{ .pattern = row.pattern[1..], .target = row.target };
        count += arrangements(memo, newRow);
    }
    if (row.target.len > 0) {
        if (skipDamaged(row.pattern, row.target[0])) |next| {
            const newRow = InputRow{ .pattern = next, .target = row.target[1..] };
            count += arrangements(memo, newRow);
        }
    }
    return count;
}

test "arrangements" {
    var memo = ArrangementsHash.init(std.testing.allocator);
    defer memo.deinit();
    try expect(arrangements(&memo, test_input[0]) == 1);
    try expect(arrangements(&memo, test_input[1]) == 4);
    try expect(arrangements(&memo, test_input[2]) == 1);
    try expect(arrangements(&memo, test_input[3]) == 1);
    try expect(arrangements(&memo, test_input[4]) == 4);
    try expect(arrangements(&memo, test_input[5]) == 10);
}

fn unfoldRow(row: InputRow) InputRow {
    return InputRow{
        .pattern = std.mem.join(allocator, "?", &[_][]const u8{ row.pattern, row.pattern, row.pattern, row.pattern, row.pattern }) catch unreachable,
        .target = std.mem.concat(allocator, u16, &[_][]const u16{ row.target, row.target, row.target, row.target, row.target }) catch unreachable,
    };
}

test "arrangements_unfolded" {
    var memo = ArrangementsHash.init(std.testing.allocator);
    defer memo.deinit();
    try expect(arrangements(&memo, unfoldRow(test_input[0])) == 1);
    try expect(arrangements(&memo, unfoldRow(test_input[1])) == 16384);
    try expect(arrangements(&memo, unfoldRow(test_input[2])) == 1);
    try expect(arrangements(&memo, unfoldRow(test_input[3])) == 16);
    try expect(arrangements(&memo, unfoldRow(test_input[4])) == 2500);
    try expect(arrangements(&memo, unfoldRow(test_input[5])) == 506250);
}

fn part1(input: Input) !u64 {
    var memo = ArrangementsHash.init(allocator);
    defer memo.deinit();
    var sum: u64 = 0;
    for (input) |row| {
        memo.clearRetainingCapacity();
        sum += arrangements(&memo, row);
    }
    return sum;
}

test "part1" {
    try expect(try part1(try parse(test_input_str)) == 21);
}

fn part2(input: Input) !u64 {
    var memo = ArrangementsHash.init(allocator);
    defer memo.deinit();
    var sum: u64 = 0;
    for (input) |row| {
        memo.clearRetainingCapacity();
        sum += arrangements(&memo, unfoldRow(row));
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
