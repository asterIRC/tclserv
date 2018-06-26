package require tls

# just to have sanity here. don't want a {} dict or a bum array
set $::netname(-) -

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
		tnda set "ts6/$netname/prefix" $pfx
	} {
		# safe defaults, will cover charybdis and chatircd
		tnda set "ts6/$netname/prefix" [list @ o % h + v]
	}
	# open a connection
	set socke [connect $host $port [list $proto irc-main]]
	after 500 $proto login $socke $numeric $pass $netname $servername
	# store it up
	postblock network $headlines $block
}

proc core.conn.mknetworks {args} {
	set blocks [tnda get "openconf/[ndcenc network]/blocks"]]
	for {set i 1} {$i < ($blocks + 1)} {incr i} {
		after 1000 [list mknetwork [tnda get [format "openconf/%s/hdr%s" [ndcenc network] $i]] [tnda get [format "openconf/%s/n%s" [ndcenc network] $i]]]
	}
}

blocktnd network

llbind - evnt - confloaded core.conn.mknetworks

#blockwcb network mknetwork
