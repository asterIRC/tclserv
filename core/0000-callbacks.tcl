# This portion, of course, is available under the MIT license if not bundled with the rest of TclServ.

# just to have sanity here. don't want a {} dict or a bum array
# this is for the logging algorithm to work once implemented, too, among other important things
set ::netname(-) -
#set ::nettype(-) -
#set ::sock(-) -

set globctx ""
set globuctx ""

proc curctx {args} {return "-"}

tnda set "llbinds" [list]

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
#	puts stdout "$sock $type $client [ndcenc $comd] $args"
	global globuctx globctx
	if {$sock == "-"} {} {set globctx $::netname($sock)}
	set oldglobuctx $globuctx
	if {$client == "-"} {set globuctx ""} {set globuctx $client}
	if {""!=[tnda get "llbinds/$::netname($sock)/$type/$client/[ndcenc $comd]"]} {
		foreach {id script} [tnda get "llbinds/$::netname($sock)/$type/$client/[ndcenc $comd]"] {
			if {$script != ""} {
				set scr [string range $script 0 120]
#				lappend $scr $sock
				foreach {a} $args {
					lappend scr $a
				}
				if {[set errcode [catch {eval $scr} erre]] > 0} {
					foreach logline [split [format "in script %s:\n\nerror code %s, %s\nerror info:\n%s\ncontact script developer for assistance\n" $scr $errcode $::errorInfo $erre] "\n"] {
						putloglev o * $logline
					}
					firellbind $sock evnt - error $erre {*}$scr
				}
			}
		};return
	} {
#		puts stdout "didn't find one"
	}
	set globuctx $oldglobuctx
	#if {""!=[tnda get "llbinds/$type/-/[ndcenc $comd]"]} {foreach {id script} [tnda get "llbinds/$type/-/[ndcenc $comd]"] {$script [lindex $args 0] [lrange $args 1 end]};return}
}

proc firellmbind {sock type client comd args} {
#	puts stdout "$sock $type $client [ndcenc $comd] $args"
	global globuctx globctx
	if {$sock == "-"} {} {set globctx $::netname($sock)}
	set oldglobuctx $globuctx
	if {$client == "-"} {set globuctx ""} {set globuctx $client}
	foreach {comde scripts} [tnda get "llbinds/$::netname($sock)/$type/$client"] {
		set text [ndadec $comde]
		if {[string match $text $comd]} {
			foreach {id script} $scripts {
				if {$script != ""} {
					set scr $script
#					lappend $scr $sock
					foreach {a} $args {
						lappend scr $a
					}
					if {[set errcode [catch {eval $scr} erre]] > 0} {
						foreach logline [split [format "in script (#%s) %s:\n\nerror code %s, %s\nerror info:\n%s\ncontact script developer for assistance\n" $id $scr $errcode $::errorInfo $erre] "\n"] {
							putloglev o * $logline
						}
						firellbind $sock evnt - error $erre {*}$scr
					}
				}
			}
		}
	}
	set globuctx $oldglobuctx
	#if {""!=[tnda get "llbinds/$type/-/[ndcenc $comd]"]} {foreach {id script} [tnda get "llbinds/$type/-/[ndcenc $comd]"] {$script [lindex $args 0] [lrange $args 1 end]};return}
}
proc putloglev {lev ch msg} {
	global globuctx globctx
	set oldglobuctx $globuctx
	# punt
    foreach level [split $lev {}] {
		catch {firellmbind [curctx sock] log - [format "%s %s" $ch $level] [curctx net] $level $ch $msg}
		catch {firellbind [curctx sock] logall - - [curctx net] $level $ch $msg}
		catch {firellmbind - log - [format "%s %s" $ch $level] [curctx net] $level $ch $msg}
		catch {firellbind - logall - - [curctx net] $level $ch $msg}
	}
	set globuctx $oldglobuctx
}
proc putlog {msg} {putloglev o * $msg}
