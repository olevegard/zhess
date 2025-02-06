// Returns position in chess format from an index
// The index starts at 0 = A1 and ends at 63 = H8
pub inline fn pos_to_index(pos: []const u8) u8 {
    // First char is 'A' - 'H'. Subtracting 'A' gives us the numbers 0-7
    // Second char is '0' - '9'. Subtracting '0' gives us the numbers 0-7
    // Note that the number part ( pos[1] ) is encoded at utf-8,
    // so the decimal value is 49 to 57, not 1-8
    return (pos[0] - 'A') + ((pos[1] - '1') * 8);
}

// Strings in Zig are *const [n:x] where n is length and x is sentinel
pub inline fn index_to_pos(index: u8) *const [2:0]u8 {
    return &[2:0]u8{
        'A' + (index % 8), // 65
        '1' + (index / 8), // 48
    };
}
