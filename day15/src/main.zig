const std = @import("std");
const expect = @import("std").testing.expect;

const test_input = "rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7";

fn hash(in: []const u8) u8 {
    var value: u8 = 0;
    for (in) |ch| {
        value *%= 17;
        value +%= ch *% 17;
    }
    return value;
}

test "hash" {
    try expect(hash("HASH") == 52);
}

fn part1(input: []const u8) !u64 {
    var sum: u64 = 0;
    var it = std.mem.splitScalar(u8, input, ',');
    while (it.next()) |word| sum += hash(word);
    return sum;
}

test "part1" {
    try expect(try part1(test_input) == 1320);
}

const Lens = struct {
    label: []const u8,
    focalLength: u64,
};

const HashMap = struct {
    const Self = @This();
    const Node = struct {
        next: ?*Node,
        data: Lens,
    };
    boxes: [256]?*Node = [_]?*Node{null} ** 256,
    fn findNodePtr(self: *Self, label: []const u8) *?*Node {
        const h = hash(label);
        var p = &self.boxes[h];
        while (p.*) |node| : (p = &node.next)
            if (std.mem.eql(u8, node.data.label, label)) break;
        return p;
    }
    fn addOrReplace(self: *Self, item: Lens) !void {
        const p = self.findNodePtr(item.label);
        if (p.*) |node| {
            node.data = item;
        } else {
            const node = try allocator.create(Node);
            node.data = item;
            node.next = null;
            p.* = node;
        }
    }
    fn delete(self: *Self, label: []const u8) void {
        const p = self.findNodePtr(label);
        if (p.*) |node| {
            p.* = node.next;
            allocator.destroy(node);
        }
    }
    fn visit(self: Self, comptime T: type, comptime f: fn (t: T, box: u8, e: usize, item: Lens) void, t: T) void {
        for (0..256) |i| {
            var optnode = self.boxes[i];
            var j: usize = 0;
            while (optnode) |node| : ({
                optnode = node.next;
                j += 1;
            })
                f(t, @intCast(i), j, node.data);
        }
    }
};

fn parseLens(in: []const u8) !Lens {
    const pos = std.mem.indexOfScalar(u8, in, '=') orelse return error.NoEquals;
    return Lens{
        .label = in[0..pos],
        .focalLength = try std.fmt.parseUnsigned(u64, in[pos + 1 ..], 10),
    };
}

fn addScore(sum: *u64, box: u8, e: usize, lens: Lens) void {
    sum.* += (@as(u64, box) + 1) * (e + 1) * lens.focalLength;
}

fn part2(input: []const u8) !u64 {
    var sum: u64 = 0;
    var it = std.mem.splitScalar(u8, input, ',');
    var hm = HashMap{};
    while (it.next()) |word| {
        if (word[word.len - 1] == '-') {
            hm.delete(word[0 .. word.len - 1]);
        } else {
            const lens = try parseLens(word);
            try hm.addOrReplace(lens);
        }
    }
    hm.visit(*u64, addScore, &sum);
    return sum;
}

test "part2" {
    try expect(try part2(test_input) == 145);
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
    std.debug.print("{d}\n", .{try part1(input_string)});
    std.debug.print("{d}\n", .{try part2(input_string)});
}
