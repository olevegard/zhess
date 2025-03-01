const std = @import("std");

pub const max: u64 = std.math.pow(u64, 2, 63);

pub fn strip_player_pos(bitfield: u64, position: u64) u64 {
    return bitfield & ~std.math.shr(u64, max, position);
}

pub fn index_to_bitfield_pos(position: u64) u64 {
    return std.math.shr(u64, max, position);
}

pub fn print_u64(prefix: [:0]const u8, num: u64) void {
    var buf: [68]u8 = undefined;
    const slice = std.fmt.bufPrint(&buf, "{b:0>64}", .{num}) catch |e| {
        std.debug.print("Failed printing {d} : {any}\n", .{ num, e });
        return;
    };

    std.debug.print("{s} : {s}_{s}_{s}_{s}_{s}_{s}_{s}_{s}\n", .{
        prefix,
        slice[0..8],
        slice[8..16],
        slice[16..24],
        slice[24..32],
        slice[32..40],
        slice[40..48],
        slice[48..56],
        slice[56..64],
    });
}
