const std = @import("std");

pub fn print_single_board_piece(board: u64) void {
    const b: [12]u64 = [12]u64{
        board,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
    };
    const board_pieces = render_board(b);
    print_board_pieces(board_pieces);
}

pub fn print_board(board: [12]u64) void {
    const board_pieces = render_board(board);
    print_board_pieces(board_pieces);
}
// Turns the board into a [64]u8 array
// with a letter for each piece or [no_piece] for empty
// This is probably needlessly hacky,
// but it serves as a way of getting used to using bitwise operators
fn render_board(board: [12]u64) [64]u8 {
    const piece_names = "PpRrNnBbQqKk";
    const no_piece = '_';

    // The letters for the pieces in each position
    // Creates an array of [64]u8 with items set to [no_piece]
    var board_pieces = [1]u8{no_piece} ** 64;

    // Has the bit for the current position set to 1, starting at a8
    // a8 = 100000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
    // b8 = 010000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
    // a7 = 000000000 10000000 00000000 00000000 00000000 00000000 00000000 00000000
    // ..
    // a1 = 000000000 00000000 00000000 00000000 00000000 00000000 00000000 10000000
    // h1 = 000000000 00000000 00000000 00000000 00000000 00000000 00000000 00000001
    // 2 ^ 63
    var mask: u64 = 0b10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000;

    // Loop through all positions
    for (0..64) |board_position| {
        // Loop through all pieces
        for (piece_names, 0..) |piece_letter, piece_index| {
            // Check if this bit mask has the bit for this position set
            if ((board[piece_index] & mask) > 0) {
                // Update the array
                board_pieces[board_position] = piece_letter;
                break;
            }
        }

        // We've found a piece or gone through all piece types
        // Shift the mask to point at the next position
        mask = mask >> 1;
    }

    return board_pieces;
}

fn print_board_pieces(board_pieces: [64]u8) void {
    // Prints the board in the following form :
    // |---|---|---|---|---|---|---|---|
    // | r | n | b | k | q | b | n | r |
    // |---|---|---|---|---|---|---|---|
    // | p | p | p | p | p | p | p | p |
    // |---|---|---|---|---|---|---|---|
    // | - | - | - | - | - | - | - | - |
    // |---|---|---|---|---|---|---|---|
    // | - | - | - | - | - | - | - | - |
    // |---|---|---|---|---|---|---|---|
    // | - | - | - | - | - | - | - | - |
    // |---|---|---|---|---|---|---|---|
    // | - | - | - | - | - | - | - | - |
    // |---|---|---|---|---|---|---|---|
    // | P | P | P | P | P | P | P | P |
    // |---|---|---|---|---|---|---|---|
    // | R | N | B | K | Q | B | N | R |
    // |---|---|---|---|---|---|---|---|
    const sep_line = "|---|---|---|---|---|---|---|---|\n";

    // First row should how have a leading newline
    std.debug.print("{s}", .{sep_line});
    for (0.., board_pieces) |i, p| {
        std.debug.print("| {u} ", .{p});

        // Check if the last piece in a row
        // Which happens every 8th iteration1
        // Same as doing ( (i + 1) % 8) == 0
        if ((i & 7) == 7) {
            std.debug.print("|\n{s}", .{sep_line});
        }
    }
}
