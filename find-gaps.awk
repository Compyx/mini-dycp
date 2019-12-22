
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
    printf("Got lo = $%04x, hi = $%04x\n", addr_lo, addr_hi)
    # check music
    if (addr_lo >= SID_LO && addr_hi < SID_HI) {
        return 1
    }
    # check dycp render area
    if (addr_lo >= DYCP_LO && addr_hi < DYCP_HI) {
        return 1
    }
    # check vidram
    if (addr_lo >= VIDRAM_LO && addr_hi < VIDRAM_HI) {
        return 1
    }
    return 0
}


function add_to_space_array(addr_lo, addr_hi)
{
    space_array[addr_lo] = addr_hi - addr_lo
}


BEGIN {
    print ">> Start AWK filtering:"

    FS=":"
    lastaddr=0
    total_space = 0

    BASE_ADDR = 8192

    SID_LO = BASE_ADDR + 6 * 256 - 1
    SID_HI = SID_LO + 512 - 1
    DYCP_LO = BASE_ADDR + 8 * 256 -1
    DYCP_HI = DYCP_LO + 3 *256 -1
    VIDRAM_LO = BASE_ADDR + 12 * 256 - 1
    VIDRAM_HI = VIDRAM_LO + 3 * 256 - 1
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
            && !is_reserved_space(lastaddr, lo)) {
            total_space += (lo - lastaddr)
            add_to_space_array(lastaddr, lo)
        }
        print $0
        lastaddr = hi
    } else {
        print
    }
}

END {
    print ">> Total free space between $2000-$2fff = " total_space
    # Dump space free
    print ">> Free space list:"
    for (key in space_array) {
        printf("$%04x-$%04x: $%04x\n",
               key, key + space_array[key] - 1, space_array[key] - 1)
    }
    print ">> End AWK filtering"
}
