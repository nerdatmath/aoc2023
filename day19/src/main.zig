const std = @import("std");
const expect = @import("std").testing.expect;

const test_input_str =
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
    \\
    \\{x=787,m=2655,a=1222,s=2876}
    \\{x=1679,m=44,a=2067,s=496}
    \\{x=2036,m=264,a=79,s=2244}
    \\{x=2461,m=1339,a=466,s=291}
    \\{x=2127,m=1623,a=2188,s=1013}
;

const test_input = Data{
    .workflows = &[_]Workflow{
        Accept,
        Reject,
        .{ //crn{x>2662:A,R}
            .name = "crn",
            .action = .{
                .rules = &[_]Rule{
                    .{ .condition = .{ .comparison = .{ .rating = .x, .op = .gt, .value = 2662 } }, .workflow = "A" },
                    .{ .condition = Always, .workflow = "R" },
                },
            },
        },
        .{ //gd{a>3333:R,R}
            .name = "gd",
            .action = .{
                .rules = &[_]Rule{
                    .{ .condition = .{ .comparison = .{ .rating = .a, .op = .gt, .value = 3333 } }, .workflow = "R" },
                    .{ .condition = Always, .workflow = "R" },
                },
            },
        },
        .{ //hdj{m>838:A,pv}
            .name = "hdj",
            .action = .{
                .rules = &[_]Rule{
                    .{ .condition = .{ .comparison = .{ .rating = .m, .op = .gt, .value = 838 } }, .workflow = "A" },
                    .{ .condition = Always, .workflow = "pv" },
                },
            },
        },
        .{ //in{s<1351:px,qqz}
            .name = "in",
            .action = .{
                .rules = &[_]Rule{
                    .{ .condition = .{ .comparison = .{ .rating = .s, .op = .lt, .value = 1351 } }, .workflow = "px" },
                    .{ .condition = Always, .workflow = "qqz" },
                },
            },
        },
        .{ //lnx{m>1548:A,A}
            .name = "lnx",
            .action = .{
                .rules = &[_]Rule{
                    .{ .condition = .{ .comparison = .{ .rating = .m, .op = .gt, .value = 1548 } }, .workflow = "A" },
                    .{ .condition = Always, .workflow = "A" },
                },
            },
        },
        .{ //pv{a>1716:R,A}
            .name = "pv",
            .action = .{
                .rules = &[_]Rule{
                    .{ .condition = .{ .comparison = .{ .rating = .a, .op = .gt, .value = 1716 } }, .workflow = "R" },
                    .{ .condition = Always, .workflow = "A" },
                },
            },
        },
        .{ //px{a<2006:qkq,m>2090:A,rfg}
            .name = "px",
            .action = .{
                .rules = &[_]Rule{
                    .{ .condition = .{ .comparison = .{ .rating = .a, .op = .lt, .value = 2006 } }, .workflow = "qkq" },
                    .{ .condition = .{ .comparison = .{ .rating = .m, .op = .gt, .value = 2090 } }, .workflow = "A" },
                    .{ .condition = Always, .workflow = "rfg" },
                },
            },
        },
        .{ //qkq{x<1416:A,crn}
            .name = "qkq",
            .action = .{
                .rules = &[_]Rule{
                    .{ .condition = .{ .comparison = .{ .rating = .x, .op = .lt, .value = 1416 } }, .workflow = "A" },
                    .{ .condition = Always, .workflow = "crn" },
                },
            },
        },
        .{ //qqz{s>2770:qs,m<1801:hdj,R}
            .name = "qqz",
            .action = .{
                .rules = &[_]Rule{
                    .{ .condition = .{ .comparison = .{ .rating = .s, .op = .gt, .value = 2770 } }, .workflow = "qs" },
                    .{ .condition = .{ .comparison = .{ .rating = .m, .op = .lt, .value = 1801 } }, .workflow = "hdj" },
                    .{ .condition = Always, .workflow = "R" },
                },
            },
        },
        .{ //qs{s>3448:A,lnx}
            .name = "qs",
            .action = .{
                .rules = &[_]Rule{
                    .{ .condition = .{ .comparison = .{ .rating = .s, .op = .gt, .value = 3448 } }, .workflow = "A" },
                    .{ .condition = Always, .workflow = "lnx" },
                },
            },
        },
        .{ //rfg{s<537:gd,x>2440:R,A}
            .name = "rfg",
            .action = .{
                .rules = &[_]Rule{
                    .{ .condition = .{ .comparison = .{ .rating = .s, .op = .lt, .value = 537 } }, .workflow = "gd" },
                    .{ .condition = .{ .comparison = .{ .rating = .x, .op = .gt, .value = 2440 } }, .workflow = "R" },
                    .{ .condition = Always, .workflow = "A" },
                },
            },
        },
    },
    .parts = &[_]Part{
        .{ .x = 787, .m = 2655, .a = 1222, .s = 2876 },
        .{ .x = 1679, .m = 44, .a = 2067, .s = 496 },
        .{ .x = 2036, .m = 264, .a = 79, .s = 2244 },
        .{ .x = 2461, .m = 1339, .a = 466, .s = 291 },
        .{ .x = 2127, .m = 1623, .a = 2188, .s = 1013 },
    },
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

const Operator = enum {
    const Self = @This();
    lt,
    gt,

    fn parse(input: []const u8) !Self {
        if (input.len != 1) return error.WrongSize;
        return switch (input[0]) {
            '<' => .lt,
            '>' => .gt,
            else => return error.BadOperator,
        };
    }
};

const Comparison = struct {
    const Self = @This();
    rating: Rating,
    op: Operator,
    value: u16,

    fn parse(input: []const u8) !Self {
        if (input.len < 3) return error.WrongSize;
        return Comparison{
            .rating = try Rating.parse(input[0..1]),
            .op = try Operator.parse(input[1..2]),
            .value = try std.fmt.parseUnsigned(u16, input[2..], 10),
        };
    }
    fn matches(self: Self, part: Part) bool {
        return switch (self.op) {
            .lt => part.get(self.rating) < self.value,
            .gt => part.get(self.rating) > self.value,
        };
    }
};

test "Comparison.parse" {
    try std.testing.expectEqualDeep(
        Comparison{ .rating = .a, .op = .lt, .value = 2006 },
        try Comparison.parse("a<2006"),
    );
}

const Condition = union(enum) {
    const Self = @This();
    comparison: Comparison,
    always: struct {},

    fn matches(self: Self, part: Part) bool {
        return switch (self) {
            .comparison => |c| c.matches(part),
            .always => true,
        };
    }
};

const Always = Condition{ .always = .{} };

const Rule = struct {
    const Self = @This();
    condition: Condition,
    workflow: []const u8,

    fn parse(input: []const u8) !Self {
        const p = std.mem.indexOfScalar(u8, input, ':') orelse return error.NoSplit;
        return Self{
            .condition = .{ .comparison = try Comparison.parse(input[0..p]) },
            .workflow = input[p + 1 ..],
        };
    }
};

test "Rule.parse" {
    try std.testing.expectEqualDeep(
        Rule{ .condition = .{ .comparison = .{ .rating = .a, .op = .lt, .value = 2006 } }, .workflow = "qkq" },
        try Rule.parse("a<2006:qkq"),
    );
}

const Workflow = struct {
    const Self = @This();
    name: []const u8,
    action: union(enum) {
        halt: bool,
        rules: []const Rule,
    },

    fn parse(input: []const u8) !Self {
        if (input.len < 4) return error.TooShort;
        if (input[input.len - 1] != '}') return error.NoCloseBrace;
        var p = std.mem.indexOfScalar(u8, input, '{') orelse return error.NoOpenBrace;
        var p2 = std.mem.lastIndexOfScalar(u8, input, ',') orelse return error.NoComma;
        var list = std.ArrayList(Rule).init(allocator);
        errdefer list.deinit();
        return Self{
            .name = input[0..p],
            .action = .{
                .rules = init: {
                    var it = std.mem.splitScalar(u8, input[p + 1 .. p2], ',');
                    while (it.next()) |item|
                        try list.append(try Rule.parse(item));
                    try list.append(Rule{ .condition = Always, .workflow = input[p2 + 1 .. input.len - 1] });
                    break :init try list.toOwnedSlice();
                },
            },
        };
    }
    fn lessThan(context: void, lhs: Self, rhs: Self) bool {
        _ = context;
        return std.mem.lessThan(u8, lhs.name, rhs.name);
    }
};

const Accept = Workflow{ .name = "A", .action = .{ .halt = true } };
const Reject = Workflow{ .name = "R", .action = .{ .halt = false } };

test "Workflow.parse" {
    try std.testing.expectEqualDeep(
        Workflow{
            .name = "px",
            .action = .{
                .rules = &[_]Rule{
                    .{ .condition = .{ .comparison = .{ .rating = .a, .op = .lt, .value = 2006 } }, .workflow = "qkq" },
                    .{ .condition = .{ .comparison = .{ .rating = .m, .op = .gt, .value = 2090 } }, .workflow = "A" },
                    .{ .condition = Always, .workflow = "rfg" },
                },
            },
        },
        try Workflow.parse("px{a<2006:qkq,m>2090:A,rfg}"),
    );
}

const Part = struct {
    const Self = @This();
    x: u16,
    m: u16,
    a: u16,
    s: u16,

    fn parse(input: []const u8) !Self {
        if (input.len < 3) return error.TooShort;
        if (input[0] != '{') return error.NoOpenBrace;
        if (input[input.len - 1] != '}') return error.NoCloseBrace;
        var it = std.mem.splitScalar(u8, input[1 .. input.len - 1], ',');
        var arr = std.EnumArray(Rating, ?u16).initFill(null);
        while (it.next()) |word| {
            if (word.len < 3) return error.TooShort;
            if (word[1] != '=') return error.NoEquals;
            const rating = try Rating.parse(word[0..1]);
            if (arr.get(rating) != null) return error.RepeatedRating;
            arr.set(rating, try std.fmt.parseUnsigned(u16, word[2..], 10));
        }
        return Self{
            .x = arr.get(.x) orelse return error.RatingNotSet,
            .m = arr.get(.m) orelse return error.RatingNotSet,
            .a = arr.get(.a) orelse return error.RatingNotSet,
            .s = arr.get(.s) orelse return error.RatingNotSet,
        };
    }
    fn ratingSum(self: Self) u16 {
        return self.x + self.m + self.a + self.s;
    }
    fn getPtr(self: *Self, rating: Rating) *u16 {
        return switch (rating) {
            .x => &self.x,
            .m => &self.m,
            .a => &self.a,
            .s => &self.s,
        };
    }
    fn get(self: Self, rating: Rating) u16 {
        return switch (rating) {
            .x => self.x,
            .m => self.m,
            .a => self.a,
            .s => self.s,
        };
    }
    fn subst(self: Self, r: Rating, v: u16) Self {
        var new = self;
        new.getPtr(r).* = v;
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

const Data = struct {
    const Self = @This();
    workflows: []const Workflow,
    parts: []const Part,

    fn parse(input: []const u8) !Self {
        const p = std.mem.indexOf(u8, input, "\n\n") orelse return error.NoSplit;
        return Self{
            .workflows = init: {
                var list = std.ArrayList(Workflow).init(allocator);
                errdefer list.deinit();
                try list.append(Accept);
                try list.append(Reject);
                var it = std.mem.splitScalar(u8, input[0..p], '\n');
                while (it.next()) |line| {
                    try list.append(try Workflow.parse(line));
                }
                std.sort.insertion(Workflow, list.items, {}, Workflow.lessThan);
                break :init try list.toOwnedSlice();
            },
            .parts = init: {
                var list = std.ArrayList(Part).init(allocator);
                errdefer list.deinit();
                var it = std.mem.splitScalar(u8, input[p + 2 ..], '\n');
                while (it.next()) |line| {
                    try list.append(try Part.parse(line));
                }
                break :init try list.toOwnedSlice();
            },
        };
    }
};

test "Data.parse" {
    try std.testing.expectEqualDeep(test_input, try Data.parse(test_input_str));
}

fn compareWorkflowName(context: void, name: []const u8, workflow: Workflow) std.math.Order {
    _ = context;
    return std.mem.order(u8, name, workflow.name);
}

fn getWorkflow(workflows: []const Workflow, name: []const u8) Workflow {
    const wf = workflows[std.sort.binarySearch(Workflow, name, workflows, {}, compareWorkflowName) orelse unreachable];
    std.debug.assert(std.mem.eql(u8, wf.name, name));
    return wf;
}

fn check(part: Part, workflows: []const Workflow, start: []const u8) bool {
    return switch (getWorkflow(workflows, start).action) {
        .halt => |b| b,
        .rules => |rules| for (rules) |rule|
            if (rule.condition.matches(part))
                break check(part, workflows, rule.workflow),
    };
}

test "check" {
    const tests = [_]struct { part: Part, accept: bool }{
        .{ .part = .{ .x = 787, .m = 2655, .a = 1222, .s = 2876 }, .accept = true },
        .{ .part = .{ .x = 1679, .m = 44, .a = 2067, .s = 496 }, .accept = false },
        .{ .part = .{ .x = 2036, .m = 264, .a = 79, .s = 2244 }, .accept = true },
        .{ .part = .{ .x = 2461, .m = 1339, .a = 466, .s = 291 }, .accept = false },
        .{ .part = .{ .x = 2127, .m = 1623, .a = 2188, .s = 1013 }, .accept = true },
    };
    for (tests) |t|
        try expect(check(t.part, test_input.workflows, "in") == t.accept);
}

fn part1(input: Data) i64 {
    var sum: i64 = 0;
    for (input.parts) |part| {
        if (check(part, input.workflows, "in"))
            sum += part.ratingSum();
    }
    return sum;
}

test "part1" {
    try expect(part1(test_input) == 19114);
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
    pub fn format(r: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        return std.fmt.format(
            writer,
            "({d}..{d}, {d}..{d}, {d}..{d}, {d}..{d})",
            .{ r.lo.x, r.hi.x, r.lo.m, r.hi.m, r.lo.a, r.hi.a, r.lo.s, r.hi.s },
        );
    }
};

const EmptyRange = Range{
    .lo = .{ .x = 0, .m = 0, .a = 0, .s = 0 },
    .hi = .{ .x = 0, .m = 0, .a = 0, .s = 0 },
};

const SplitRange = struct {
    const Self = @This();
    match: Range,
    rest: Range,

    fn make(r: Range, cond: Condition) Self {
        switch (cond) {
            .always => return Self{ .match = r, .rest = EmptyRange },
            .comparison => |c| {
                return switch (c.op) {
                    .lt => Self{
                        .match = .{ .lo = r.lo, .hi = r.hi.subst(c.rating, c.value) },
                        .rest = .{ .lo = r.lo.subst(c.rating, c.value), .hi = r.hi },
                    },
                    .gt => Self{
                        .match = .{ .lo = r.lo.subst(c.rating, c.value + 1), .hi = r.hi },
                        .rest = .{ .lo = r.lo, .hi = r.hi.subst(c.rating, c.value + 1) },
                    },
                };
            },
        }
    }
};

fn volume(r: Range, workflows: []const Workflow, start: []const u8) u64 {
    return switch (getWorkflow(workflows, start).action) {
        .halt => |b| if (b) r.volume() else 0,
        .rules => |rules| init: {
            var rest = r;
            var sum: u64 = 0;
            for (rules) |rule| {
                if (rest.isEmpty()) break;
                const sp = SplitRange.make(rest, rule.condition);
                sum += volume(sp.match, workflows, rule.workflow);
                rest = sp.rest;
            }
            break :init sum;
        },
    };
}

fn part2(input: Data) u64 {
    const v = volume(
        .{
            .lo = .{ .x = 1, .m = 1, .a = 1, .s = 1 },
            .hi = .{ .x = 4001, .m = 4001, .a = 4001, .s = 4001 },
        },
        input.workflows,
        "in",
    );
    return v;
}

test "part2" {
    try expect(part2(test_input) == 167409079868000);
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
    const input = try Data.parse(input_string);
    std.debug.print("{d}\n", .{part1(input)});
    std.debug.print("{d}\n", .{part2(input)});
}
