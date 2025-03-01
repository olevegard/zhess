const std = @import("std");
pub const debug = @import("debug.zig");
pub const lookup = @import("lookup.zig");
pub const bishops = @import("pieces/bishop.zig");
pub const knights = @import("pieces/knight.zig");
pub const pawns = @import("pieces/pawn.zig");
pub const kings = @import("pieces/king.zig");
pub const rooks = @import("pieces/rook.zig");
pub const queens = @import("pieces/queen.zig");
pub const util = @import("pieces/util.zig");

pub fn main() !void {
    // var board: [12]u64 = comptime create_board();
    // debug.print_board(board);

    // const piece_names = "PpRrNnBbQqKk";
    var moves: [7][64]u64 = undefined;

    // Use u6 as a loop counter, since the move generators usually take u6
    inline for (0..64) |position| {
        moves[0][position] = comptime pawns.generate_white_pawn_moves(position);
        moves[1][position] = comptime pawns.generate_black_pawn_moves(position);
        // moves[2][position] = rooks.generate_rook_moves(position);
        moves[3][position] = comptime knights.generate_knight_moves(position);
        @setEvalBranchQuota(2000);
        moves[4][position] = comptime bishops.generate_bishop_moves(position);
        // moves[5][position] = queens.generate_queen_moves(position);
        moves[6][position] = comptime kings.generate_king_moves(position);
        if (position == 63) break;
    }

    //                   1234567812345678123456781234567812345678123456781234567812345678
    // const d2: u64 = 0b0000000000001000000000000000000000000000000000000000000000000000;
    // const enemy: u64 = 0b0000000000001000000000000000000000000000000000000000100000000000;
    //                   12345678_12345678_12345678_12345678_12345678_12345678_12345678_12345678
    // const enemy: u64 = 0b00000000_01000000_00001000_00000000_01010000_01000100_00001000_00000010;
    // const enemy: u64 = 0b00000000_00000000_00001000_00000000_00000000_01000100_00001000_00000000;
    //  const enemy: u64 = 0b00000000_00000000_00001000_00000000_00000000_00000100_00001000_00000000;
    // const enemy: u64 = 0b00000000_00000000_00001000_00000000_00000000_01000000_00001000_00000000;
    // const player = 4;

    // const player = 63;
    //

    // const enemy: u64 = 0b00100100_00000000_00000000_00000000_00000000_00000000_00000000_11000000;
    const enemy: u64 = 0b01000010_00000000_00000000_00000000_00000000_00000000_00000000_11000000;

    const player = 4;
    //debug.print_possible_moves_captures(
    //    rooks.with_enemy_row(
    //        player,
    //        enemy,
    //    ),
    //    enemy,
    //    player,
    //);

    debug.print_possible_moves_captures(
        rooks.movement_short(
            player,
            enemy,
        ),
        enemy,
        player,
    ); // rooks.strip_lower_test(0b10000000, 0b10000000);
    // rooks.strip_lower_test(0b11000000, 0b10000000);
    // rooks.strip_lower_test(0b11111110, 0b10000000);
    // rooks.strip_lower_test(0b10001110, 0b10000000);

    //   const stdin = std.io.getStdIn().reader();
    //   // const stdout = std.io.getStdOut().writer();
    //   var input: [3]u8 = undefined;
    //
    //   while (input[0] != 'q') {
    //       var data = MoveData{ .board = board };
    //       _ = try stdin.readUntilDelimiter(&input, '\n');
    //
    //       // Take the coordinat ( A1, etc ) and turn it into the index ( A8 = 0)
    //       const index1: u8 = lookup.pos_to_index(input[0..2]);
    //
    //       // Take that index and get the correspnding bit mask 56 = A8 = 10000000
    //       data.old_bitmask = util.index_to_bitfield_pos(index1);
    //
    //       // Get the index in the board array that belongs to this piece
    //       data.old_piece_index = try get_piece_index(data.old_bitmask, board);
    //
    //       // Get the moves for the piece type at the selected pos
    //       data.moves = moves[data.old_piece_index][index1];
    //
    //       // Get all pieces on the board in two bit fields
    //       data.all_pieces = get_pieces_bit_field(board);
    //
    //       // Remove the pieces belonging to the current player from the possible moves
    //       data.moves &= ~data.all_pieces.current_player;
    //
    //       debug.print_possible_moves_captures(data.moves, data.all_pieces.oponent & data.moves, index1);
    //       _ = try stdin.readUntilDelimiter(&input, '\n');
    //
    //       const index2 = lookup.pos_to_index(input[0..2]);
    //       data.new_bitmask = util.index_to_bitfield_pos(index2);
    //
    //       board = perform_move(data);
    //       debug.print_board(board);
    //   }
}
const MoveData = struct {
    board: [12]u64,
    moves: u64 = 0,
    all_pieces: AllPieces = AllPieces{},
    old_piece_index: u8 = 0,
    old_bitmask: u64 = 0,
    new_bitmask: u64 = 0,
};

const AllPieces = struct {
    current_player: u64 = 0,
    oponent: u64 = 0,
};

fn perform_move(data: MoveData) [12]u64 {
    debug.print_possible_moves_captures(data.moves, data.all_pieces.oponent & data.moves, 0);
    if (data.moves & data.new_bitmask == 0) {
        std.debug.print("Invalid move!", .{});
        return data.board;
    }

    var new_board: [12]u64 = data.board;

    // Check if the move was a capture
    if (data.all_pieces.oponent & data.new_bitmask > 0) {
        // Find which array to remove the old piece from
        const captured_pi: u8 = get_piece_array_index(data.new_bitmask, data.board);

        // Remove the captured piece
        new_board[captured_pi] &= ~data.new_bitmask;
    }

    // Remove the piece from the current position
    new_board[data.old_piece_index] &= ~data.old_bitmask;

    // Put the piece in its new position
    new_board[data.old_piece_index] |= data.new_bitmask;

    return new_board;
}

fn get_pieces_bit_field(board: [12]u64) AllPieces {
    var pieces = AllPieces{};
    for (board, 0..) |p, j| {
        if (j % 2 == 0) {
            pieces.current_player |= p;
        } else {
            pieces.oponent |= p;
        }
    }

    std.debug.print("CurrentP pieces {b:0>64}\n", .{pieces.current_player});
    std.debug.print("Opponent pieces {b:0>64}\n", .{pieces.oponent});
    return pieces;
}

fn get_piece_array_index(bf_pos: u64, board: [12]u64) u8 {
    for (0..12) |i| {
        if (board[i] & bf_pos > 0) {
            const r: u8 = @intCast(i);
            return r;
        }
    }

    return 0;
}

const InvalidMoveError = error{
    InvalidPiece,
};

// Finds which piece is at position with bitfield calue bf_pos
fn get_piece_index(bf_pos: u64, board: [12]u64) InvalidMoveError!u8 {
    const i = for (0..12) |i| {
        if (board[i] & bf_pos > 0) {
            break i;
        }
    } else 0;

    return switch (i) {
        // Pawns
        0 => 0,
        1 => 1,
        // Rooks
        2 => 2,
        3 => 2,
        // Knight
        4 => 3,
        5 => 3,
        // Bishop
        6 => 4,
        7 => 4,
        // Queen
        8 => 5,
        9 => 5,
        // Kings
        10 => 6,
        11 => 6,
        // TODO : Return error here
        else => InvalidMoveError.InvalidPiece,
    };
}
fn create_board() [12]u64 {
    return [12]u64{
        // Pawns
        //
        // 0b11111111_10000001_10000001_10000001_10000001_10000001_10000001_11111111,
        0b00000000_00000000_00000000_00000000_00000000_00000000_11111111_00000000,
        0b00000000_11111111_00000000_00000000_00000000_00000000_00000000_00000000,

        // Rooks
        0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_10000001,
        0b10000001_00000000_00000000_00000000_00000000_00000000_00000000_00000000,

        // Knights
        0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_01000010,
        0b01000010_00000000_00000000_00000000_00000000_00000000_00000000_00000000,

        // Bishops
        0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00100100,
        0b00100100_00000000_00000000_00000000_00000000_00000000_00000000_00000000,

        // Queens
        0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00010000,
        0b00010000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,

        // Kings
        0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00001000,
        0b00001000_00000000_00000000_00000000_00000000_00000000_00000000_00000000,
    };
}
