const std = @import("std");
const expect = @import("std").testing.expect;
const expectError = @import("std").testing.expectError;

const Set = std.bit_set.IntegerBitSet(100);

const Card = struct {
    id: u16,
    winning: Set,
    have: Set,
};

fn parseSet(buffer: []const u8) !Set {
    var set = Set.initEmpty();
    var wordsIter = std.mem.tokenizeScalar(u8, buffer, ' ');
    while (wordsIter.next()) |word| {
        // std.debug.print("word = {s}\n", .{word});
        var n = try std.fmt.parseInt(u8, word, 10);
        if (n < 1 or n > 99) {
            return error.NumberOutOfRange;
        }
        set.set(n);
    }
    return set;
}

test "parseSet" {
    try expect((try parseSet("1 2 99")).count() == 3);
    try expectError(error.NumberOutOfRange, parseSet("1 2 100"));
}

fn parseCard(buffer: []const u8) !Card {
    if (!std.mem.startsWith(u8, buffer, "Card ")) {
        return error.WrongPrefix;
    }
    const startPos = std.mem.indexOfNonePos(u8, buffer, 5, " ") orelse return error.NoValues;
    const colonPos = std.mem.indexOf(u8, buffer, ": ") orelse return error.MissingColon;
    const pipePos = std.mem.indexOf(u8, buffer, " | ") orelse return error.MissingPipe;
    return Card{
        .id = try std.fmt.parseInt(u16, buffer[startPos..colonPos], 10),
        .winning = try parseSet(buffer[colonPos + 2 .. pipePos]),
        .have = try parseSet(buffer[pipePos + 3 ..]),
    };
}

test "parseCard" {
    const card = try parseCard("Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53");
    try expect(card.id == 1);
    try expect(card.winning.count() == 5);
    try expect(card.winning.isSet(41));
    try expect(card.winning.isSet(48));
    try expect(card.winning.isSet(83));
    try expect(card.winning.isSet(86));
    try expect(card.winning.isSet(17));
    try expect(card.have.count() == 8);
    try expect(card.have.isSet(83));
    try expect(card.have.isSet(86));
    try expect(card.have.isSet(6));
    try expect(card.have.isSet(31));
    try expect(card.have.isSet(17));
    try expect(card.have.isSet(9));
    try expect(card.have.isSet(48));
    try expect(card.have.isSet(53));
    _ = try parseCard("Card    1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53");
}

fn parse(cardsList: *std.ArrayList(Card), input: []const u8) !void {
    var linesIter = std.mem.splitScalar(u8, input, '\n');
    while (linesIter.next()) |line| {
        try cardsList.append(try parseCard(line));
    }
}

fn wins(card: Card) u8 {
    const winSet = card.winning.intersectWith(card.have);
    return @intCast(winSet.count());
}

test "wins" {
    try expect(wins(try parseCard("Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53")) == 4);
    try expect(wins(try parseCard("Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36")) == 0);
}

fn score(card: Card) u16 {
    const w = wins(card);
    return if (w == 0) 0 else @as(u16, 1) << @intCast(w - 1);
}

test "score" {
    try expect(score(try parseCard("Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53")) == 8);
    try expect(score(try parseCard("Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36")) == 0);
}

fn part1(cards: []const Card) !void {
    var sum: u16 = 0;
    for (cards) |card| {
        sum += score(card);
    }
    std.debug.print("{d}\n", .{sum});
}

fn copies(winsSlice: []const u16) u32 {
    var copiesArray: [1024]u32 = undefined;
    for (0..winsSlice.len) |i| {
        copiesArray[i] = 1;
    }
    var sum: u32 = 0;
    for (winsSlice, 0..) |w, i| {
        for (i + 1..i + w + 1) |j| {
            copiesArray[j] += copiesArray[i];
        }
        sum += copiesArray[i];
        // std.debug.print("{d} {d} {d}\n", .{ w, sum, copiesSlice });
    }
    return sum;
}

test "copies" {
    try expect((try copies(&[_]u16{ 4, 2, 2, 1, 0, 0 })) == 30);
}

fn part2(cards: []const Card) !void {
    var winsArray: [1024]u16 = undefined;
    for (cards, 0..) |card, i| {
        winsArray[i] = wins(card);
    }
    std.debug.print("{d}\n", .{copies(winsArray[0..cards.len])});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var buffer: [1 << 16]u8 = undefined;
    const bytes_read = try file.readAll(&buffer);
    const input = buffer[0..bytes_read];
    var cardsList = std.ArrayList(Card).init(allocator);
    defer cardsList.deinit();
    try parse(&cardsList, input);
    try part1(cardsList.items);
    try part2(cardsList.items);
}
