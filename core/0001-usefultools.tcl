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
