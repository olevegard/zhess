const std = @import("std");

pub const max: u64 = std.math.pow(u64, 2, 63);

pub fn strip_player_pos(bitfield: u64, position: u64) u64 {
    return bitfield & ~std.math.shr(u64, max, position);
}

pub fn index_to_bitfield_pos(position: u64) u64 {
    return std.math.shr(u64, max, position);
}
