const std = @import("std");

const rightSide: u64 = 0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_00000001;
const rightSide2: u64 = 0b00000011_00000011_00000011_00000011_00000011_00000011_00000011_00000011;

const leftSide: u64 = 0b10000000_10000000_10000000_10000000_10000000_10000000_10000000_10000000;
const leftSide2: u64 = 0b11000000_11000000_11000000_11000000_11000000_11000000_11000000_11000000;

const black_back_rank: u64 = 0b00000000_11111111_00000000_00000000_00000000_00000000_00000000_00000000;

const white_back_rank: u64 = 0b00000000_00000000_00000000_00000000_00000000_00000000_11111111_00000000;

pub fn generate_white_pawn_moves(pawn_pos: u6) u64 {
    var pattern: u64 = 0b10000000_00000000;

    // https://github.com/ziglang/zig/issues/6903
    const pawn_pos_shifted: u64 = @as(u64, 1) << (pawn_pos);
    if (pawn_pos_shifted & white_back_rank > 0) {
        pattern = 0b10000000_10000000;
    }
    pattern = pattern << 40;

    return pattern >> pawn_pos;
}

pub fn generate_black_pawn_moves(pawn_pos: u6) u64 {
    var pattern: u64 = 0b10000000_00000000;

    // https://github.com/ziglang/zig/issues/6903
    const pawn_pos_shifted: u64 = @as(u64, 1) << (pawn_pos);
    if (pawn_pos_shifted & black_back_rank > 0) {
        std.debug.print("Is back rank", .{});
        pattern = 0b10000000_10000000;
    }
    pattern = pattern << 32;

    return pattern; // >> pawn_pos;
}

// Taking a u6 means we can safely do bit shifts without having to cast
pub fn generateKnightMoves(knightPos: u6) u64 {
    // The basic way a king moves ( 1 square in each direction )
    var pattern: u64 = 0b01010000_10001000_00000000_10001000_01010000_00000000_00000000_00000000;

    // The pattern is for kings in position 9, the first spot in which the king can move in any direction

    const patternStartPos = 18;

    // Shift the pattern to match the position of the king
    if (knightPos >= patternStartPos) {
        pattern = pattern >> (knightPos - patternStartPos);
    } else {
        pattern = pattern << (patternStartPos - knightPos);
    }

    // https://github.com/ziglang/zig/issues/6903
    const knightPosShifted: u64 = @as(u64, 1) << (63 - knightPos);

    // Check if the king is on the left side of the board
    if (knightPosShifted & leftSide2 > 0) {
        // Make sure the king can't cross from the left side to the right
        pattern = pattern & ~rightSide2;
    }

    if (knightPosShifted & rightSide2 > 0) {
        pattern = pattern & ~leftSide2;
    }

    return pattern;
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

    if (kingPosShifted & rightSide > 0) {
        pattern = pattern & ~leftSide;
    }

    return pattern;
}
