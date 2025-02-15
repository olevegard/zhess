const std = @import("std");
const testing = @import("testing.zig");
const util = @import("util.zig");

const vertical: u64 = 0b10000000_10000000_10000000_10000000_10000000_10000000_10000000_10000000;
const horizontal: u64 = 0b11111111_00000000_00000000_00000000_00000000_00000000_00000000_00000000;

pub fn generate_rook_moves(rook_pos: u6) u64 {
    const col = rook_pos & 7;
    const entire_col: u64 = vertical >> col;

    return util.strip_player_pos(entire_col, rook_pos);
}

pub fn generate_with_enemy_vertical(rook_pos: u6, enemies: u64) u64 {
    // Need to isolate the enemies on this col
    const col: u6 = rook_pos & 7;
    const full_col = vertical >> col;
    const enemies_on_col = (enemies & full_col);

    const rook_pos_bf = util.index_to_bitfield_pos(rook_pos);

    var bottom_en = (enemies_on_col -% rook_pos_bf) & enemies_on_col;
    var top_en = (enemies_on_col -% bottom_en) & enemies_on_col;

    // A dorky way of avoiding branches
    const end = util.index_to_bitfield_pos(col + 56);
    bottom_en += @intFromBool(bottom_en == 0) * end;

    // Need to use -% here to not underflowing when col = 0
    const start = util.index_to_bitfield_pos(col -% 1);
    top_en += @intFromBool(top_en == 0 and col > 0) * start;

    std.debug.print("col {d}\n", .{col});
    std.debug.print("Oppon pieces {b:0>64}\n", .{enemies_on_col});
    std.debug.print("Leftt pieces {b:0>64}\n", .{top_en});
    std.debug.print("Right pieces {b:0>64}\n", .{bottom_en});

    return (top_en -% bottom_en) & full_col;
}

pub fn generate_with_enemy(rook_pos: u6, enemies: u64) u64 {
    // Need to isolate the enemies on this row
    const row: u6 = (rook_pos >> 3) * 8;
    const full_row = horizontal >> row;
    const enemies_on_row = (enemies & full_row);

    const rook_pos_bf = util.index_to_bitfield_pos(rook_pos);

    // Find each end of movement range
    // First we need to separate pawns on the left and right
    // We do this by subtracting the player pos from the enemy mask
    // This will either unset any mask of left pawns, or overflow
    // The -% means subtraction with overflow
    // After the subtraction the bits that are lower than that of the player will have changed
    // We then do & enemies_on_row to make sure only the bits of the actual pawns are set
    var right_en = (enemies_on_row -% rook_pos_bf) & enemies_on_row;

    // Now we know the pos of the right pawn, we can simply subtract that from the enemies mask
    // to unset to lower masks and thus get the position of the left pawn
    var left_en = (enemies_on_row -% right_en) & enemies_on_row;

    // This works, but uses branches
    //if (right_en == 0) {
    //    const end = util.index_to_bitfield_pos(47);
    //    right_en = end;
    //}

    //if (left_en == 0) {
    //    const start = util.index_to_bitfield_pos(39);
    //    left_en = start;
    //}

    // A dorky way of avoiding branches
    const end = util.index_to_bitfield_pos(row + 7);
    right_en += @intFromBool(right_en == 0) * end;

    // Need to use -% here to not underflowing when row = 0
    const start = util.index_to_bitfield_pos(row -% 1);
    left_en += @intFromBool(left_en == 0 and row > 0) * start;

    std.debug.print("Row {d}\n", .{(row -% 1) & vertical});
    std.debug.print("Oppon pieces {b:0>64}\n", .{enemies_on_row});
    std.debug.print("Leftt pieces {b:0>64}\n", .{left_en});
    std.debug.print("Right pieces {b:0>64}\n", .{right_en});

    return left_en -% right_en;
}

const left: u64 = 0b10000000_10000000_10000000_10000000_10000000_10000000_10000000_10000000;
const right: u64 = 0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_00000001;
const top: u64 = 0b11111111_00000000_00000000_00000000_00000000_00000000_00000000_00000000;
const bottom: u64 = 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_11111111;

// An alternative, slightly less dorky, way of generating the moves
fn _generate_with_enemy(rook_pos: u6, enemies: u64) u64 {
    const rook_pos_bf = util.index_to_bitfield_pos(rook_pos);
    // Works by starting at player pos and moving one sqaure at the time in each direction
    // stopping when it either reaches and edge or an enemy
    var row_left = rook_pos_bf;
    const left_limits = enemies | left;
    while ((row_left & left_limits) == 0) {
        row_left |= row_left << 1;
    }

    var row_right = rook_pos_bf;
    const right_limits = enemies | right;
    while ((row_right & right_limits) == 0) {
        row_right |= row_right >> 1;
    }

    var col_top = rook_pos_bf;
    const top_limits = enemies | top;
    while ((col_top & top_limits) == 0) {
        col_top |= col_top << 8;
    }

    var col_bottom = rook_pos_bf;
    const bottom_limits = enemies | bottom;
    while ((col_bottom & bottom_limits) == 0) {
        col_bottom |= col_bottom >> 8;
    }

    return row_right | row_left | col_top | col_bottom;
}
test generate_rook_moves {
    std.testing.log_level = .debug;

    try testing.expectBitBoardArray(
        [64]u64{
            0b01111111_10000000_10000000_10000000_10000000_10000000_10000000_10000000,
            0b10111111_01000000_01000000_01000000_01000000_01000000_01000000_01000000,
            0b11011111_00100000_00100000_00100000_00100000_00100000_00100000_00100000,
            0b11101111_00010000_00010000_00010000_00010000_00010000_00010000_00010000,
            0b11110111_00001000_00001000_00001000_00001000_00001000_00001000_00001000,
            0b11111011_00000100_00000100_00000100_00000100_00000100_00000100_00000100,
            0b11111101_00000010_00000010_00000010_00000010_00000010_00000010_00000010,
            0b11111110_00000001_00000001_00000001_00000001_00000001_00000001_00000001,
            0b10000000_01111111_10000000_10000000_10000000_10000000_10000000_10000000,
            0b01000000_10111111_01000000_01000000_01000000_01000000_01000000_01000000,
            0b00100000_11011111_00100000_00100000_00100000_00100000_00100000_00100000,
            0b00010000_11101111_00010000_00010000_00010000_00010000_00010000_00010000,
            0b00001000_11110111_00001000_00001000_00001000_00001000_00001000_00001000,
            0b00000100_11111011_00000100_00000100_00000100_00000100_00000100_00000100,
            0b00000010_11111101_00000010_00000010_00000010_00000010_00000010_00000010,
            0b00000001_11111110_00000001_00000001_00000001_00000001_00000001_00000001,
            0b10000000_10000000_01111111_10000000_10000000_10000000_10000000_10000000,
            0b01000000_01000000_10111111_01000000_01000000_01000000_01000000_01000000,
            0b00100000_00100000_11011111_00100000_00100000_00100000_00100000_00100000,
            0b00010000_00010000_11101111_00010000_00010000_00010000_00010000_00010000,
            0b00001000_00001000_11110111_00001000_00001000_00001000_00001000_00001000,
            0b00000100_00000100_11111011_00000100_00000100_00000100_00000100_00000100,
            0b00000010_00000010_11111101_00000010_00000010_00000010_00000010_00000010,
            0b00000001_00000001_11111110_00000001_00000001_00000001_00000001_00000001,
            0b10000000_10000000_10000000_01111111_10000000_10000000_10000000_10000000,
            0b01000000_01000000_01000000_10111111_01000000_01000000_01000000_01000000,
            0b00100000_00100000_00100000_11011111_00100000_00100000_00100000_00100000,
            0b00010000_00010000_00010000_11101111_00010000_00010000_00010000_00010000,
            0b00001000_00001000_00001000_11110111_00001000_00001000_00001000_00001000,
            0b00000100_00000100_00000100_11111011_00000100_00000100_00000100_00000100,
            0b00000010_00000010_00000010_11111101_00000010_00000010_00000010_00000010,
            0b00000001_00000001_00000001_11111110_00000001_00000001_00000001_00000001,
            0b10000000_10000000_10000000_10000000_01111111_10000000_10000000_10000000,
            0b01000000_01000000_01000000_01000000_10111111_01000000_01000000_01000000,
            0b00100000_00100000_00100000_00100000_11011111_00100000_00100000_00100000,
            0b00010000_00010000_00010000_00010000_11101111_00010000_00010000_00010000,
            0b00001000_00001000_00001000_00001000_11110111_00001000_00001000_00001000,
            0b00000100_00000100_00000100_00000100_11111011_00000100_00000100_00000100,
            0b00000010_00000010_00000010_00000010_11111101_00000010_00000010_00000010,
            0b00000001_00000001_00000001_00000001_11111110_00000001_00000001_00000001,
            0b10000000_10000000_10000000_10000000_10000000_01111111_10000000_10000000,
            0b01000000_01000000_01000000_01000000_01000000_10111111_01000000_01000000,
            0b00100000_00100000_00100000_00100000_00100000_11011111_00100000_00100000,
            0b00010000_00010000_00010000_00010000_00010000_11101111_00010000_00010000,
            0b00001000_00001000_00001000_00001000_00001000_11110111_00001000_00001000,
            0b00000100_00000100_00000100_00000100_00000100_11111011_00000100_00000100,
            0b00000010_00000010_00000010_00000010_00000010_11111101_00000010_00000010,
            0b00000001_00000001_00000001_00000001_00000001_11111110_00000001_00000001,
            0b10000000_10000000_10000000_10000000_10000000_10000000_01111111_10000000,
            0b01000000_01000000_01000000_01000000_01000000_01000000_10111111_01000000,
            0b00100000_00100000_00100000_00100000_00100000_00100000_11011111_00100000,
            0b00010000_00010000_00010000_00010000_00010000_00010000_11101111_00010000,
            0b00001000_00001000_00001000_00001000_00001000_00001000_11110111_00001000,
            0b00000100_00000100_00000100_00000100_00000100_00000100_11111011_00000100,
            0b00000010_00000010_00000010_00000010_00000010_00000010_11111101_00000010,
            0b00000001_00000001_00000001_00000001_00000001_00000001_11111110_00000001,
            0b10000000_10000000_10000000_10000000_10000000_10000000_10000000_01111111,
            0b01000000_01000000_01000000_01000000_01000000_01000000_01000000_10111111,
            0b00100000_00100000_00100000_00100000_00100000_00100000_00100000_11011111,
            0b00010000_00010000_00010000_00010000_00010000_00010000_00010000_11101111,
            0b00001000_00001000_00001000_00001000_00001000_00001000_00001000_11110111,
            0b00000100_00000100_00000100_00000100_00000100_00000100_00000100_11111011,
            0b00000010_00000010_00000010_00000010_00000010_00000010_00000010_11111101,
            0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_11111110,
        },
        generate_rook_moves,
    );
}
