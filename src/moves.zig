const std = @import("std");
const debug = @import("debug.zig");

const rightSide: u64 = 0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_00000001;
const rightSide2: u64 = 0b00000011_00000011_00000011_00000011_00000011_00000011_00000011_00000011;

const leftSide: u64 = 0b10000000_10000000_10000000_10000000_10000000_10000000_10000000_10000000;
const leftSide2: u64 = 0b11000000_11000000_11000000_11000000_11000000_11000000_11000000_11000000;

const white_back_rank: u64 = 0b00000000_11111111_00000000_00000000_00000000_00000000_00000000_00000000;

const diagonal_tl: u64 = 0b10000000_01000000_00100000_00010000_00001000_00000100_00000010_00000001;
const diagonal_tr: u64 = 0b00000001_00000010_00000100_00001000_00010000_00100000_01000000_10000000;

const vertical: u64 = 0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_00000001;
const horizontal: u64 = 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_11111111;

pub fn generate_queen_moves(queen_pos: u6) u64 {
    return generate_rook_moves(queen_pos) | generate_bishop_moves_12(queen_pos);
}
pub fn generate_rook_moves(rook_pos: u6) u64 {
    const col = rook_pos % 8;
    const row: u6 = rook_pos / 8;

    return (vertical << (col)) | (horizontal << (row * 8));
}
// TODO: Rook + queen
// TODO: make sure pawn can move 2 on first move
// TODO: Return separate array for capture moves?
pub fn generate_bishop_moves_12(bishop_pos: u6) u64 {
    // We don't need to check against the bounds of the table here since
    // the piece will be able to move infintely in all four directions
    const col = bishop_pos & 7;
    const row = bishop_pos >> 3;

    var diagonal_1: u64 = diagonal_tl;

    if (col > row) {
        diagonal_1 >>= (col - row) * 8;
    }

    if (col < row) {
        diagonal_1 <<= (row - col) * 8;
    }

    var diagonal_2: u64 = diagonal_tr;
    // Diagonal tr starts form top right, so the x axis needs to be flipped
    // Otherwise this is exactly the same as for the other diagonal
    const rel_col = 7 - col;

    if (rel_col > row) {
        diagonal_2 >>= (rel_col - row) * 8;
    }

    if (rel_col < row) {
        diagonal_2 <<= (row - rel_col) * 8;
    }

    return diagonal_1 | diagonal_2;
}

// This seems silly, but it allows us to do
// one << pawn_pos + 8
// Instead of
// @as(u64, 1) << pawn_pos - 8,
const one: u64 = 1;

// Includes being able to move 2 squares on the first move but not en passant
pub fn generate_white_pawn_moves(pawn_pos: u6) u64 {
    const row: u8 = pawn_pos >> 3;

    return switch (row) {
        // Pawn't can't move if it's on the first or last rank
        0 => 0,
        7 => 0,
        // 1 instead of 6 for black
        //  + 8 instead of -8
        6 => one << pawn_pos - 8 | one << pawn_pos - 16,
        else => one << pawn_pos - 8,
    };
}

// Includes being able to move 2 squares on the first move but not en passant
pub fn generate_black_pawn_moves(pawn_pos: u6) u64 {
    const row: u8 = pawn_pos >> 3;

    if (row == 0 or row == 7) {
        return 0;
    }

    // First valid move is the square ahead of the pawn
    var pattern = one << pawn_pos + 8;

    if (row == 1) {
        // If the move is on the first rank,
        // add a move saying it can move 1 extra space ahead
        pattern |= pattern << 8;
    }

    return pattern;
}

test generateKnightMoves {
    // std.testing.log_level = .debug;
    try std.testing.expect(
        generateKnightMoves(45) == 0b01010000_10001000_00000000_10001000_01010000_00000000_00000000_00000000,
    );

    try std.testing.expectEqual(
        generateKnightMoves(0),
        0b00000000_00000000_00000000_00000000_00000000_00000010_00000100_00000000,
    );

    try std.testing.expectEqual(
        generateKnightMoves(1),
        0b00000000_00000000_00000000_00000000_00000000_00000101_00001000_00000000,
    );

    try std.testing.expectEqual(
        generateKnightMoves(2),
        0b00000000_00000000_00000000_00000000_00000000_00001010_00010001_00000000,
    );

    try std.testing.expectEqual(
        generateKnightMoves(6),
        0b00000000_00000000_00000000_00000000_00000000_10100000_00010000_00000000,
    );

    try std.testing.expectEqual(
        generateKnightMoves(7),
        0b00000000_00000000_00000000_00000000_00000000_01000000_00100000_00000000,
    );

    debug.compare_bit_boards(
        generateKnightMoves(36),
        0b00000000_00101000_01000100_00000000_01000100_00101000_00000000_00000000,
    );
}

// Taking a u6 means we can safely do bit shifts without having to cast
pub fn generateKnightMoves(knight_pos: u6) u64 {
    // The basic way a knight moves ( 1 + 2 in perpendicilar directions)
    var pattern: u64 = 0b01010000_10001000_00000000_10001000_01010000_00000000_00000000_00000000;

    // The pattern is for knight in position 45, the first spot in which the knight can move in any direction
    const patternStartPos = 18;

    // Shift the pattern to match the position of the knight
    if (knight_pos > patternStartPos) {
        pattern = pattern >> (knight_pos - patternStartPos);
    }

    if (knight_pos < patternStartPos) {
        pattern = pattern << (patternStartPos - knight_pos);
    }

    // Check if the knight is place on the edge
    // If we only look at the lower 3 bits, we get the position regardless of the row number
    // -> 0-1 is on the left,
    // -> 2-5 is in the middle
    // -> 6-7 is on the right

    std.debug.print("{d} {d}\n", .{ knight_pos, knight_pos & 7 });
    return switch (knight_pos & 7) {
        // Unset all bits on left edge
        0 => pattern & 0b00111111_00111111_00111111_00111111_00111111_00111111_00111111_00111111,
        1 => pattern & 0b01111111_01111111_01111111_01111111_01111111_01111111_01111111_01111111,

        // Unset all bits on right edge
        6 => pattern & 0b11111110_11111110_11111110_11111110_11111110_11111110_11111110_11111110,
        7 => pattern & 0b11111100_11111100_11111100_11111100_11111100_11111100_11111100_11111100,
        else => pattern,
    };

    //return pattern;
}

// Taking a u6 means we can safely do bit shifts without having to cast
pub fn generateKingMoveBitboard(kingPos: u6) u64 {
    // The basic way a king moves ( 1 square in each direction )
    var pattern: u64 = 0b11100000_10100000_11100000_00000000_00000000_00000000_00000000_00000000;
    // The pattern is for kings in position 9, the first spot in which the king can move in any direction
    const patternStartPos = 9;

    // Shift the pattern to match the position of the king
    if (kingPos >= patternStartPos) {
        pattern = pattern >> (kingPos - patternStartPos);
    } else {
        pattern = pattern << (patternStartPos - kingPos);
    }

    // https://github.com/ziglang/zig/issues/6903
    const kingPosShifted: u64 = @as(u64, 1) << (63 - kingPos);

    // Check if the king is on the left side of the board
    if (kingPosShifted & leftSide > 0) {
        // Make sure the king can't cross from the left side to the right
        pattern = pattern & ~rightSide;
    }

    // Check if the king is on the right side of the board
    if (kingPosShifted & rightSide > 0) {
        // Make sure the king can't cross from the right side to the left
        pattern = pattern & ~leftSide;
    }

    // We don't need to check for top or bottom since top is begining of bitboard and bottom is the end
    // Meaning we would just shift the bits outside the range of the number

    return pattern;
}
