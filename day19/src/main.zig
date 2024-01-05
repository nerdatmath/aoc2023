const std = @import("std");
const expect = @import("std").testing.expect;

const test_program_str =
    \\px{a<2006:qkq,m>2090:A,rfg}
    \\pv{a>1716:R,A}
    \\lnx{m>1548:A,A}
    \\rfg{s<537:gd,x>2440:R,A}
    \\qs{s>3448:A,lnx}
    \\qkq{x<1416:A,crn}
    \\crn{x>2662:A,R}
    \\in{s<1351:px,qqz}
    \\qqz{s>2770:qs,m<1801:hdj,R}
    \\gd{a>3333:R,R}
    \\hdj{m>838:A,pv}
;

const test_data_str =
    \\{x=787,m=2655,a=1222,s=2876}
    \\{x=1679,m=44,a=2067,s=496}
    \\{x=2036,m=264,a=79,s=2244}
    \\{x=2461,m=1339,a=466,s=291}
    \\{x=2127,m=1623,a=2188,s=1013}
;

const test_input_str = test_program_str ++ "\n\n" ++ test_data_str;

const test_program = Program{
    .instructions = &[_]Instruction{
        // A (0)
        .{ .ret = true },
        // R (1)
        .{ .ret = false },
        // px (2)
        .{ .blt = .{ .r = .a, .v = 2006, .label = 14 } },
        .{ .bgt = .{ .r = .m, .v = 2090, .label = 0 } },
        .{ .b = .{ .label = 9 } },
        // pv (5)
        .{ .bgt = .{ .r = .a, .v = 1716, .label = 1 } },
        .{ .b = .{ .label = 0 } },
        // lnx (7)
        .{ .bgt = .{ .r = .m, .v = 1548, .label = 0 } },
        .{ .b = .{ .label = 0 } },
        // rfg (9)
        .{ .blt = .{ .r = .s, .v = 537, .label = 23 } },
        .{ .bgt = .{ .r = .x, .v = 2440, .label = 1 } },
        .{ .b = .{ .label = 0 } },
        // qs (12)
        .{ .bgt = .{ .r = .s, .v = 3448, .label = 0 } },
        .{ .b = .{ .label = 7 } },
        // qkq (14)
        .{ .blt = .{ .r = .x, .v = 1416, .label = 0 } },
        .{ .b = .{ .label = 16 } },
        // crn (16)
        .{ .bgt = .{ .r = .x, .v = 2662, .label = 0 } },
        .{ .b = .{ .label = 1 } },
        // in (18)
        .{ .blt = .{ .r = .s, .v = 1351, .label = 2 } },
        .{ .b = .{ .label = 20 } },
        // qqz (20)
        .{ .bgt = .{ .r = .s, .v = 2770, .label = 12 } },
        .{ .blt = .{ .r = .m, .v = 1801, .label = 25 } },
        .{ .b = .{ .label = 1 } },
        // gd (23)
        .{ .bgt = .{ .r = .a, .v = 3333, .label = 1 } },
        .{ .b = .{ .label = 1 } },
        // hdj (25)
        .{ .bgt = .{ .r = .m, .v = 838, .label = 0 } },
        .{ .b = .{ .label = 5 } },
    },
    .start = 18,
};

const test_data = &[_]Part{
    .{ .x = 787, .m = 2655, .a = 1222, .s = 2876 },
    .{ .x = 1679, .m = 44, .a = 2067, .s = 496 },
    .{ .x = 2036, .m = 264, .a = 79, .s = 2244 },
    .{ .x = 2461, .m = 1339, .a = 466, .s = 291 },
    .{ .x = 2127, .m = 1623, .a = 2188, .s = 1013 },
};

const Rating = enum {
    const Self = @This();
    x,
    m,
    a,
    s,

    fn parse(input: []const u8) !Self {
        if (input.len != 1) return error.WrongSize;
        return switch (input[0]) {
            'x' => .x,
            'm' => .m,
            'a' => .a,
            's' => .s,
            else => return error.BadRatingName,
        };
    }
};

const Instruction = union(enum) {
    ret: bool,
    blt: struct { r: Rating, v: u16, label: usize },
    bgt: struct { r: Rating, v: u16, label: usize },
    b: struct { label: usize },
};

const Program = struct {
    const Self = @This();
    instructions: []const Instruction,
    start: usize,

    fn run(self: Self, part: Part) bool {
        var pc = self.start;
        var regs = part;
        while (true) {
            switch (self.instructions[pc]) {
                .ret => |ret| return ret,
                .blt => |blt| if (regs.get(blt.r) < blt.v) {
                    pc = blt.label;
                } else {
                    pc += 1;
                },
                .bgt => |bgt| if (regs.get(bgt.r) > bgt.v) {
                    pc = bgt.label;
                } else {
                    pc += 1;
                },
                .b => |b| pc = b.label,
            }
        }
    }
    fn volume(self: Self, start: usize, r: Range) u64 {
        var pc = start;
        var rest = r;
        var sum: u64 = 0;
        while (true) {
            if (rest.isEmpty()) return sum;
            switch (self.instructions[pc]) {
                .ret => |b| {
                    if (b) sum += rest.volume();
                    return sum;
                },
                .blt => |blt| {
                    const sp = rest.splitAt(blt.r, blt.v);
                    sum += self.volume(blt.label, sp.lo);
                    rest = sp.hi;
                    pc += 1;
                },
                .bgt => |bgt| {
                    const sp = rest.splitAt(bgt.r, bgt.v + 1);
                    sum += self.volume(bgt.label, sp.hi);
                    rest = sp.lo;
                    pc += 1;
                },
                .b => |b| {
                    pc = b.label;
                },
            }
        }
    }
    fn compile(input: []const u8) !Self {
        var list = std.ArrayList(Instruction).init(allocator);
        errdefer list.deinit();
        var labels = std.StringHashMap(usize).init(allocator);
        defer labels.deinit();
        var references = std.ArrayList(struct { label: []const u8, offset: usize }).init(allocator);
        defer references.deinit();
        try labels.put("A", list.items.len);
        try list.append(.{ .ret = true });
        try labels.put("R", list.items.len);
        try list.append(.{ .ret = false });
        var it = std.mem.splitScalar(u8, input, '\n');
        while (it.next()) |line| {
            if (line.len < 1) return error.TooShort;
            if (line[line.len - 1] != '}') return error.NoCloseBrace;
            var p = std.mem.indexOfScalar(u8, line, '{') orelse return error.NoOpenBrace;
            try labels.put(line[0..p], list.items.len);
            var p2 = std.mem.lastIndexOfScalar(u8, line, ',') orelse return error.NoComma;
            var rules = std.mem.splitScalar(u8, line[p + 1 .. p2], ',');
            while (rules.next()) |rule| {
                const p3 = std.mem.indexOfScalar(u8, rule, ':') orelse return error.NoColon;
                const rating = try Rating.parse(rule[0..1]);
                const value = try std.fmt.parseUnsigned(u16, rule[2..p3], 10);
                const label = rule[p3 + 1 ..];
                switch (rule[1]) {
                    '>' => {
                        try list.append(.{ .bgt = .{ .r = rating, .v = value, .label = undefined } });
                        try references.append(.{ .label = label, .offset = @intFromPtr(&list.items[list.items.len - 1].bgt.label) - @intFromPtr(&list.items[0]) });
                    },
                    '<' => {
                        try list.append(.{ .blt = .{ .r = rating, .v = value, .label = undefined } });
                        try references.append(.{ .label = label, .offset = @intFromPtr(&list.items[list.items.len - 1].blt.label) - @intFromPtr(&list.items[0]) });
                    },
                    else => return error.BadOperator,
                }
            }
            try list.append(.{ .b = .{ .label = undefined } });
            try references.append(.{ .label = line[p2 + 1 .. line.len - 1], .offset = @intFromPtr(&list.items[list.items.len - 1].b.label) - @intFromPtr(&list.items[0]) });
        }
        for (references.items) |reference| {
            const ptr = @as(*usize, @ptrFromInt(@intFromPtr(&list.items[0]) + reference.offset));
            ptr.* = labels.get(reference.label) orelse return error.LabelNotFound;
        }
        return Self{
            .instructions = try list.toOwnedSlice(),
            .start = labels.get("in") orelse return error.NoEntryPoint,
        };
    }
};

test "Program.compile" {
    const pgm = try Program.compile(test_program_str);
    try std.testing.expectEqualDeep(test_program, pgm);
}

test "Program.run" {
    const tests = [_]struct { part: Part, accept: bool }{
        .{ .part = .{ .x = 787, .m = 2655, .a = 1222, .s = 2876 }, .accept = true },
        .{ .part = .{ .x = 1679, .m = 44, .a = 2067, .s = 496 }, .accept = false },
        .{ .part = .{ .x = 2036, .m = 264, .a = 79, .s = 2244 }, .accept = true },
        .{ .part = .{ .x = 2461, .m = 1339, .a = 466, .s = 291 }, .accept = false },
        .{ .part = .{ .x = 2127, .m = 1623, .a = 2188, .s = 1013 }, .accept = true },
    };
    for (tests) |t|
        try expect(test_program.run(t.part) == t.accept);
}

const Part = struct {
    const Self = @This();
    x: u16,
    m: u16,
    a: u16,
    s: u16,

    fn parse(input: []const u8) !Self {
        var result: Self = undefined;
        if (input.len < 1 or input[0] != '{') return error.NoOpenBrace;
        if (input[input.len - 1] != '}') return error.NoCloseBrace;
        var it = std.mem.splitScalar(u8, input[1 .. input.len - 1], ',');
        for (std.enums.values(Rating)) |rating|
            if (it.next()) |word| {
                if (word.len < 2) return error.TooShort;
                if (try Rating.parse(word[0..1]) != rating) return error.WrongRating;
                if (word[1] != '=') return error.NoEquals;
                result.set(rating, try std.fmt.parseUnsigned(u16, word[2..], 10));
            };
        if (it.next()) |_| return error.TooManyRatings;
        return result;
    }
    fn ratingSum(self: Self) u16 {
        return self.x + self.m + self.a + self.s;
    }
    fn get(self: Self, rating: Rating) u16 {
        return switch (rating) {
            .x => self.x,
            .m => self.m,
            .a => self.a,
            .s => self.s,
        };
    }
    fn set(self: *Self, r: Rating, v: u16) void {
        (switch (r) {
            .x => &self.x,
            .m => &self.m,
            .a => &self.a,
            .s => &self.s,
        }).* = v;
    }
    fn subst(self: Self, r: Rating, v: u16) Self {
        var new = self;
        new.set(r, v);
        return new;
    }
};

test "Part.parse" {
    try std.testing.expectEqualDeep(
        Part{ .x = 787, .m = 2655, .a = 1222, .s = 2876 },
        try Part.parse("{x=787,m=2655,a=1222,s=2876}"),
    );
}

test "Part.ratingSum" {
    const tests = [_]struct { part: Part, sum: u16 }{
        .{ .part = .{ .x = 787, .m = 2655, .a = 1222, .s = 2876 }, .sum = 7540 },
        .{ .part = .{ .x = 2036, .m = 264, .a = 79, .s = 2244 }, .sum = 4623 },
        .{ .part = .{ .x = 2127, .m = 1623, .a = 2188, .s = 1013 }, .sum = 6951 },
    };
    for (tests) |t|
        try expect(t.part.ratingSum() == t.sum);
}

fn parse(input: []const u8) !struct { program: Program, data: []const Part } {
    const p = std.mem.indexOf(u8, input, "\n\n") orelse return error.NoSplit;
    return .{
        .program = try Program.compile(input[0..p]),
        .data = init: {
            var list = std.ArrayList(Part).init(allocator);
            errdefer list.deinit();
            var it = std.mem.splitScalar(u8, input[p + 2 ..], '\n');
            while (it.next()) |line|
                try list.append(try Part.parse(line));
            break :init try list.toOwnedSlice();
        },
    };
}

test "parse" {
    const parsed = try parse(test_input_str);
    try std.testing.expectEqualDeep(test_program, parsed.program);
    try std.testing.expectEqualSlices(Part, test_data, parsed.data);
}

fn part1(program: Program, data: []const Part) i64 {
    var sum: i64 = 0;
    for (data) |part| {
        if (program.run(part))
            sum += part.ratingSum();
    }
    return sum;
}

test "part1" {
    try expect(part1(test_program, test_data) == 19114);
}

const Range = struct {
    const Self = @This();
    lo: Part,
    hi: Part,

    fn isEmpty(r: Self) bool {
        return for (std.enums.values(Rating)) |rating| {
            if (r.hi.get(rating) <= r.lo.get(rating)) break true;
        } else false;
    }
    fn volume(r: Range) u64 {
        var v: u64 = 1;
        for (std.enums.values(Rating)) |rating|
            v *= r.hi.get(rating) -| r.lo.get(rating);
        return v;
    }
    fn splitAt(r: Self, rating: Rating, value: u16) struct { lo: Range, hi: Range } {
        return .{
            .lo = .{ .lo = r.lo, .hi = r.hi.subst(rating, value) },
            .hi = .{ .lo = r.lo.subst(rating, value), .hi = r.hi },
        };
    }
};

fn part2(program: Program) u64 {
    return program.volume(program.start, .{
        .lo = .{ .x = 1, .m = 1, .a = 1, .s = 1 },
        .hi = .{ .x = 4001, .m = 4001, .a = 4001, .s = 4001 },
    });
}

test "part2" {
    try expect(part2(test_program) == 167409079868000);
}

var buffer: [1 << 20]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
const allocator = fba.allocator();
pub fn main() !void {
    var input_string = init: {
        const file = try std.fs.cwd().openFile("input.txt", .{});
        defer file.close();
        break :init try file.readToEndAlloc(allocator, 1 << 16);
    };
    const parsed = try parse(input_string);
    std.debug.print("{d}\n", .{part1(parsed.program, parsed.data)});
    std.debug.print("{d}\n", .{part2(parsed.program)});
}
