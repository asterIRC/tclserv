package require tls

# just to have sanity here. don't want a {} dict or a bum array
set ::netname(-) -

proc connect {addr port script} {
	if {[string index $port 0] == "+"} { set port [string range $port 1 end] ; set comd ::tls::socket } {set comd socket}
	set sck [$comd $addr $port]
	fconfigure $sck -blocking 0 -buffering line
	fileevent $sck readable [concat $script $sck]
	return $sck
}

proc mknetwork {headlines block} {
	if {[llength $headlines]<2} {
		puts stdout "fuck it, block's invalid ($headlines)"
		return
	}
	set proto [dict get $block proto]
	set numeric [dict get $block numeric]
	set pass [dict get $block pass]
	set host [dict get $block host]
	set port [dict get $block port]
	set isupport [dict get $block isupport]
	set servername [lindex $headlines 1]
	set netname [lindex $headlines 0]
	if {[catch {set ::sock($netname)} result] == 0} {
		if {![eof $::sock($netname)]} {
			puts stdout "probably rehashing (connected network block, [tnda get rehashing], $result)"
			return
		}
	}
	if {[dict exists $block prefixes]} {
		# only required for ts6
		set prefixes [split [dict get $block prefix] " "]
		set pfxl [split [lindex $prefixes 0] {}]
		set pfxr [split [lindex $prefixes 1] {}]
		set pfx [list]
		foreach {p} $pfxl {m} $pfxr {
			lappend pfx $p
			lappend pfx $m
		}
		tnda set "netinfo/$netname/prefix" $pfx
	} {
		# safe defaults, will cover charybdis and chatircd
		tnda set "netinfo/$netname/prefix" [list @ o % h + v]
	}
	if {[dict exists $block type]} {
		tnda set "netinfo/$netname/type" [dict get $block type]
	} {	tnda set "netinfo/$netname/type" norm	}
	if {[string length $isupport] > 0} {
		foreach {tok} [split $isupport " "] {
			foreach {key val} [split $tok "="] {
				if {$key == "PREFIX"} {
					if {[tnda get "netinfo/$netname/pfxissjoin"] == 1} {continue}
					set v [string range $val 1 end]
					set mod [split $v ")"]
					set modechar [split [lindex $mod 1] {}]
					set modepref [split [lindex $mod 0] {}]
					foreach {c} $modechar {x} $modepref {
						tnda set "netinfo/$netname/prefix/$c" $x
					}
					foreach {x} $modechar {c} $modepref {
						tnda set "netinfo/$netname/pfxchar/$c" $x
					}
				} elseif {$key == "SJOIN"} {
					tnda set "netinfo/$netname/pfxissjoin" 1
					set v [string range $val 1 end]
					set mod [split $v ")"]
					set modechar [split [lindex $mod 1] {}]
					set modepref [split [lindex $mod 0] {}]
					foreach {c} $modechar {x} $modepref {
						tnda set "netinfo/$netname/prefix/$c" $x
					}
					foreach {x} $modechar {c} $modepref {
						tnda set "netinfo/$netname/pfxchar/$c" $x
					}
				} elseif {$key == "CHANMODES"} {
					set spt [split $val ","]
					tnda set "netinfo/$netname/chmban" [lindex $spt 0]
					tnda set "netinfo/$netname/chmparm" [format "%s%s" [lindex $spt 0] [lindex $spt 1]]
					tnda set "netinfo/$netname/chmpartparm" [lindex $spt 2]
					tnda set "netinfo/$netname/chmnoparm" [lindex $spt 3]
				} else {
					tnda set "netinfo/$netname/isupport/[ndaenc $key]" $val
				}
			}
		}
	}
	# open a connection
	set socke [connect $host $port [list $proto irc-main]]
	after 500 $proto login $socke $numeric $pass $netname $servername
	llbind - dead - $socke [list after 5000 [list mknetwork $headlines $block]]
	foreach {def} {
		protectop protecthalfop protectvoice operit autoop autohalfop autovoice bitch halfbitch voicebitch
	} {
		setudef flag $def
	}
	tnda set "netinfo/$netname/crontab" [cron add "* * * * *" eval [concat firellmbind $socke time - {[clock format [clock seconds] -format "%M %H %d %m %Y"]} \
		{[clock format [clock seconds] -format "%M"]} \
		{[clock format [clock seconds] -format "%H"]} \
		{[clock format [clock seconds] -format "%d"]} \
		{[clock format [clock seconds] -format "%m"]} \
		{[clock format [clock seconds] -format "%Y"]} \
		]]
	# store it up
#	postblock network $headlines $block
}

proc core.conn.mknetworks {args} {
	set blocks [tnda get "openconf/[ndcenc network]/blocks"]
	for {set i 1} {$i < ($blocks + 1)} {incr i} {
		puts stdout "$blocks"
		after 1000 [list mknetwork [tnda get [format "openconf/%s/hdr%s" [ndcenc network] $i]] [tnda get [format "openconf/%s/n%s" [ndcenc network] $i]]]
	}
}

blocktnd network

llbind - evnt - confloaded core.conn.mknetworks

#blockwcb network mknetwork
