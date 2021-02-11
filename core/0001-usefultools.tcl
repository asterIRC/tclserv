blocktnd misc
set miscellanyunbindrehash [llbind - evnt - confloaded miscellany.rehash]

proc miscellany.rehash {a} {
#	if {[catch {set oldmiscellanyunbindalive}] == 0} {
#		unllbind - evnt - alive $::oldmiscellanyunbindalive
#		unllbind - evnt - confloaded $::oldmiscellanyunbindrehash
#	}
	putlog [format "there are %s miscellany blocks" [set blocks [tnda get "openconf/[ndcenc misc]/blocks"]]]
	for {set i 1} {$i < ($blocks + 1)} {incr i} {
		set netname [string tolower [lindex [tnda get [format "openconf/%s/hdr%s" [ndcenc misc] $i]] 0]]
		after 1000 [list miscellany.oneintro [tnda get [format "openconf/%s/hdr%s" [ndcenc misc] $i]] [tnda get [format "openconf/%s/n%s" [ndcenc misc] $i]]]
	}
}

proc miscellany.oneintro {hdr block} {
	if {$hdr == ""} {
		tnda set "gmisc" $block
	} {
		tnda set "misc/[ndcenc $hdr]" $block
	}
}

proc dictassign {dictValue args} {
	foreach {i j} $args {
		upvar $j jj
		if {[dict exists $dictValue {*}$i]} {
			set jj [dict get $dictValue {*}$i]
		} {
			set jj ""
		}
	}
}
