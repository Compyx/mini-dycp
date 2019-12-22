
# Determine if memory slab addr_lo-addr_his reserved
#
# Reserved currently means:
#   $2600-$27ff     music (still need to relocate SID
#   $2c00-$2c9f     viram
#   $2800-$2bff     DYCP rendering area
#
# Return:   TRUE if reserved
#
function is_reserved_space(addr_lo, addr_hi)
{
    # check music
    if (addr_lo >= SID_LO && addr_hi <= SID_HI) {
        return 0
    }
    # check dycp render area
    if (addr_lo >= DYCP_LO && addr_hi <= DYCP_HI) {
        return 0
    }
    return 1
}

BEGIN {
    FS=":"
    lastaddr=0
    print ">> Start AWK filtering:"
    total_space = 0

    SID_LO = 2 * 4096 + 6 * 256
    SID_HI = SID_LO + 512 -1
    DYCP_LO = 2 * 4096 + 8 * 256
    DYCP_HI = DYCP_LO + 3 *256 -1

}

{
    if (match($0, /Memory range.*\$([0-9a-f]+)-\$([0-9a-f]+)\s*\$([0-9a-f]+)/, foo)) {
        #print foo[1], foo[2], foo[3]
        lo = strtonum("0x" foo[1])
        hi = strtonum("0x" foo[2])
        # print strtonum("0x" foo[1]), strtonum("0x" foo[2]), strtonum("0x" foo[3])
        if (lastaddr != 0) {
            printf "  Free space:                    $%04x\n", lo - lastaddr - 1
        }
        # calculate total free space when between $2000 and $2fff
        if (lastaddr >= 8192 && lo < 8192 + 4096 \
            && is_reserved_space(lo, last_addr)) {
            total_space += (lo - lastaddr)
        }
        print $0
        lastaddr = hi
    } else {
        print
    }
}

END {
    print ">> Total free space between $2000-$2fff = " total_space
    print ">> End AWK filtering"

}
