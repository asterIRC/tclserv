$::maintype sendUid $sock syn syn channels. channels. 1444 "Tin"
bind $::sock msg 1444 "addgwcloak" addgwcloak
bind $::sock msg 1444 "addaccloak" addaccloak
bind $::sock conn - - dogwcloak
bind $::sock motd - - dogwcloak
bind $::sock msg 1444 "motd" dogwcloak

proc addgwcloak {from msg} {
	set uname [tnda get "login/$::netname($::sock)/$from"]
	if {$::synpass != [lindex $msg 0 2]} {
		$::maintype notice $::sock 1444 $from "SYNTAX: /msg syn addgwcloak match cloak syn-password"
		$::maintype notice $::sock 1444 $from "FORMATCHAR: %i = realhost"
		return
	}
	if {""==[lindex $msg 0 0]} {
		$::maintype notice $::sock 1444 $from "SYNTAX: /msg syn addgwcloak match cloak"
		$::maintype notice $::sock 1444 $from "FORMATCHAR: %i = realhost"
                return

	}
	if {""==[lindex $msg 0 1]} {
		$::maintype notice $::sock 1444 $from "SYNTAX: /msg syn addgwcloak match cloak"
		$::maintype notice $::sock 1444 $from "FORMATCHAR: %i = realhost"
                return

	}
	nda set "gwcloaks/[lindex $msg 0 0]" [lindex $msg 0 1]
}

proc dogwcloak {unick n} {
	doinsecurehost $unick
	set fp [open ./services.motd r]
	set fl [read $fp]
#	set fl ""
	close $fp
	foreach {l} [split $fl "\r\n"] {
		$::maintype putmotd $::sock $unick "$l"
	}
	$::maintype putmotdend $::sock $unick
	set match [tnda get "rhost/$::netname($::sock)/$unick"]
	foreach {mask cloak} [nda get "gwcloaks"] {
		if {[string match -nocase $mask "[tnda get "nick/$::netname($::sock)/$unick"]![tnda get "ident/$::netname($::sock)/$unick"]@[tnda get "rhost/$::netname($::sock)/$unick"]"]} {set match $cloak}
	}
	set cloake [string map [list "::" "-" ":" "."] [string map [list "%i" [tnda get "rhost/$::netname($::sock)/$unick"]] $match]]
	$::maintype notice $::sock 1444 $unick "$cloake should be your vHost."
	$::maintype sethost $::sock 1444 $unick "$cloake"
	$::maintype putwallop $::sock "CONNECT: [tnda get "nick/$::netname($::sock)/$unick"]![tnda get "ident/$::netname($::sock)/$unick"]@[tnda get "rhost/$::netname($::sock)/$unick"] ($cloake)"
}

proc doinsecurehost {unick} {
	package require ip
	set rhostname [tnda get "rhost/$::netname($::sock)/$unick"]
	if {![string match "*:*" $rhostname] && [catch {::ip::toInteger $rhostname}]} {
		if {![catch "exec php ./dnslib.php [string trim $rhostname] A . 0 $unick" reho]} {set rhostname [lindex [split [string trim $reho] " "] 1]} elseif {![catch "exec php ./dnslib.php [string trim $rhostname] AAAA . 0 $unick" reho]} {set rhostname [lindex [split [string trim $reho] " "] 1]} {puts stdout "gave up $rhostname $unick";return}
		# If we returned then we gave up.
	}
	if {[string match "*:*" $rhostname]} {return;}
	foreach {dnsbl} $::dnsbls {
		set fp [open |[list php ./dnslib.php [string trim $rhostname] A $dnsbl 1 $unick] r]
		set reho [read $fp]
		catch "close $fp"
		set reho [string trim $reho]
		if {[lindex [split $reho " "] 0] == $unick} {set result [lindex [split $reho " "] 1]} {puts stdout "gave up $rhostname $unick results /$reho/";return}
		# If we returned then we gave up.
		if {$result!="" && $result != 0 && $result != 1} {$::maintype kill $::sock 1444 $unick "(DNSBL::$::dname($dnsbl) match - if this is in error contact j4jackj)"}
	}
}

set dname(dnsbl.dronebl.org) DroneBL
set dname(6667.141.117.162.69.ip-port.exitlist.torproject.org) Tor
set dnsbls [list dnsbl.dronebl.org 6667.141.117.162.69.ip-port.exitlist.torproject.org]
