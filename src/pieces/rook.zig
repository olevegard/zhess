const std = @import("std");
const testing = @import("testing.zig");
const util = @import("util.zig");

const vertical: u64 = 0b10000000_10000000_10000000_10000000_10000000_10000000_10000000_10000000;
const horizontal: u64 = 0b11111111_00000000_00000000_00000000_00000000_00000000_00000000_00000000;

pub const max: u64 = std.math.pow(u64, 2, 63);

const all_bits_set: u8 = 0b1111_1111;
const first_pow_on_row: u8 = 0b1000_0000;
const last_pow_on_row: u8 = 0b0000_0001;

pub fn movement_short(rook_pos: u6, enemies: u64) u64 {
    // This aproach works if we decide to move away from using index to specify a position
    // Get the bitfield post of the rook
    // const rook_pos_bf: u64 = util.index_to_bitfield_pos(rook_pos);
    // Move it to within single byte
    // const rook_pos_row: u8 = @intCast(rook_pos_bf >> row);

    // Find the col of the rook

    const col: u3 = @intCast(rook_pos & 0b111);
    const rook_pos_row: u8 = @intCast(first_pow_on_row >> col); // @intCast(rook_pos_bf >> row);

    const row: u6 = (7 - (rook_pos >> 3)) * 8;

    // Move the mask to the correct row
    const board_row_mask: u64 = std.math.shl(u64, all_bits_set, row);

    // Apply mask, removing pieces that aren't on this line
    const board_row_masked: u64 = enemies & board_row_mask;

    // Shift the row of piece so that they fit within a single byte
    const board_row: u8 = @intCast(board_row_masked >> row);

    _ = movement_row_short(rook_pos_row, board_row);

    return 0;
}

test movement_row_short {
    std.testing.log_level = .debug;
    var list = std.ArrayList([3]u64).init(std.testing.allocator);
    defer list.deinit();

    // const a: [3]u64 = ;

    try list.append([3]u64{ 0, 0, 0b01111111 });
    try list.append([3]u64{ 0, 0b01000000, 0b01000000 });
    try list.append([3]u64{ 0, 0b01100000, 0b01000000 });
    try list.append([3]u64{ 0, 0b00110000, 0b01100000 });
    try list.append([3]u64{ 0, 0b00101000, 0b01100000 });
    try list.append([3]u64{ 0, 0b00100100, 0b01100000 });
    try list.append([3]u64{ 0, 0b00111100, 0b01100000 });
    try list.append([3]u64{ 0, 0b00001100, 0b01111000 });
    try list.append([3]u64{ 0, 0b00001010, 0b01111000 });

    // Right
    try list.append([3]u64{ 0, 0b00000000, 0b11111110 });
    try list.append([3]u64{ 0, 0b00000010, 0b00000010 });

    try testing.expectBitBoardArray_En(
        list,
        movement_row_short,
    );
}
pub fn movement_row_short(rook_pos: u8, enemies: u8) u8 {
    const right_mask: u8 = rook_pos - 1;
    const right_enemies: u8 = enemies & right_mask;

    var right_leading_zeros: u8 = @clz(right_enemies);
    right_leading_zeros -= @intFromBool(right_enemies == 0);

    const rightmost_pos: u8 = std.math.shr(
        u8,
        // 0000 0001
        first_pow_on_row,
        right_leading_zeros,
    );

    // right_mask contains all pieces to the right of the player
    // ~right_mask gives us the opppsite which includes the player
    // << 1 makes sure we move the mask so that it's to the left of the player
    const left_mask: u8 = ~right_mask << 1;
    const left_enemies: u8 = enemies & left_mask;

    // We need to find the 1 closest to the player
    // here the player is on the right side so we need trailing zeros
    var left_trailing_zero: u8 = @ctz(left_enemies);

    // If there are no enemies, trailing zeros will be 8
    // Which means we would shift the bit by 8, turning it into 0000 0000
    // Subtracting 1 instead gives us the 7, shifting the bit to 1000 0000
    left_trailing_zero -= @intFromBool(left_enemies == 0);

    const leftmost_pos: u8 = std.math.shl(
        u8,
        // 0000 0001
        last_pow_on_row,
        left_trailing_zero,
    );

    std.debug.print("Enemies    : {b:_>8}\n", .{enemies});
    std.debug.print("Rook pos   : {b:_>8}\n", .{rook_pos});

    const both: u8 = leftmost_pos | rightmost_pos;
    std.debug.print("Left|right : {b:_>8}\n", .{both});

    const movement: u8 = (leftmost_pos - rightmost_pos) | both;
    std.debug.print("movement   : {b:_>8}\n", .{movement});

    return movement;
}

pub fn generate_rook_moves(rook_pos: u6) u64 {
    const col = rook_pos & 7;
    const entire_col: u64 = vertical >> col;

    return util.strip_player_pos(entire_col, rook_pos);
}

pub fn generate_with_enemy(rook_pos: u6, enemies: u64) u64 {
    return with_enemy_col(rook_pos, enemies) | with_enemy_row(rook_pos, enemies);
}
pub fn with_enemy_col(rook_pos: u6, enemies: u64) u64 {
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

    // This will fill all cells between the first and last
    // So we use & full_col to separate out the cells we want
    return (top_en -% bottom_en) & full_col;
}

pub fn strip_lower(in: u64) u64 {
    var result: u64 = 1;

    while (in >= result) {
        result *= 2;
    }

    return result >> 1;
}

pub fn strip_lower_test(in: u64, target: u64) void {
    var result: u64 = 1;

    while (in >= result) {
        result *= 2;
    }

    result /= 2;

    // n = 0011 0101
    // s1 = >> 0001 1010
    //
    //       1111 1111
    // -     0001 1010
    //s1m =  1110 0101
    // n & s1
    //
    //  0011 0101
    // ~0001 1010
    //  0010
    //
    //
    //  in = 0100 1010
    //  s1 = 0010 0101
    // ns1 = 1101 1010
    // ns1 & in = 0100 1010
    // & ns1 0100 000
    //
    //  s1 = 1001 0100
    // ns1 = 0110 1011

    //s1_m_max = 1110 0101
    // s1      = 0001 1010
    // not-s1  = 1110 0101
    // n       = 0011 0101
    //
    // 0010 1110 = 32 + 8 + 4 +2  = 46
    // 127 - 46 = 81
    // 1001 0001 = 82
    // 0010 1110 = 46
    // 127 = 121 = 6
    // in  = 0111 1001 == 64 + 32 + 16 = 8 + 1 = 121
    //  s1 = 0011 1100 = 60
    //  s1 = 0000 0011 = 3
    //  s2 = 0011 1011 = 121 - 60 = 61
    //
    //
    // >> 0001 1110 ~ 1110 0001
    //
    // >> 0011 1100 ~ 1100 0011
    // >> 1111 0010 ~ 0000 1101
    // const result: u64 = in & (~(in >> 1) & ~(in >> 2));
    //
    //n =  1110 0101
    //~n = 0001 1010
    //   = 1111 1111
    //s1 = 0111 1111
    //
    //or = 0111 0000
    //
    //

    //const shift = in >> 1;
    //const shift_not = ~shift;
    //const shift_or = shift ^ shift_not;
    //const xor = in ^ in;
    //const result: u64 = ~xor;

    //  in = 0100 1110
    //  s1 = 0010 0111
    //  s1 = 1001 1000
    //       1 11 1111
    //
    // ns1 = 1101 1010
    // ns1 & in = 0100 1010
    // & ns1 0100 000
    // in       1000 1110
    // s1       0100 0111
    // not s1   1011 1000
    //<not s1   0111 0000
    //
    // in & ~sl -> significant bit is 1

    if (result == target) {
        std.debug.print("Correct!\n", .{});
        return;
    }

    std.debug.print("Incorrect got {d} wanted {d}!\n", .{ result, target });

    // std.debug.print("NOT Correct!\n", .{});
    // util.print_u64("in           ", in);
    // util.print_u64("shift        ", shift);
    // util.print_u64("shift not    ", shift_not);
    // util.print_u64("shift not  or", shift_or);
    // util.print_u64("xor          ", xor);
    // util.print_u64("not xor      ", ~xor);
    // util.print_u64("result       ", result);

    // const max = 255;
    //const s1_m_max = max - s1;

    // util.print_u64("max ", max);
    // util.print_u64("s1 - max ", s1_m_max);

    //util.print_u64("in >> 2 ", in >> 2);
    //util.print_u64("~1 & ~2 ", ~(in >> 1) & ~(in >> 2));
    //util.print_u64("Result  ", result);
}
pub fn with_enemy_row(rook_pos: u6, enemies: u64) u64 {
    const row: u6 = (rook_pos >> 3) * 8;
    const full_row = horizontal >> row;
    std.debug.print("Row {d}\n", .{(row -% 1) & vertical});

    // Need to isolate the enemies on this row
    const enemies_on_row = (enemies & full_row);
    util.print_u64("Both en  ", enemies_on_row);

    const rook_pos_bf = util.index_to_bitfield_pos(rook_pos);
    util.print_u64("Rookpos  ", rook_pos_bf);

    const left_of_rook = (max - rook_pos_bf) << 1;
    util.print_u64("Rook left", left_of_rook);

    var right_en = (enemies_on_row -% rook_pos_bf) & enemies_on_row;
    util.print_u64("Righ 1 ", right_en);

    // Make sure we only consider the leftmost enemy on the right side
    right_en = strip_lower(right_en);

    util.print_u64("Righ 2 ", right_en);

    // In cases with two pieces on the left side
    // right_en will be on the left side of the rook
    right_en &= ~left_of_rook;

    util.print_u64("Righ 3 ", right_en);

    // A dorky way of avoiding branches
    const end = util.index_to_bitfield_pos(row + 7);
    right_en += @intFromBool(right_en == 0) * end;

    util.print_u64("Righ 4 ", right_en);

    // If rook is at the end of the row, set end to 0
    right_en *= @intFromBool(rook_pos_bf != end);

    util.print_u64("Righ 5 ", right_en);

    // Find each end of movement range
    // First we need to separate pawns on the left and right
    // We do this by subtracting the player pos from the enemy mask
    // This will either unset any mask of left pawns, or overflow
    // The -% means subtraction with overflow
    // After the subtraction the bits that are lower than that of the player will have changed
    // We then do & enemies_on_row to make sure only the bits of the actual pawns are set

    // 128
    //    o x x _ _ _ _ _
    //     64 32

    // Now we know the pos of the right pawn, we can simply subtract that from the enemies mask
    // to unset to lower masks and thus get the position of the left pawn
    var left_en = (enemies_on_row -% right_en) & enemies_on_row;
    util.print_u64("Left 1 ", left_en);

    // Need to use -% here to not underflowing when row = 0
    const start = util.index_to_bitfield_pos(row -% 1);
    left_en += @intFromBool(left_en == 0 and row > 0) * start;

    util.print_u64("Left 2 ", left_en);

    if (right_en > 0 and left_en > 0) {
        left_en = left_en & ~(right_en - 1);
    }

    util.print_u64("Left 3 ", left_en);

    // This works, but uses branches
    //if (right_en == 0) {
    //    const end = util.index_to_bitfield_pos(47);
    //    right_en = end;
    //}

    //if (left_en == 0) {
    //    const start = util.index_to_bitfield_pos(39);
    //    left_en = start;
    //}
    //
    // std.debug.print("{s}\n", .{util.print_u64(left_en)});
    // std.debug.print("Row {d}\n", .{(row -% 1) & vertical});

    util.print_u64("Both en", left_en | right_en);

    // return left_en -% right_en & full_row;

    return util.strip_player_pos(left_en -% right_en & full_row, rook_pos);
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

test with_enemy_row {
    std.testing.log_level = .debug;
    var list = std.ArrayList([3]u64).init(std.testing.allocator);
    defer list.deinit();

    // const a: [3]u64 = ;

    try list.append([3]u64{ 56, 0, 0b01111111 });
    try list.append([3]u64{ 56, 0b01000000, 0b01000000 });
    try list.append([3]u64{ 56, 0b01100000, 0b01000000 });
    try list.append([3]u64{ 56, 0b00110000, 0b01100000 });
    try list.append([3]u64{ 56, 0b00101000, 0b01100000 });
    try list.append([3]u64{ 56, 0b00100100, 0b01100000 });
    try list.append([3]u64{ 56, 0b00111100, 0b01100000 });
    try list.append([3]u64{ 56, 0b00001100, 0b01111000 });
    try list.append([3]u64{ 56, 0b00001010, 0b01111000 });

    // Right
    try list.append([3]u64{ 63, 0b00000000, 0b11111110 });
    try list.append([3]u64{ 63, 0b00000010, 0b00000010 });

    try testing.expectBitBoardArray_En(
        list,
        with_enemy_row,
    );
}

// test generate_rook_moves {
//  std.testing.log_level = .debug;

//  try testing.expectBitBoardArray(
//      [64]u64{
//          0b01111111_10000000_10000000_10000000_10000000_10000000_10000000_10000000,
//          0b10111111_01000000_01000000_01000000_01000000_01000000_01000000_01000000,
//          0b11011111_00100000_00100000_00100000_00100000_00100000_00100000_00100000,
//          0b11101111_00010000_00010000_00010000_00010000_00010000_00010000_00010000,
//          0b11110111_00001000_00001000_00001000_00001000_00001000_00001000_00001000,
//          0b11111011_00000100_00000100_00000100_00000100_00000100_00000100_00000100,
//          0b11111101_00000010_00000010_00000010_00000010_00000010_00000010_00000010,
//          0b11111110_00000001_00000001_00000001_00000001_00000001_00000001_00000001,
//          0b10000000_01111111_10000000_10000000_10000000_10000000_10000000_10000000,
//          0b01000000_10111111_01000000_01000000_01000000_01000000_01000000_01000000,
//          0b00100000_11011111_00100000_00100000_00100000_00100000_00100000_00100000,
//          0b00010000_11101111_00010000_00010000_00010000_00010000_00010000_00010000,
//          0b00001000_11110111_00001000_00001000_00001000_00001000_00001000_00001000,
//          0b00000100_11111011_00000100_00000100_00000100_00000100_00000100_00000100,
//          0b00000010_11111101_00000010_00000010_00000010_00000010_00000010_00000010,
//          0b00000001_11111110_00000001_00000001_00000001_00000001_00000001_00000001,
//          0b10000000_10000000_01111111_10000000_10000000_10000000_10000000_10000000,
//          0b01000000_01000000_10111111_01000000_01000000_01000000_01000000_01000000,
//          0b00100000_00100000_11011111_00100000_00100000_00100000_00100000_00100000,
//          0b00010000_00010000_11101111_00010000_00010000_00010000_00010000_00010000,
//          0b00001000_00001000_11110111_00001000_00001000_00001000_00001000_00001000,
//          0b00000100_00000100_11111011_00000100_00000100_00000100_00000100_00000100,
//          0b00000010_00000010_11111101_00000010_00000010_00000010_00000010_00000010,
//          0b00000001_00000001_11111110_00000001_00000001_00000001_00000001_00000001,
//          0b10000000_10000000_10000000_01111111_10000000_10000000_10000000_10000000,
//          0b01000000_01000000_01000000_10111111_01000000_01000000_01000000_01000000,
//          0b00100000_00100000_00100000_11011111_00100000_00100000_00100000_00100000,
//          0b00010000_00010000_00010000_11101111_00010000_00010000_00010000_00010000,
//          0b00001000_00001000_00001000_11110111_00001000_00001000_00001000_00001000,
//          0b00000100_00000100_00000100_11111011_00000100_00000100_00000100_00000100,
//          0b00000010_00000010_00000010_11111101_00000010_00000010_00000010_00000010,
//          0b00000001_00000001_00000001_11111110_00000001_00000001_00000001_00000001,
//          0b10000000_10000000_10000000_10000000_01111111_10000000_10000000_10000000,
//          0b01000000_01000000_01000000_01000000_10111111_01000000_01000000_01000000,
//          0b00100000_00100000_00100000_00100000_11011111_00100000_00100000_00100000,
//          0b00010000_00010000_00010000_00010000_11101111_00010000_00010000_00010000,
//          0b00001000_00001000_00001000_00001000_11110111_00001000_00001000_00001000,
//          0b00000100_00000100_00000100_00000100_11111011_00000100_00000100_00000100,
//          0b00000010_00000010_00000010_00000010_11111101_00000010_00000010_00000010,
//          0b00000001_00000001_00000001_00000001_11111110_00000001_00000001_00000001,
//          0b10000000_10000000_10000000_10000000_10000000_01111111_10000000_10000000,
//          0b01000000_01000000_01000000_01000000_01000000_10111111_01000000_01000000,
//          0b00100000_00100000_00100000_00100000_00100000_11011111_00100000_00100000,
//          0b00010000_00010000_00010000_00010000_00010000_11101111_00010000_00010000,
//          0b00001000_00001000_00001000_00001000_00001000_11110111_00001000_00001000,
//          0b00000100_00000100_00000100_00000100_00000100_11111011_00000100_00000100,
//          0b00000010_00000010_00000010_00000010_00000010_11111101_00000010_00000010,
//          0b00000001_00000001_00000001_00000001_00000001_11111110_00000001_00000001,
//          0b10000000_10000000_10000000_10000000_10000000_10000000_01111111_10000000,
//          0b01000000_01000000_01000000_01000000_01000000_01000000_10111111_01000000,
//          0b00100000_00100000_00100000_00100000_00100000_00100000_11011111_00100000,
//          0b00010000_00010000_00010000_00010000_00010000_00010000_11101111_00010000,
//          0b00001000_00001000_00001000_00001000_00001000_00001000_11110111_00001000,
//          0b00000100_00000100_00000100_00000100_00000100_00000100_11111011_00000100,
//          0b00000010_00000010_00000010_00000010_00000010_00000010_11111101_00000010,
//          0b00000001_00000001_00000001_00000001_00000001_00000001_11111110_00000001,
//          0b10000000_10000000_10000000_10000000_10000000_10000000_10000000_01111111,
//          0b01000000_01000000_01000000_01000000_01000000_01000000_01000000_10111111,
//          0b00100000_00100000_00100000_00100000_00100000_00100000_00100000_11011111,
//          0b00010000_00010000_00010000_00010000_00010000_00010000_00010000_11101111,
//          0b00001000_00001000_00001000_00001000_00001000_00001000_00001000_11110111,
//          0b00000100_00000100_00000100_00000100_00000100_00000100_00000100_11111011,
//          0b00000010_00000010_00000010_00000010_00000010_00000010_00000010_11111101,
//          0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_11111110,
//      },
//      generate_rook_moves,
//  );
// }
