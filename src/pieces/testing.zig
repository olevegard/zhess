const std = @import("std");
const util = @import("util.zig");

pub fn expectBitBoardArray(all_correct_results: [64]u64, gen_func: fn (pos: u6) u64) !void {
    for (0.., all_correct_results) |i, correct_possible_moves| {
        if (!expectBitBoardEqual(gen_func(@intCast(i)), correct_possible_moves)) {
            std.debug.print("Index was {d}\n", .{i});
            try std.testing.expect(false);
        }
    }
}

pub fn expectBitBoardArray_En(all_cases: std.ArrayList([3]u64), gen_func: fn (pos: u6, enemies: u64) u64) !void {
    for (all_cases.items) |case| {
        const actual = gen_func(@intCast(case[0] % 64), case[1]);
        if (!expectBitBoardEqual(actual, case[2])) {
            std.debug.print("Test failed!\nPlayer pos {d}\n", .{case[0]});
            util.print_u64("Enemies ", case[1]);
            util.print_u64("Expecte ", case[2]);
            util.print_u64("ACtual  ", actual);

            try std.testing.expect(false);
        }
    }
}

pub fn expectBitBoardEqual(actual: u64, expected: u64) bool {
    if (actual == expected) {
        return true;
    }

    std.debug.print("Bit boards did not match!\n", .{});
    compare_bit_boards(actual, expected);

    return false;
}

pub fn compare_bit_boards(board1: u64, board2: u64) void {
    const hed_line = " Actual               Expected           ";
    const fst_line = " |A|B|C|D|E|F|G|H|    |A|B|C|D|E|F|G|H|\n";

    // First row should how have a leading newline
    std.debug.print("{s}\n", .{hed_line});
    std.debug.print("{s}", .{fst_line});

    var p1 = std.math.pow(u64, 2, 63);
    var p2 = std.math.pow(u64, 2, 63);
    for (0..8) |i| {
        std.debug.print("{d}", .{8 - i});
        for (0..8) |_| {
            if ((board1 & p1) > 0) {
                std.debug.print("|x", .{});
            } else {
                std.debug.print("|_", .{});
            }

            p1 >>= 1;
        }

        std.debug.print("|    |", .{});
        for (0..8) |_| {
            if ((board2 & p2) > 0) {
                std.debug.print("x|", .{});
            } else {
                std.debug.print("_|", .{});
            }

            p2 >>= 1;
        }
        std.debug.print("{d}\n", .{8 - i});
    }
}

pub fn compare_bit_boards_many(boards: [64]u64) void {
    const fst_line = "|A|B|C|D|E|F|G|H|";

    // First row should how have a leading newline

    for (0..8) |board_row| {
        for (0..8) |_| {
            std.debug.print(" {s}     ", .{fst_line});
        }

        std.debug.print("\n", .{});

        const board_chunk = boards[(board_row * 8) .. (board_row * 8) + 8];
        var p1 = std.math.pow(u64, 2, 63);
        for (0..8) |row| {
            for (0..8) |board_index| {
                std.debug.print("{d}", .{8 - row});
                for (0..8) |col| {
                    if ((board_chunk[board_index] & (p1 >> @intCast(col))) > 0) {
                        std.debug.print("|x", .{});
                    } else {
                        std.debug.print("|_", .{});
                    }
                }

                if (board_index < 7) {
                    std.debug.print("|    |", .{});
                } else {
                    std.debug.print("|", .{});
                }
            }

            p1 >>= 8;

            std.debug.print("\n", .{});
        }

        std.debug.print("\n\n", .{});
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
