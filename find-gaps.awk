BEGIN {
    FS=":"
    lastaddr=0
    print "Start"
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
        print $0
        lastaddr = hi
    } else {
        print
    }
}

END {
    print "End"
}
