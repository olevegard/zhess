const std = @import("std");

pub fn expectBitBoardEqual(actual: u64, expected: u64) void {
    if (actual == expected) {
        return;
    }

    std.debug.print("Bit boards did not match!", .{});
    compare_bit_boards(actual, expected);
}

pub fn compare_bit_boards(board1: u64, board2: u64) void {
    const fst_line = " |A|B|C|D|E|F|G|H|    |A|B|C|D|E|F|G|H|\n";

    // First row should how have a leading newline
    std.debug.print("{s}", .{fst_line});
    var p1 = board1;
    var p2 = board2;
    for (0..8) |i| {
        std.debug.print("{d}", .{i + 1});
        for (0..8) |_| {
            if ((p1 & 1) == 1) {
                std.debug.print("|x", .{});
            } else {
                std.debug.print("|_", .{});
            }

            p1 >>= 1;
        }

        std.debug.print("|    |", .{});
        for (0..8) |_| {
            if ((p2 & 1) == 1) {
                std.debug.print("x|", .{});
            } else {
                std.debug.print("_|", .{});
            }

            p2 >>= 1;
        }
        std.debug.print("{d}\n", .{i + 1});
    }
}

pub fn print_possible_moves(moves: u64, piece_pos: u64) void {
    // 123456789012345678901234567890123456789
    const sep_line = "|---|---|---|---|---|---|---|---|---|---|";
    const fst_line = "|   | A | B | C | D | E | F | G | H |   |";

    std.debug.print("{s}\n{s}\n{s}\n", .{ sep_line, fst_line, sep_line });

    var p = std.math.pow(u64, 2, 63);
    for (0..8) |i| {
        std.debug.print("| {d} ", .{8 - i});

        for (0..8) |j| {
            // std.debug.print("\np : {b}\nm : {b}\n{any}\n", .{ p, moves, moves & p });
            if (((i * 8) + j) == piece_pos) {
                std.debug.print("| o ", .{});
            } else if ((moves & p) > 1) {
                std.debug.print("| x ", .{});
            } else {
                std.debug.print("| _ ", .{});
            }

            p >>= 1;
        }

        std.debug.print("| {d} |\n{s}\n", .{ 8 - i, sep_line });
    }

    std.debug.print("{s}\n{s}\n", .{ fst_line, sep_line });
}
