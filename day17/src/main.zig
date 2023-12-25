const std = @import("std");
const expect = @import("std").testing.expect;

const test_input_str =
    \\2413432311323
    \\3215453535623
    \\3255245654254
    \\3446585845452
    \\4546657867536
    \\1438598798454
    \\4457876987766
    \\3637877979653
    \\4654967986887
    \\4564679986453
    \\1224686865563
    \\2546548887735
    \\4322674655533
;

const maxSize = 256;

const Dir = enum {
    const Self = @This();
    up,
    dn,
    lt,
    rt,
    fn left(self: Self) Self {
        return switch (self) {
            .up => .lt,
            .dn => .rt,
            .lt => .dn,
            .rt => .up,
        };
    }
    fn right(self: Self) Self {
        return switch (self) {
            .up => .rt,
            .dn => .lt,
            .lt => .up,
            .rt => .dn,
        };
    }
};

const Pos = struct {
    const Self = @This();
    x: usize,
    y: usize,
    const maxIndex = maxSize * maxSize;
    fn eql(self: Self, other: Self) bool {
        return self.x == other.x and self.y == other.y;
    }
    fn compare(a: Self, b: Self) std.math.Order {
        if (a.y != b.y) return std.math.order(a.y, b.y);
        return std.math.order(a.x, b.x);
    }
    fn index(self: Self) usize {
        return @as(usize, self.y) * maxSize + self.x;
    }
    fn step(self: Self, dir: Dir, dist: usize, size: usize) ?Self {
        return switch (dir) {
            .up => if (self.y >= dist) .{ .x = self.x, .y = self.y - dist } else null,
            .dn => if (self.y < size - dist) .{ .x = self.x, .y = self.y + dist } else null,
            .lt => if (self.x > dist) .{ .x = self.x - dist, .y = self.y } else null,
            .rt => if (self.x < size - dist) .{ .x = self.x + dist, .y = self.y } else null,
        };
    }
};

const Map = struct {
    const Self = @This();
    size: usize,
    blocks: [maxSize][maxSize]usize,
    fn at(self: Self, pos: Pos) ?usize {
        if (pos.x >= self.size or pos.y >= self.size) return null;
        return self.blocks[pos.y][pos.x];
    }
};

fn parse(input: []const u8) !Map {
    var it = std.mem.splitScalar(u8, input, '\n');
    var map: Map = undefined;
    var j: usize = 0;
    while (it.next()) |line| : (j += 1) {
        map.size = line.len;
        for (line, 0..) |ch, i| {
            map.blocks[j][i] = try std.fmt.charToDigit(ch, 10);
        }
    }
    return map;
}

const Graph = struct {
    const Self = @This();
    map: Map,
    ultra: bool,

    const Node = struct {
        pos: Pos,
        dir: Dir,
        fn compare(a: Node, b: Node) std.math.Order {
            const posOrder = Pos.compare(a.pos, b.pos);
            if (posOrder != .eq) return posOrder;
            return std.math.order(@intFromEnum(a.dir), @intFromEnum(b.dir));
        }
    };

    const Edge = struct {
        dest: Node,
        cost: usize,
    };

    fn edges(self: Self, node: Node, buf: *[20]Edge) []Edge {
        var len: usize = 0;
        var cost: usize = 0;
        const min: usize = if (self.ultra) 4 else 1;
        const max: usize = if (self.ultra) 10 else 3;
        for (1..max + 1) |blocks| {
            if (node.pos.step(node.dir, blocks, self.map.size)) |pos| {
                cost += self.map.at(pos) orelse unreachable;
                if (blocks < min) continue;
                for ([_]Dir{ node.dir.left(), node.dir.right() }) |dir| {
                    buf[len] = Edge{ .dest = Node{ .pos = pos, .dir = dir }, .cost = cost };
                    len += 1;
                }
            } else break;
        }
        return buf[0..len];
    }
};

const Dijkstra = struct {
    const Self = @This();
    const Key = struct {
        graphNode: Graph.Node,
        dist: usize,
    };
    fn compareKeys(a: Key, b: Key) std.math.Order {
        if (a.dist != b.dist) return std.math.order(a.dist, b.dist);
        return Graph.Node.compare(a.graphNode, b.graphNode);
    }
    const Treap = std.Treap(Key, compareKeys);
    g: Graph,
    nodes: [maxSize][maxSize]std.enums.EnumArray(Dir, Treap.Node) = undefined,
    dist: [maxSize][maxSize]std.enums.EnumArray(Dir, usize) = undefined,
    treap: Treap = Treap{},

    fn nodePtr(self: *Self, p: Graph.Node) *Treap.Node {
        return self.nodes[p.pos.y][p.pos.x].getPtr(p.dir);
    }

    fn distPtr(self: *Self, p: Graph.Node) *usize {
        return self.dist[p.pos.y][p.pos.x].getPtr(p.dir);
    }

    fn init(self: *Self) void {
        for (0..self.g.map.size) |j| {
            for (0..self.g.map.size) |i| {
                for (std.enums.values(Dir)) |dir| {
                    const p = Graph.Node{
                        .pos = .{ .x = i, .y = j },
                        .dir = dir,
                    };
                    self.distPtr(p).* = std.math.maxInt(usize);
                    self.insert(p);
                }
            }
        }
    }

    fn insert(self: *Self, p: Graph.Node) void {
        var entry = self.treap.getEntryFor(.{ .graphNode = p, .dist = self.distPtr(p).* });
        entry.set(self.nodePtr(p));
    }

    fn remove(self: *Self, p: Graph.Node) void {
        var entry = self.treap.getEntryFor(.{ .graphNode = p, .dist = self.distPtr(p).* });
        entry.set(null);
    }

    fn reduceDist(self: *Self, p: Graph.Node, dist: usize) void {
        const dp = self.distPtr(p);
        if (dist < dp.*) {
            self.remove(p);
            dp.* = dist;
            self.insert(p);
        }
    }

    fn extractMin(self: *Self) ?Key {
        if (self.treap.getMin()) |node| {
            const key = node.key;
            var entry = self.treap.getEntryForExisting(node);
            entry.set(null);
            return key;
        } else return null;
    }

    fn shortestPath(self: *Self, start: Pos, end: Pos) !usize {
        var buf: [20]Graph.Edge = undefined;
        self.init();
        for (std.enums.values(Dir)) |dir|
            self.reduceDist(.{ .pos = start, .dir = dir }, 0);
        while (self.extractMin()) |key| {
            if (end.eql(key.graphNode.pos))
                return key.dist;
            for (self.g.edges(key.graphNode, &buf)) |e|
                self.reduceDist(e.dest, key.dist + e.cost);
        } else return error.NotReached;
    }
};

fn part1(map: Map) !usize {
    var dijkstra = Dijkstra{ .g = .{ .map = map, .ultra = false } };
    return try dijkstra.shortestPath(Pos{ .x = 0, .y = 0 }, Pos{ .x = map.size - 1, .y = map.size - 1 });
}

test "part1" {
    const test_input = try parse(test_input_str);
    try expect(try part1(test_input) == 102);
}

fn part2(map: Map) !u64 {
    var dijkstra = Dijkstra{ .g = .{ .map = map, .ultra = true } };
    return try dijkstra.shortestPath(Pos{ .x = 0, .y = 0 }, Pos{ .x = map.size - 1, .y = map.size - 1 });
}

test "part2" {
    const test_input = try parse(test_input_str);
    try expect(try part2(test_input) == 94);
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
