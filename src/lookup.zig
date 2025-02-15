const std = @import("std");

// Returns position in chess format from an index
// The index starts at 0 = A1 and ends at 63 = H8
pub inline fn pos_to_index(pos: []const u8) u8 {
    // First char is 'A' - 'H'. Subtracting 'A' gives us the numbers 0-7
    // Second char is '0' - '9'. Subtracting '0' gives us the numbers 0-7
    // Note that the number part ( pos[1] ) is encoded at utf-8,
    // so the decimal value is 49 to 57, not 1-8
    return (pos[0] - 'A') + (('8' - pos[1]) * 8);
}

// Strings in Zig are *const [n:x] where n is length and x is sentinel
pub inline fn index_to_pos(index: u8) *const [2:0]u8 {
    return &[2:0]u8{
        'A' + (index % 8), // 65
        '8' - (index >> 3), // 48
    };
}

pub inline fn index_to_row(index: u8) u8 {
    // Since each row starts at 0,8,16,24,32,40,48 or 56
    // we can use << 3 to get the row
    // ie. H8 = 7 = 0000 0111 >> 3 = 0
    // ie. B2 = 9 = 0000 1001 >> 3 = 1
    // ie. C5 = 9 = 0000 1001 >> 3 = 1
    return index >> 3;
}

pub inline fn index_to_col(index: u8) u8 {
    return index & 7;
}
