const std = @import("std");
const expect = @import("std").testing.expect;

const Card = enum {
    joker,
    two,
    three,
    four,
    five,
    six,
    seven,
    eight,
    nine,
    ten,
    queen,
    king,
    ace,
};

const cardChars = "J23456789TQKA";

fn cardToChar(c: Card) u8 {
    return cardChars[@intFromEnum(c)];
}

fn charToCard(ch: u8) ?Card {
    return @enumFromInt(std.mem.indexOfScalar(u8, cardChars, ch) orelse return null);
}

const Hand = [5]Card;

fn parseHand(buffer: [5]u8) !Hand {
    var hand: Hand = undefined;
    for (buffer, 0..) |ch, i| {
        hand[i] = charToCard(ch) orelse return error.BadCard;
    }
    return hand;
}

test "parseHand" {
    try std.testing.expectEqual(
        Hand{ .three, .two, .ten, .three, .king },
        try parseHand(@as(*const [5]u8, "32T3K").*),
    );
}

const Play = struct { hand: Hand, bid: u32 };

fn parsePlay(buffer: []const u8) !Play {
    if (buffer.len < 7) {
        return error.LineTooShort;
    }
    if (buffer[5] != ' ') {
        return error.BadFormat;
    }
    return Play{
        .hand = try parseHand(buffer[0..5].*),
        .bid = try std.fmt.parseInt(u32, buffer[6..], 10),
    };
}

test "parsePlay" {
    try std.testing.expectEqual(
        Play{ .hand = .{ .three, .two, .ten, .three, .king }, .bid = 765 },
        try parsePlay("32T3K 765"),
    );
}

const Game = []const Play;

fn parseGame(allocator: std.mem.Allocator, buffer: []const u8) !Game {
    var list = std.ArrayList(Play).init(allocator);
    errdefer list.deinit();
    var iter = std.mem.splitScalar(u8, buffer, '\n');
    while (iter.next()) |line| {
        try list.append(try parsePlay(line));
    }
    return list.toOwnedSlice();
}

const test_input =
    \\32T3K 765
    \\T55J5 684
    \\KK677 28
    \\KTJJT 220
    \\QQQJA 483
;

const test_game: Game = @as(Game, &[_]Play{
    .{ .hand = .{ .three, .two, .ten, .three, .king }, .bid = 765 },
    .{ .hand = .{ .ten, .five, .five, .joker, .five }, .bid = 684 },
    .{ .hand = .{ .king, .king, .six, .seven, .seven }, .bid = 28 },
    .{ .hand = .{ .king, .ten, .joker, .joker, .ten }, .bid = 220 },
    .{ .hand = .{ .queen, .queen, .queen, .joker, .ace }, .bid = 483 },
});

test "parseGame" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expectEqualDeep(
        test_game,
        try parseGame(arena.allocator(), test_input),
    );
}

const HandType = enum {
    highCard,
    onePair,
    twoPair,
    threeOfAKind,
    fullHouse,
    fourOfAKind,
    fiveOfAKind,
};

fn handType(hand: Hand) HandType {
    var bag = std.enums.BoundedEnumMultiset(Card, u8).initEmpty();
    for (hand) |card| {
        bag.addAssertSafe(card, 1);
    }
    var biggestCard: ?Card = null;
    var biggestCount: u8 = 0;
    {
        var it = bag.iterator();
        while (it.next()) |entry| {
            if (entry.key == .joker) continue;
            if (biggestCount < entry.value.*) {
                biggestCard = entry.key;
                biggestCount = entry.value.*;
            }
        }
        if (biggestCard) |c| {
            const jokers = bag.getCount(.joker);
            bag.setCount(.joker, 0);
            bag.addAssertSafe(c, jokers);
        }
    }
    var counts: [6]u4 = .{ 0, 0, 0, 0, 0, 0 };
    {
        var it = bag.iterator();
        while (it.next()) |entry| {
            counts[entry.value.*] += 1;
        }
    }
    if (std.meta.eql(counts, .{ 8, 5, 0, 0, 0, 0 }))
        return .highCard
    else if (std.meta.eql(counts, .{ 9, 3, 1, 0, 0, 0 }))
        return .onePair
    else if (std.meta.eql(counts, .{ 10, 1, 2, 0, 0, 0 }))
        return .twoPair
    else if (std.meta.eql(counts, .{ 10, 2, 0, 1, 0, 0 }))
        return .threeOfAKind
    else if (std.meta.eql(counts, .{ 11, 0, 1, 1, 0, 0 }))
        return .fullHouse
    else if (std.meta.eql(counts, .{ 11, 1, 0, 0, 1, 0 }))
        return .fourOfAKind
    else if (std.meta.eql(counts, .{ 12, 0, 0, 0, 0, 1 }))
        return .fiveOfAKind
    else
        unreachable;
}

const hAAAAA: Hand = .{ .ace, .ace, .ace, .ace, .ace };
const hAA8AA: Hand = .{ .ace, .ace, .eight, .ace, .ace };
const hAAJAA: Hand = .{ .ace, .ace, .joker, .ace, .ace };
const h23332: Hand = .{ .two, .three, .three, .three, .two };
const hTTT98: Hand = .{ .ten, .ten, .ten, .nine, .eight };
const h23432: Hand = .{ .two, .three, .four, .three, .two };
const hA23A4: Hand = .{ .ace, .two, .three, .ace, .four };
const h23456: Hand = .{ .two, .three, .four, .five, .six };
const h33332: Hand = .{ .three, .three, .three, .three, .two };
const h2AAAA: Hand = .{ .two, .ace, .ace, .ace, .ace };
const h77888: Hand = .{ .seven, .seven, .eight, .eight, .eight };
const h77788: Hand = .{ .seven, .seven, .seven, .eight, .eight };
const hQJJQ2: Hand = .{ .queen, .joker, .joker, .queen, .two };
const hJKKK2: Hand = .{ .joker, .king, .king, .king, .two };
const hQQQQ2: Hand = .{ .queen, .queen, .queen, .queen, .two };

test "handType" {
    try expect(handType(hAAAAA) == .fiveOfAKind);
    try expect(handType(hAA8AA) == .fourOfAKind);
    try expect(handType(hAAJAA) == .fiveOfAKind);
    try expect(handType(h23332) == .fullHouse);
    try expect(handType(hTTT98) == .threeOfAKind);
    try expect(handType(h23432) == .twoPair);
    try expect(handType(hA23A4) == .onePair);
    try expect(handType(h23456) == .highCard);
    try expect(handType(hQJJQ2) == .fourOfAKind);
    try expect(handType(hJKKK2) == .fourOfAKind);
    try expect(handType(hQQQQ2) == .fourOfAKind);
}

fn lessHandType(a: HandType, b: HandType) bool {
    return @intFromEnum(a) < @intFromEnum(b);
}

fn lessCard(a: Card, b: Card) bool {
    return @intFromEnum(a) < @intFromEnum(b);
}

fn lessHand(a: Hand, b: Hand) bool {
    if (lessHandType(handType(a), handType(b))) {
        return true;
    }
    if (lessHandType(handType(b), handType(a))) {
        return false;
    }
    for (0..5) |i| {
        if (lessCard(a[i], b[i])) {
            return true;
        }
        if (lessCard(b[i], a[i])) {
            return false;
        }
    }
    return false;
}

test "lessHand" {
    try expect(lessHand(hAA8AA, hAAAAA));
    try expect(!lessHand(hAAAAA, hAA8AA));
    try expect(!lessHand(h33332, h2AAAA));
    try expect(!lessHand(h77888, h77788));
    try expect(lessHand(hJKKK2, hQQQQ2));
}

fn lessPlayByHand(context: void, a: Play, b: Play) bool {
    _ = context;
    return lessHand(a.hand, b.hand);
}

fn part2(allocator: std.mem.Allocator, game: Game) !u64 {
    var plays: []Play = try allocator.dupe(Play, game);
    defer allocator.free(plays);
    std.sort.insertion(Play, plays, {}, lessPlayByHand);
    var sum: u64 = 0;
    for (plays, 1..) |p, i| {
        sum += i * p.bid;
    }
    return sum;
}

test "part2" {
    try expect(try part2(std.testing.allocator, test_game) == 5905);
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
    const game = try parseGame(allocator, input);
    std.debug.print("{d}\n", .{try part2(allocator, game)});
}
