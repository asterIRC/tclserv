proc llbind {sock type client comd script} {
	set moretodo 1
	while {0!=$moretodo} {
		set llbindnum [rand 1 100000000]
		if {[tnda get "llbinds/$::netname($sock)/$type/$client/[ndcenc $comd]/$llbindnum"]!=""} {} {set moretodo 0}
	}
	tnda set "llbinds/$::netname($sock)/$type/$client/[ndcenc $comd]/$llbindnum" $script
	return $llbindnum
}

proc unllbind {sock type client comd id} {
	tnda set "llbinds/$::netname($sock)/$type/$client/[ndcenc $comd]/$id" ""
	tnda unset "llbinds/$::netname($sock)/$type/$client/[ndcenc $comd]/$id"
}
proc unllbindall {sock type client comd} {
	tnda set "llbinds/$::netname($sock)/$type/$client/[ndcenc $comd]" ""
	tnda unset "llbinds/$::netname($sock)/$type/$client/[ndcenc $comd]"
}
proc firellbind {sock type client comd args} {
#	puts stdout "$sock $type $client $comd $args"
	global globuctx globctx
	set globctx $::netname($sock)
	set globuctx $client
	if {""!=[tnda get "llbinds/$::netname($sock)/$type/$client/[ndcenc $comd]"]} {
		foreach {id script} [tnda get "llbinds/$::netname($sock)/$type/$client/[ndcenc $comd]"] {
			if {$script != ""} {
				set scr $script
#				lappend $scr $sock
				foreach {a} $args {
					lappend scr $a
				}
				if {[set errcode [catch {eval $scr} erre]] > 0} {
					puts stdout [format "in script %s:\n\nerror code %s, %s\ncontact script developer for assistance\n" $scr $errcode $erre]
					firellbind $sock evnt - error $erre {*}$scr
				}
			}
		};return
	}
	#if {""!=[tnda get "llbinds/$type/-/[ndcenc $comd]"]} {foreach {id script} [tnda get "llbinds/$type/-/[ndcenc $comd]"] {$script [lindex $args 0] [lrange $args 1 end]};return}
}
