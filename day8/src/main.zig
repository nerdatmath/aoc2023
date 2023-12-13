const std = @import("std");
const expect = @import("std").testing.expect;

const test_input =
    \\RL
    \\
    \\AAA = (BBB, CCC)
    \\BBB = (DDD, EEE)
    \\CCC = (ZZZ, GGG)
    \\DDD = (DDD, DDD)
    \\EEE = (EEE, EEE)
    \\GGG = (GGG, GGG)
    \\ZZZ = (ZZZ, ZZZ)
;

const test_input2 =
    \\LR
    \\
    \\QQA = (QQB, XXX)
    \\QQB = (XXX, QQZ)
    \\QQZ = (QQB, XXX)
    \\RRA = (RRB, XXX)
    \\RRB = (RRC, RRC)
    \\RRC = (RRZ, RRZ)
    \\RRZ = (RRB, RRB)
    \\XXX = (XXX, XXX)
;

const Dir = enum {
    left,
    right,
};

fn parseDir(buf: [1]u8) !Dir {
    return switch (buf[0]) {
        'L' => .left,
        'R' => .right,
        else => return error.InvalidDirection,
    };
}

const NodeID = u16;
const maxNodeCount = 26 * 26 * 26;

fn parseNodeID(buf: [3]u8) !NodeID {
    var id: NodeID = 0;
    for (buf) |ch| {
        if (ch < 'A' or ch > 'Z') return error.NotACapitalLetter;
        id = id * 26 + (ch - 'A');
    }
    return id;
}

fn formatNodeID(id: NodeID) [3]u8 {
    var n: u16 = id;
    var buf: [3]u8 = undefined;
    for (0..3) |i| {
        buf[2 - i] = 'A' + @as(u8, @intCast(n % 26));
        n /= 26;
    }
    return buf;
}

test "parse and format NodeID" {
    try expect(try parseNodeID(formatNodeID(12345)) == 12345);
}

const Map = struct {
    instructions: []Dir,
    nodes: []NodeID,
    left: [maxNodeCount]NodeID,
    right: [maxNodeCount]NodeID,
};

// testing only function
fn tNodeID(input: []const u8) NodeID {
    if (input.len != 3) unreachable;
    return parseNodeID(input[0..3].*) catch unreachable;
}

fn parseInstructions(allocator: std.mem.Allocator, input: []const u8) ![]Dir {
    var list = std.ArrayList(Dir).init(allocator);
    errdefer list.deinit();
    for (input) |ch| {
        try list.append(try parseDir(.{ch}));
    }
    return list.toOwnedSlice();
}

test "parseInstructions" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expectEqualSlices(
        Dir,
        &[_]Dir{ .left, .right, .left },
        try parseInstructions(arena.allocator(), "LRL"),
    );
}

fn parseMap(allocator: std.mem.Allocator, input: []const u8) !Map {
    const splitPos = std.mem.indexOf(u8, input, "\n\n") orelse return error.NoBreak;
    const instructions = try parseInstructions(allocator, input[0..splitPos]);
    var list = std.ArrayList(NodeID).init(allocator);
    errdefer list.deinit();
    var left: [maxNodeCount]NodeID = std.mem.zeroes([maxNodeCount]NodeID);
    var right: [maxNodeCount]NodeID = std.mem.zeroes([maxNodeCount]NodeID);
    var it = std.mem.splitScalar(u8, input[splitPos + 2 ..], '\n');
    while (it.next()) |line| {
        if (line.len != 16) return error.BadNodeLine;
        const source = try parseNodeID(line[0..3].*);
        try list.append(source);
        if (!std.mem.eql(u8, line[3..7], " = (")) return error.BadNodeLine;
        left[source] = try parseNodeID(line[7..10].*);
        if (!std.mem.eql(u8, line[10..12], ", ")) return error.BadNodeLine;
        right[source] = try parseNodeID(line[12..15].*);
        if (line[15] != ')') return error.BadNodeLine;
    }
    return Map{
        .instructions = instructions,
        .nodes = try list.toOwnedSlice(),
        .left = left,
        .right = right,
    };
}

test "parseMap" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const map: Map = try parseMap(arena.allocator(), test_input);
    try std.testing.expectEqualSlices(Dir, &[_]Dir{ .right, .left }, map.instructions);
    try std.testing.expectEqualSlices(
        NodeID,
        &[_]NodeID{ tNodeID("AAA"), tNodeID("BBB"), tNodeID("CCC"), tNodeID("DDD"), tNodeID("EEE"), tNodeID("GGG"), tNodeID("ZZZ") },
        map.nodes,
    );
    try std.testing.expect(map.left[tNodeID("AAA")] == tNodeID("BBB"));
    try std.testing.expect(map.right[tNodeID("AAA")] == tNodeID("CCC"));
    try std.testing.expect(map.left[tNodeID("BBB")] == tNodeID("DDD"));
    try std.testing.expect(map.right[tNodeID("BBB")] == tNodeID("EEE"));
    try std.testing.expect(map.left[tNodeID("ZZZ")] == tNodeID("ZZZ"));
    try std.testing.expect(map.right[tNodeID("ZZZ")] == tNodeID("ZZZ"));
}

fn part1(map: Map) !usize {
    var count: usize = 0;
    var node: NodeID = 0; // Node AAA
    const target: NodeID = maxNodeCount - 1; // Node ZZZ
    while (true) {
        for (map.instructions) |inst| {
            if (node == target) return count;
            switch (inst) {
                .left => node = map.left[node],
                .right => node = map.right[node],
            }
            count += 1;
        }
    }
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    {
        const map: Map = try parseMap(arena.allocator(), test_input);
        try expect(try part1(map) == 2);
    }
    {
        const map: Map = try parseMap(arena.allocator(),
            \\LLR
            \\
            \\AAA = (BBB, BBB)
            \\BBB = (AAA, ZZZ)
            \\ZZZ = (ZZZ, ZZZ)
        );
        try expect(try part1(map) == 6);
    }
}

const State = struct { node: NodeID, pos: usize };

fn step(s: State, map: Map) State {
    switch (map.instructions[s.pos]) {
        .left => return State{ .node = map.left[s.node], .pos = (s.pos + 1) % map.instructions.len },
        .right => return State{ .node = map.right[s.node], .pos = (s.pos + 1) % map.instructions.len },
    }
}

const Path = struct {
    prefix: []const usize,
    loop: []const usize,
};

fn path(allocator: std.mem.Allocator, node: NodeID, map: Map) !Path {
    var state = State{ .node = node, .pos = 0 };
    var d = std.AutoHashMap(State, usize).init(allocator);
    defer d.deinit();
    var list = std.ArrayList(usize).init(allocator);
    defer list.deinit();
    while (!d.contains(state)) : (try list.append(distToTarget(&state, map))) {
        // std.debug.print("state={}\n", .{state});
        try d.put(state, list.items.len);
    }
    var slice = try list.toOwnedSlice();
    // std.debug.print("slice={d}\n", .{slice});
    const loopStart = d.get(state).?;
    // std.debug.print("loopStart={d}\n", .{loopStart});
    return Path{
        .prefix = slice[0..loopStart],
        .loop = slice[loopStart..],
    };
}

test "path" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const map: Map = try parseMap(arena.allocator(), test_input2);
    try std.testing.expectEqualDeep(
        Path{ .prefix = &[_]usize{2}, .loop = &[_]usize{2} },
        try path(arena.allocator(), tNodeID("QQA"), map),
    );
    try std.testing.expectEqualDeep(
        Path{ .prefix = &[_]usize{3}, .loop = &[_]usize{ 3, 3 } },
        try path(arena.allocator(), tNodeID("RRA"), map),
    );
}

fn isSource(node: NodeID) bool {
    return node % 26 == 0;
}

fn isTarget(node: NodeID) bool {
    return node % 26 == 25;
}

fn distToTarget(s: *State, map: Map) usize {
    var dist: usize = 0;
    while (dist == 0 or !isTarget(s.node)) : (dist += 1) {
        s.* = step(s.*, map);
    }
    return dist;
}

test "distToTarget" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const map: Map = try parseMap(arena.allocator(), test_input2);
    {
        var s = State{ .node = tNodeID("QQA"), .pos = 0 };
        try expect(distToTarget(&s, map) == 2);
        try expect(s.node == tNodeID("QQZ"));
        try expect(s.pos == 0);
    }
    {
        var s = State{ .node = tNodeID("QQZ"), .pos = 0 };
        try expect(distToTarget(&s, map) == 2);
        try expect(s.node == tNodeID("QQZ"));
        try expect(s.pos == 0);
    }
}

fn lcm(a: usize, b: usize) usize {
    return a * b / std.math.gcd(a, b);
}

fn part2(allocator: std.mem.Allocator, map: Map) !usize {
    // The following only works because we know that the paths we get will have
    // a single element prefix, and the loop will just be copies of that same value.
    // That's not a reasonable expectation a priori, but it's true of the input data.
    // So we can just take the LCM of all those numbers.
    var steps: usize = 1;
    for (map.nodes) |node| {
        if (isSource(node)) { // ends with A
            const p = try path(allocator, node, map);
            // Confirm that it matches our expectations or error out.
            if (p.prefix.len != 1) return error.UnexpectedPath;
            for (p.loop) |x| {
                if (x != p.prefix[0]) return error.UnexpectedPath;
            }
            steps = lcm(steps, p.prefix[0]);
        }
    }
    return steps;
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    {
        const map: Map = try parseMap(arena.allocator(), test_input2);
        try expect(try part2(arena.allocator(), map) == 6);
    }
}

pub fn main() !void {
    var buffer: [1 << 20]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    var input = init: {
        const file = try std.fs.cwd().openFile("input.txt", .{});
        defer file.close();
        break :init try file.readToEndAlloc(allocator, 1 << 16);
    };
    const map: Map = try parseMap(allocator, input);
    std.debug.print("{d}\n", .{try part1(map)});
    std.debug.print("{d}\n", .{try part2(allocator, map)});
}
