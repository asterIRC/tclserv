#source nda.tcl
#source 9999-protocol-common.tcl


namespace eval ts6 {
#proc putcmdlog {args} {}
proc ::ts6::b64e {numb} {
        set b64 [split "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" {}]

        set res ""
	while {$numb != 0} {
		append res [lindex $b64 [expr {$numb % 36}]]
		set numb [expr {$numb / 36}]
	}
	if {[string length $res] == 0} {
		set res "A"
	}
        return [string reverse $res]
}

proc ::ts6::b64d {numb} {
        set b64 "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	set numb [string trimleft $numb "A"]
	set res 0
	for {set i 0} {$i<[string length $numb]} {incr i} {
		set new [string first [string index $numb $i] $b64]
		incr res [expr {$new * (36 * $i)+1}]
	}
        return $res
}
}

proc putl {args} {
	puts stdout [join $args " "]
	puts {*}$args
}

namespace eval ts6 {

proc ::ts6::sendUid {sck nick ident host dhost uid {realname "* Unknown *"} {modes "+oiS"} {server ""}} {
	if {""==$server} {set server $::sid($sck)}
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $server]]}]]
	append sid [::ts6::b64e $server]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	if {![tnda get "netinfo/$::netname($sck)/euid"]} {
		set sl [format ":%s UID %s 1 %s %s %s %s 0 %s%s :%s" $sid $nick [clock format [clock seconds] -format %s] $modes $ident $host $sid $sendnn $realname]
	} {
		set sl [format ":%s EUID %s 1 %s %s %s %s 0 %s%s %s * :%s" $sid $nick [clock format [clock seconds] -format %s] $modes $ident $dhost $sid $sendnn $host $realname]
	}
	tnda set "intclient/$::netname($sck)/${sid}${sendnn}" $uid
	tnda set "nick/$::netname($sck)/${sid}${sendnn}" $nick
	tnda set "ident/$::netname($sck)/${sid}${sendnn}" $ident
	tnda set "rhost/$::netname($sck)/${sid}${sendnn}" $host
	tnda set "vhost/$::netname($sck)/${sid}${sendnn}" $dhost
	tnda set "rname/$::netname($sck)/${sid}${sendnn}" $realname
	tnda set "ipaddr/$::netname($sck)/${sid}${sendnn}" 0
	putl $sck $sl
}

proc ::ts6::topic {sck uid targ topic} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
	append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putl $sck [format ":%s%s TOPIC %s :%s" $sid $sendnn $targ $topic]
}

proc ::ts6::setnick {sck uid newnick} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
	append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putl $sck [format ":%s%s NICK %s :%s" $sid $sendnn $newnick [clock format [clock seconds] -format %s]]
}

proc ::ts6::sethost {sck targ topic} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
	append sid [::ts6::b64e $::sid($sck)]
	if {![tnda get "netinfo/$::netname($sck)/euid"]} {
		putl $sck [format ":%s ENCAP * CHGHOST %s %s" $sid $targ $topic]
	} {
		putl $sck [format ":%s CHGHOST %s %s" $sid $targ $topic]
	}
}

proc ::ts6::sendSid {sck sname sid {realname "In use by Services"}} {
set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
append sid [::ts6::b64e $::sid($sck)]
	set sl [format ":%s SID %s 1 %s :%s" [::ts6::b64e $sid] $sname [::ts6::b64e $sid] $realname]
	putl $sck $sl
}

proc ::ts6::privmsg {sck uid targ msg} {
set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putl $sck [format ":%s%s PRIVMSG %s :%s" $sid $sendnn $targ $msg]
}

proc ::ts6::snote {sck targ msg} {
set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putl $sck [format ":%s ENCAP * SNOTE %s :%s" $sid $sendnn $targ $msg]
}

proc ::ts6::metadata {sck targ direction type {msg ""}} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
	append sid [::ts6::b64e $::sid($sck)]
	if {[string toupper $direction] != "ADD" && [string toupper $direction] != "DELETE"} {putloglev d * "failed METADATA attempt (invalid arguments)";return} ;#no that didn't work
	if {[string toupper $direction] == "ADD"} {
		tnda set "metadata/$::netname($sck)/$targ/[ndaenc $type]" $msg
		putl $sck [format ":%s ENCAP * METADATA %s %s %s :%s" $sid [string toupper $direction] $targ [string toupper $type] $msg]
	}
	if {[string toupper $direction] == "DELETE"} {
		tnda unset "metadata/$::netname($sck)/$targ/[ndaenc $type]"
		putl $sck [format ":%s ENCAP * METADATA %s %s :%s" $sid [string toupper $direction] $targ [string toupper $type]]
	}
}

proc ::ts6::kick {sck uid targ tn msg} {
set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putl $sck [format ":%s%s KICK %s %s :%s" $sid $sendnn $targ $tn $msg]
}

proc ::ts6::notice {sck uid targ msg} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putl $sck [format ":%s%s NOTICE %s :%s" $sid $sendnn $targ $msg]
}

proc ::ts6::part {sck uid targ msg} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putl $sck [format ":%s%s PART %s :%s" $sid $sendnn $targ $msg]
	set chan [ndaenc $targ]
	tnda set "userchan/$::netname($sck)/$sid$sendnn/$chan" 0
	tnda set "channels/$::netname($sck)/$chan/status/[lindex $comd 0]" ""
}

proc ::ts6::quit {sck uid msg} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putl $sck [format ":%s%s QUIT :%s" $sid $sendnn $msg]
	tnda unset "intclient/$::netname($sck)/${sid}${sendnn}"
	tnda unset "ident/$::netname($sck)/${sid}${sendnn}"
	tnda unset "rhost/$::netname($sck)/${sid}${sendnn}"
	tnda unset "vhost/$::netname($sck)/${sid}${sendnn}"
	tnda unset "rname/$::netname($sck)/${sid}${sendnn}"
	tnda unset "ipaddr/$::netname($sck)/${sid}${sendnn}"
	tnda unset "nick/$::netname($sck)/${sid}${sendnn}"
}

proc ::ts6::setacct {sck targ msg} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	if {[ts6 uid2nick $sck $targ] == ""} {return}
	putl $sck [format ":%s ENCAP * SU %s %s" $sid $targ $msg]
	tnda set "login/$::netname($sck)/$targ" $msg
}

proc ::ts6::grant {sck targ msg {fmult 65}} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	if {[ts6 uid2nick $sck $targ] == ""} {return}
	putl $sck [format ":%s ENCAP * GRANT %s %s %s" $sid $targ $fmult $msg]
	tnda set "oper/$::netname($sck)/$targ" 1
}

proc ::ts6::putmotd {sck targ msg} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	if {[ts6 uid2nick $sck $targ] == ""} {return}
	putl $sck [format ":%s 372 %s :- %s" $sid $targ $msg]
}

proc ::ts6::putmotdend {sck targ} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	if {[ts6 uid2nick $sck $targ] == ""} {return}
	putl $sck [format ":%s 376 %s :End of global MOTD." $sid $targ]
}

proc ::ts6::putmode {sck uid targ mode {parm ""} {ts ""}} {
	if {$ts == ""} {
		if {[set ts [tnda get "channels/$::netname($sck)/[ndaenc [string tolower $targ]]/ts"]] == ""} {return} ;#cant do it, doesnt exist
	}
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putl $sck [format ":%s" [set com [format "%s%s TMODE %s %s %s %s" $sid $sendnn $ts $targ $mode $parm]]]
	set comd [split $com " "]
	set ctr 4
	set state 1
	foreach {c} [split $mode {}] {
		if {$c == "+"} {
			set state 1
		} elseif {$c == "-"} {
			set state 0
		} elseif {[string match [format "*%s*" $c] [tnda get "netinfo/$::netname($sck)/chmparm"]] || ($state&&[string match [format "*%s*" $c] [tnda get "netinfo/$::netname($sck)/chmpartparm"]])} {
			[expr {$state?"::ts6::checkop":"::ts6::checkdeop"}] [lindex $comd 0] [lindex $comd 3] [format "%s%s" [expr {$state?"+":"-"}] $c] [lindex $comd [incr ctr]]
#			firellmbind $sck mode - [format "%s %s%s" [string tolower [lindex $comd 3]] [expr {$state ? "+" : "-"}] $c] [lindex $comd 0] [lindex $comd 3] [format "%s%s" [expr {$state?"+":"-"}] $c] [lindex $comd [incr ctr]]
		} else {
			[expr {$state?"::ts6::checkop":"::ts6::checkdeop"}] [lindex $comd 0] [lindex $comd 3] [format "%s%s" [expr {$state?"+":"-"}] $c] [lindex $comd [incr ctr]]
#			firellmbind $sck mode - [format "%s %s%s" [string tolower [lindex $comd 3]] [expr {$state ? "+" : "-"}] $c] [lindex $comd 0] [lindex $comd 3] [format "%s%s" [expr {$state?"+":"-"}] $c] ""
#			firellmbind $sck mode "-" [expr {$state ? "+" : "-"}] $c [lindex $comd 0] [lindex $comd 3] ""
		}
	}
}

proc ::ts6::sendencap {sck uid targ args} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	if {[ts6 uid2nick $sck $targ] == ""} {return}
	if {$uid == "-1"} {	set sendnn ""} {
			set sendid [::ts6::b64e $uid]
			set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
			append sendnn $sendid
	}
	if {[string first " " [lindex $args end]] != -1} {
		putl $sck [format ":%s%s ENCAP %s %s :%s" $sid $sendnn $targ [join [lrange $args 0 end-1] " "] [lindex $args end]]
	} {
		putl $sck [format ":%s%s ENCAP %s %s" $sid $sendnn $targ [join $args " "]]
	}
}

proc ::ts6::putjoin {sck uid targ {ts ""}} {
	if {$ts == ""} {
		if {[set ts [tnda get "channels/$::netname($sck)/[ndaenc [string tolower $targ]]/ts"]] == ""} {set ts [clock format [clock seconds] -format %s]}
	}
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putl $sck [format ":%s SJOIN %s %s + :%s%s" $sid $ts $targ $sid $sendnn]
	set chan [ndaenc $targ]
	tnda set "userchan/$::netname($sck)/$sid$sendnn/$chan" 1
#	tnda set "channels/$::netname($sck)/$chan/status/[lindex $comd 0]" ""
}

proc ::ts6::validchan {sck channelname} {
	if {[string is digit [string index $channelname 0]] && [string length $channelname] == 9} {return 0} ;# valid handle, not valid channel
	if {[string first [string index $channelname 0] [tnda get "netinfo/$::netname($sck)/[ndaenc CHANTYPES]"]] != -1} {return 1} ;# could be valid channel, so let's just say yes
}

proc ::ts6::quitstorm {sck sid comment {doinit 1}} {
	if {$doinit} {set splits [list $sid]} {set splits [list]}
	foreach {sid64 sdesc} [tnda get "servers/$::netname($sck)"] {
		# if the server doesn't have $sid as the uplink, continue
		if {[dict get $sdesc uplink] != $sid} {
			continue
		}
		# but if it does... they split and we should see who they're taking down
		lappend splits [string toupper [ndadec $sid64]]
		foreach {splitid} [::ts6::quitstorm $sck [ndadec $sid64] $comment 0] {
			lappend splits $splitid
		}
	}
	return $splits
}

proc ::ts6::irc-main {sck} {
	global sid sock socksid
	if {[eof $sck]} {
		puts stdout "We're dead, folks."
#		firellbind $sck evnt "-" "ts6.dead" $::netname($sck) $sck
		firellbind $sck evnt "-" "dead" $::netname($sck) $sck
		firellbind - evnt "-" "dead" $sck $::netname($sck)
		close $sck
	}
	gets $sck line
	setctx $::netname($sck)
	#puts stdout $line
	set line [string trim $line "\r\n"]
	set one [string match ":*" $line]
	set line [string trimleft $line ":"]
	set gotsplitwhere [string first " :" $line]
	if {$gotsplitwhere==-1} {set comd [split $line " "]} {set comd [split [string range $line 0 [expr {$gotsplitwhere - 1}]] " "]}
	if {$gotsplitwhere==-1} {set payload [lindex $comd end]} {set payload [string range $line [expr {$gotsplitwhere + 2}] end]}
	if {$gotsplitwhere != -1} {lappend comd $payload}
	if {[lindex $comd 0] == "PING"} {putl $sck "PONG $::snames($sck) :$payload"}
	if {[lindex $comd 0] == "SERVER"} {putl $sck "VERSION"}
	if {$one == 1} {
		set sourceof [lindex $comd 0]
		set two 2
	} {	set sourceof ""
		set two 1}
	firellbind $sck raw - [lindex $comd $one] $sourceof [lindex $comd $one] [join [lrange $comd $two end] " "]
	set erreno [catch {
	switch -nocase -- [lindex $comd $one] {
		"479" {putloglev d * $payload}
		"PASS" {
		#	putquick "PRIVMSG #services :$line"
			puts stdout "we have a winner! $one"
			set ssid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append ssid [::ts6::b64e $::sid($sck)]
			tnda set "servers/$::netname($sck)/[ndaenc [lindex $comd 4]]/uplink" $ssid
			tnda set "servers/$::netname($sck)/[ndaenc [lindex $comd 4]]/sid" $payload
			tnda set "socksid/$::netname($sck)" $payload
		}

		"SERVER" {
			puts stdout "we have a winner! $one"
#			if {[lindex $comd [expr {$one + 2}]] != 1} {return};#we don't support jupes
			tnda set "servers/$::netname($sck)/[ndaenc [tnda get "socksid/$::netname($sck)"]]/name" [lindex $comd [expr {$one + 1}]]
			tnda set "servers/$::netname($sck)/[ndaenc [tnda get "socksid/$::netname($sck)"]]/description" [lindex $comd [expr {$one + 3}]]
#			firellbind $sck evnt "-" "alive" $::netname($sck)
			if {$one == 0} {firellbind - evnt "-" "alive" $::netname($sck)}
#			firellbind $sck evnt "-" "ts6.alive" $::netname($sck)
		}

		"SID" {
			puts stdout "we have a winner! $one"
			tnda set "servers/$::netname($sck)/[ndaenc [lindex $comd 4]]/name" [lindex $comd 2]
			tnda set "servers/$::netname($sck)/[ndaenc [lindex $comd 4]]/description" [lindex $comd 5]
			tnda set "servers/$::netname($sck)/[ndaenc [lindex $comd 4]]/uplink" [lindex $comd 0]
			tnda set "servers/$::netname($sck)/[ndaenc [lindex $comd 4]]/sid" [lindex $comd 4]
#			putloglev o * [tnda get "servers"]
		}

		"SQUIT" {
			set ssid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append ssid [::ts6::b64e $::sid($sck)]
			set failedserver [lindex $comd [expr {$one + 1}]]
			# is it us?
			if {$failedserver == $ssid} {
				#yes, it's us.
				putloglev d * "We're dead, folks."
				firellbind $sck evnt "-" "ts6.dead" $::netname($sck)
				firellbind $sck evnt "-" "dead" $::netname($sck)
				firellbind - evnt "-" "dead" $sck $::netname($sck)
				return
			}
			# Mark all servers with an uplink in failedservers as split
			set slist [::ts6::quitstorm $sck [lindex $comd [expr {$one + 1}]] [lindex $comd [expr {$one + 2}]]]
			foreach {srv} $slist {
				::ts6::snote $sck x [format "!! NETSPLIT: %s (%s) has left the network (Server Quit: %s)" [tnda get "servers/$::netname($sck)/[ndaenc $srv]/name"] $srv [lindex $comd [expr {$one + 2}]]
				tnda unset "servers/$::netname($sck)/[ndaenc $srv]"
				foreach {uidd _} [tnda get "nick/$::netname($sck)"] {
					if {[string range $uidd 0 2] != $srv} {continue};# not a dead user
					foreach {chan _} [tnda get "userchan/$::netname($sck)/$uidd"] {
						firellbind $sck part "-" "-" [ndadec $chan] $uidd $::netname($sck)
#						firellbind $sck cquit "-" "-" [ndadec $chan] $uidd $::netname($sck)
						tnda set "userchan/$::netname($sck)/$uidd/$chan" 0
					}

					::ts6::snote $sck x [format "!! NETSPLIT: %s (%s) has quit due to netsplit (%s: %s)" [tnda get "nick/$::netname($sck)/$uidd"] $uidd [tnda get "servers/$::netname($sck)/[ndaenc $srv]/name"] [lindex $comd [expr {$one + 2}]]
					tnda unset "login/$::netname($sck)/$uidd"
					tnda unset "nick/$::netname($sck)/$uidd"
					tnda set "oper/$::netname($sck)/$uidd" 0
					tnda unset "ident/$::netname($sck)/$uidd"
					tnda unset "rhost/$::netname($sck)/$uidd"
					tnda unset "vhost/$::netname($sck)/$uidd"
					tnda unset "rname/$::netname($sck)/$uidd"
					tnda unset "ipaddr/$::netname($sck)/$uidd"
					tnda set "metadata/$::netname($sck)/$uidd" [list]
					tnda unset "certfps/$::netname($sck)/$uidd"
					firellbind $sck quit "-" "-" $uidd $::netname($sck)
				}
			}
		}

		"005" - "105" {
			foreach {tok} [lrange $comd 3 end] {
				foreach {key val} [split $tok "="] {
					if {$key == "PREFIX"} {
						# We're in luck! Server advertises its PREFIX in VERSION reply to servers.
						if {[tnda get "netinfo/$::netname($sck)/pfxissjoin"] == 1} {continue}
						set v [string range $val 1 end]
						set mod [split $v ")"]
						set modechar [split [lindex $mod 1] {}]
						set modepref [split [lindex $mod 0] {}]
						foreach {c} $modechar {x} $modepref {
							tnda set "netinfo/$::netname($sck)/prefix/$c" $x
						}
						foreach {x} $modechar {c} $modepref {
							tnda set "netinfo/$::netname($sck)/pfxchar/$c" $x
						}
					} elseif {$key == "SJOIN"} {
						# We're in luck! Server advertises its PREFIX in VERSION reply to servers.
						tnda set "netinfo/$::netname($sck)/pfxissjoin" 1
						set v [string range $val 1 end]
						set mod [split $v ")"]
						set modechar [split [lindex $mod 1] {}]
						set modepref [split [lindex $mod 0] {}]
						foreach {c} $modechar {x} $modepref {
							tnda set "netinfo/$::netname($sck)/prefix/$c" $x
						}
						foreach {x} $modechar {c} $modepref {
							tnda set "netinfo/$::netname($sck)/pfxchar/$c" $x
						}
					} elseif {$key == "CHANMODES"} {
						set spt [split $val ","]
						tnda set "netinfo/$::netname($sck)/chmban" [lindex $spt 0]
						tnda set "netinfo/$::netname($sck)/chmparm" [format "%s%s" [lindex $spt 0] [lindex $spt 1]]
						tnda set "netinfo/$::netname($sck)/chmpartparm" [lindex $spt 2]
						tnda set "netinfo/$::netname($sck)/chmnoparm" [lindex $spt 3]
					} else {
						tnda set "netinfo/$::netname($sck)/[ndaenc $key]" $val
					}
				}
			}
		}

		"PRIVMSG" {
			if {[::ts6::validchan $sck [lindex $comd 2]]} {
				set client chan
				set words [split $payload " "]
				set kword [lindex $words 0]
				if {[string index $payload 0] == "\001"} {
					set payload [string range $payload 1 end-1]
					set words [split $payload " "]
					set kword [lindex $words 0]
					set payload [join [lrange $words 1 end] " "]
					firellbind $sck ctcp - [string tolower $payload] [lindex $comd 0] [lindex $comd 2] $kword $payload
				} {
					set mpayload [join [lrange $words 1 end] " "]
					firellbind $sck pub - [string tolower $payload] [lindex $comd 0] [lindex $comd 2] $mpayload
					firellmbind $sck pubm - [string tolower $payload] [lindex $comd 0] [lindex $comd 2] $payload
				}
				#firellbind $sck notc "-" [string tolower [lindex [split $payload " "] 0]] [lindex $comd 2] [lindex $comd 0] [join [lrange [split $payload " "] 1 end] " "]
				#firellmbind $sck pnotcm $client [string tolower [lindex [split $payload " "] 0]] [lindex $comd 0] [join [lrange [split $payload " "] 1 end] " "]
#				firellbind $sck pubnotc-m "-" [string tolower [lindex [split $payload " "] 0]] [lindex $comd 2] [lindex $comd 0] [join [lrange [split $payload " "] 1 end] " "]
				#firellbind $sck "evnt" "-" "channotc" [lindex $comd 0] [lindex $comd 2] $payload
			} {
				set client [tnda get "intclient/$::netname($sck)/[lindex $comd 2]"]
				set words [split $payload " "]
				set kword [lindex $words 0]
				if {[string index $payload 0] == "\001"} {
					set payload [string range $payload 1 end-1]
					set words [split $payload " "]
					set kword [lindex $words 0]
					set payload [join [lrange $words 1 end] " "]
					firellbind $sck ctcp - [string tolower $kword] [lindex $comd 0] [% uid2nick [lindex $comd 2]] $kword $payload
				} {
					set mpayload [join [lrange $words 1 end] " "]
					firellbind $sck msg $client [string tolower $kword] [lindex $comd 0] $mpayload
					firellmbind $sck msgm $client [string tolower $payload] [lindex $comd 0] $payload
				}
				#firellbind $sck notc $client [string tolower [lindex [split $payload " "] 0]] [lindex $comd 0] [join [lrange [split $payload " "] 1 end] " "]
				#firellmbind $sck notcm $client [string tolower [lindex [split $payload " "] 0]] [lindex $comd 0] [join [lrange [split $payload " "] 1 end] " "]
				#firellbind $sck "evnt" "-" "privnotc" [lindex $comd 0] [lindex $comd 2] $payload
			}
		}

		"NOTICE" {
			if {![tnda get "netinfo/$::netname($sck)/connected"]} {return}
			if {[::ts6::validchan $sck [lindex $comd 2]]} {
				set client chan
				if {[string index $payload 0] == "\001"} {
					set payload [string range $payload 1 end-1]
					set words [split $payload " "]
					set kword [lindex $words 0]
					set payload [join [lrange $words 1 end] " "]
					firellbind $sck ctcr - [string tolower $payload] [lindex $comd 0] [lindex $comd 2] $kword $payload
				} {
					firellmbind $sck notc - [string tolower $payload] [lindex $comd 0] [lindex $comd 2] $payload
				}
				#firellbind $sck notc "-" [string tolower [lindex [split $payload " "] 0]] [lindex $comd 2] [lindex $comd 0] [join [lrange [split $payload " "] 1 end] " "]
				#firellmbind $sck pnotcm $client [string tolower [lindex [split $payload " "] 0]] [lindex $comd 0] [join [lrange [split $payload " "] 1 end] " "]
#				firellbind $sck pubnotc-m "-" [string tolower [lindex [split $payload " "] 0]] [lindex $comd 2] [lindex $comd 0] [join [lrange [split $payload " "] 1 end] " "]
				#firellbind $sck "evnt" "-" "channotc" [lindex $comd 0] [lindex $comd 2] $payload
			} {
				set client [tnda get "intclient/$::netname($sck)/[lindex $comd 2]"]
				if {[string index $payload 0] == "\001"} {
					set payload [string range $payload 1 end-1]
					set words [split $payload " "]
					set kword [lindex $words 0]
					set payload [join [lrange $words 1 end] " "]
					firellbind $sck ctcr - [string tolower $payload] [lindex $comd 0] [% uid2nick [lindex $comd 2]] $kword $payload
				} {
					firellmbind $sck notc - [string tolower $payload] [lindex $comd 0] [% uid2nick [lindex $comd 2]] $payload
				}
				#firellbind $sck notc $client [string tolower [lindex [split $payload " "] 0]] [lindex $comd 0] [join [lrange [split $payload " "] 1 end] " "]
				#firellmbind $sck notcm $client [string tolower [lindex [split $payload " "] 0]] [lindex $comd 0] [join [lrange [split $payload " "] 1 end] " "]
				#firellbind $sck "evnt" "-" "privnotc" [lindex $comd 0] [lindex $comd 2] $payload
			}
		}

		"MODE" {
			if {[lindex $comd 2] == [tnda get "nick/$::netname($sck)/[lindex $comd 0]"] || [lindex $comd 2] == [lindex $comd 0]} {
				foreach {c} [split [lindex $comd 3] {}] {
					switch -- $c {
						"+" {set state 1}
						"-" {set state 0}
						"o" {tnda set "oper/$::netname($sck)/[lindex $comd 0]" $state}
					}
				}
			}
		}

		"JOIN" {
			set chan [string map {/ [} [::base64::encode [string tolower [lindex $comd 3]]]]
			if {""==[tnda get "channels/$::netname($sck)/$chan/ts"]} {firellbind $sck create "-" "-" [lindex $comd 3] [lindex $comd 0] $::netname($sck)}
#			firellbind $sck join "-" "-" [lindex $comd 3] [lindex $comd 0] $::netname($sck)
			firellmbind $sck join - [format "%s %s!%s@%s" [lindex $comd 3] [% uid2nick [lindex $comd 0]] [% uid2ident [lindex $comd 0]] [% uid2host [lindex $comd 0]]] [lindex $comd 0] [lindex $comd 3]
			tnda set "channels/$::netname($sck)/$chan/ts" [lindex $comd 2]
			tnda set "userchan/$::netname($sck)/[lindex $comd 0]/$chan" 1
		}

		"BMASK" {
			# always +, no ctr and no state
			set adding [split $payload " "]
			set chan [ndaenc [lindex $comd 3]]
			if {[lindex $comd 2] > [tnda get "channels/$::netname($sck)/$chan/ts"]} {return} ;# send it packing.
			set type [lindex $comd 4]
			foreach {mask} $adding {
				::ts6::checkop [lindex $comd 0] [lindex $comd 3] [format "%s%s" + $type] $mask
				firellmbind $sck mode - [format "%s +%s" [lindex $comd 3] $type] [lindex $comd 0] [lindex $comd 3] "+$type" $mask
				#+ $type [lindex $comd 0] [lindex $comd 3] $mask $::netname($sck)
			}
		}

		"TMODE" {
			set ctr 4
			set state 1
			foreach {c} [split [lindex $comd 4] {}] {
				if {$c == "+"} {
					set state 1
				} elseif {$c == "-"} {
					set state 0
				} elseif {[string match [format "*%s*" $c] [tnda get "netinfo/$::netname($sck)/chmparm"]] || ($state&&[string match [format "*%s*" $c] [tnda get "netinfo/$::netname($sck)/chmpartparm"]])} {
					[expr {$state?"::ts6::checkop":"::ts6::checkdeop"}] [lindex $comd 0] [lindex $comd 3] [format "%s%s" [expr {$state?"+":"-"}] $c] [lindex $comd [incr ctr]]
					firellmbind $sck mode - [format "%s %s%s" [string tolower [lindex $comd 3]] [expr {$state ? "+" : "-"}] $c] [lindex $comd 0] [lindex $comd 3] [format "%s%s" [expr {$state?"+":"-"}] $c] [lindex $comd [incr ctr]]
				} else {
					[expr {$state?"::ts6::checkop":"::ts6::checkdeop"}] [lindex $comd 0] [lindex $comd 3] [format "%s%s" [expr {$state?"+":"-"}] $c] [lindex $comd [incr ctr]]
					firellmbind $sck mode - [format "%s %s%s" [string tolower [lindex $comd 3]] [expr {$state ? "+" : "-"}] $c] [lindex $comd 0] [lindex $comd 3] [format "%s%s" [expr {$state?"+":"-"}] $c] ""
#					firellmbind $sck mode "-" [expr {$state ? "+" : "-"}] $c [lindex $comd 0] [lindex $comd 3] ""
				}
			}
		}

		"SJOIN" {
			set chan [ndaenc [lindex $comd 3]]
			if {[string index [lindex $comd 4] 0] == "+"} {
				set four 5
				set ctr 4
				if {[string match "*l*" [lindex $comd 4]]} {incr four}
				if {[string match "*f*" [lindex $comd 4]]} {incr four}
				if {[string match "*j*" [lindex $comd 4]]} {incr four}
				if {[string match "*k*" [lindex $comd 4]]} {incr four}
				foreach {c} [split [lindex $comd 4] {}] {
					if {$c == "+"} {
						set state 1
					} elseif {$c == "-"} {
						# _NOTREACHED
						set state 0
					} elseif {[string match [format "*%s*" $c] [tnda get "netinfo/$::netname($sck)/chmparm"]] || ($state&&[string match [format "*%s*" $c] [tnda get "netinfo/$::netname($sck)/chmpartparm"]])} {
						[expr {$state?"::ts6::checkop":"::ts6::checkdeop"}] [lindex $comd 0] [lindex $comd 3] [format "%s%s" [expr {$state?"+":"-"}] $c] [lindex $comd [incr ctr]]
						firellmbind $sck mode - [format "%s %s%s" [string tolower [lindex $comd 3]] [expr {$state ? "+" : "-"}] $c] [lindex $comd 0] [lindex $comd 3] [format "%s%s" [expr {$state?"+":"-"}] $c] [lindex $comd [incr ctr]]
					} else {
						[expr {$state?"::ts6::checkop":"::ts6::checkdeop"}] [lindex $comd 0] [lindex $comd 3] [format "%s%s" [expr {$state?"+":"-"}] $c] [lindex $comd [incr ctr]]
						firellmbind $sck mode - [format "%s %s%s" [string tolower [lindex $comd 3]] [expr {$state ? "+" : "-"}] $c] [lindex $comd 0] [lindex $comd 3] [format "%s%s" [expr {$state?"+":"-"}] $c] ""
#						firellmbind $sck mode "-" [expr {$state ? "+" : "-"}] $c [lindex $comd 0] [lindex $comd 3] ""
					}
				}
			} {
				set four 4
			}
			tnda set "channels/$::netname($sck)/$chan/ts" [lindex $comd 2]
			# XXX: some servers don't give their SJOIN prefixes in PREFIX.
			# Solution? irca will, from the next release, support 005 portion "SJOIN=" formatted same as
			# PREFIX.
			# Also allow hardcoding.
			foreach {nick} [split $payload " "] {
				set un ""
				set uo ""
				set state uo
				set un [string range $nick end-8 end]
				set uo [string map [tnda get "netinfo/$::netname($sck)/prefix"] [string range $nick 0 end-9]]
#				foreach {c} [split $nick {}] {
#					if {[string is digit $c]} {set state un}
#					if {$state == "uo"} {set c [tnda get "netinfo/$::netname($sck)/prefix/$c"] ; }
#					if {"un"==$state} {append un $c}
#					if {"uo"==$state} {append uo $c}
#				}
				putloglev j [ndadec $chan] [format "JOIN %s by nicknumber %s (nick %s, modes %s)" [ndadec $chan] $nick [tnda get "nick/$::netname($sck)/$un"] $uo]
#				firellbind $sck join "-" "-" [lindex $comd 3] $un $::netname($sck)
				firellmbind $sck join - [format "%s %s!%s@%s" [lindex $comd 3] [% uid2nick $un] [% uid2ident $un] [% uid2host $un]] $un [lindex $comd 3]
				tnda set "userchan/$::netname($sck)/$un/$chan" 1
				if {""!=$uo} {tnda set "channels/$::netname($sck)/$chan/status/$un" $uo
					foreach {c} [split $uo {}] {
						::ts6::checkop [lindex $comd 0] [lindex $comd 3] [format "%s%s" + $c] $un
						firellmbind $sck mode - [format "%s +%s" [lindex $comd 3] $c] [lindex $comd 0] [lindex $comd 3] "+$c" $un
		#				firellbind $sck mode "-" + $c $un [lindex $comd 3] $un $::netname($sck)
					}
				}
			}

		}

		"PART" {
			set un [lindex $comd 0]
			firellmbind $sck part - [format "%s %s!%s@%s" [lindex $comd 2] [% uid2nick $un] [% uid2ident $un] [% uid2host $un]] $un [lindex $comd 2] [lindex $comd 3]
			firellbind $sck part "-" "-" [lindex $comd 2] [lindex $comd 0] [lindex $comd 3]
			set chan [string map {/ [} [::base64::encode [string tolower [lindex $comd 2]]]]
			tnda set "userchan/$::netname($sck)/[lindex $comd 0]/$chan" 0
			tnda set "channels/$::netname($sck)/$chan/status/[lindex $comd 0]" ""
		}

		"KICK" {
			firellbind $sck part "-" "-" [lindex $comd 2] [lindex $comd 3] [lindex $comd 4]
			set chan [string map {/ [} [::base64::encode [string tolower [lindex $comd 2]]]]
			tnda set "userchan/$::netname($sck)/[lindex $comd 3]/$chan" 0
		}

		"NICK" {
			firellmbind $sck nick "-" [format "%s %s" "*" [lindex $comd 2]] [lindex $comd 0] "*" [lindex $comd 2]
			tnda set "nick/$::netname($sck)/[lindex $comd 0]" [lindex $comd 2]
			tnda set "ts/$::netname($sck)/[lindex $comd 0]" [lindex $comd 3]
		}

		"EUID" {
			set num 9
			set ctr 1
			set oper 0
			set loggedin [lindex $comd 11]
			set realhost [lindex $comd 10]
			set modes [lindex $comd 5]
		#	puts stdout $comd
		#	puts stdout $modes
			if {[string first "o" $modes] != -1} {set oper 1}
			if {"*"!=$loggedin} {
				tnda set "login/$::netname($sck)/[lindex $comd $num]" $loggedin
			}
			if {"*"!=$realhost} {
				tnda set "rhost/$::netname($sck)/[lindex $comd $num]" $realhost
			} {
				tnda set "rhost/$::netname($sck)/[lindex $comd $num]" [lindex $comd 7]
			}
			tnda set "nick/$::netname($sck)/[lindex $comd $num]" [lindex $comd 2]
			tnda set "oper/$::netname($sck)/[lindex $comd $num]" $oper
			tnda set "ident/$::netname($sck)/[lindex $comd $num]" [lindex $comd 6]
			tnda set "vhost/$::netname($sck)/[lindex $comd $num]" [lindex $comd 7]
			tnda set "ipaddr/$::netname($sck)/[lindex $comd $num]" [lindex $comd 8]
			tnda set "ts/$::netname($sck)/[lindex $comd $num]" [lindex $comd 4]
			tnda set "rname/$::netname($sck)/[lindex $comd $num]" $payload
			#putloglev j * [format "New user at %s %s %s!%s@%s (IP address %s, vhost %s) :%s" $::netname($sck) [lindex $comd $num] [lindex $comd 2] [lindex $comd 6] [tnda get "rhost/$::netname($sck)/[lindex $comd $num]"] [lindex $comd 8] [tnda get "vhost/$::netname($sck)/[lindex $comd $num]"] $payload]
			firellbind $sck conn "-" "-" [lindex $comd $num]
		}

		"KLINE" {putloglev k * [format "KLINE: %s" $line]}
		"BAN" {putloglev k * [format "BAN: %s" $line]}

		"ENCAP" {
			switch -nocase -- [lindex $comd 3] {
				"SASL" {
					# we have to support sasl messages, so...
					firellbind $sck encap - "sasl" [lrange $comd 4 end]
					#don't bother
				}
				"KLINE" {
					putloglev k * [format "KLINE: %s" $line]
				}
				"SU" {
					if {$payload == ""} {set payload [lindex $comd 5]}
					tnda set "login/$::netname($sck)/[lindex $comd 4]" $payload
					if {$payload == ""} {firellbind $sck logout "-" "-" [lindex $comd 4]} {firellbind $sck login "-" "-" [lindex $comd 4] $payload}
				}
				"CERTFP" {
					tnda set "certfps/$::netname($sck)/[lindex $comd 0]" $payload
					firellbind $sck encap "-" "certfp" [lindex $comd 0] $payload
				}
				"METADATA" {
					switch -nocase -- [lindex $comd 4] {
						"ADD" {
							tnda set "metadata/$::netname($sck)/[lindex $comd 5]/[ndcenc [lindex $comd 6]]" $payload
							firellbind $sck encap "-" "metadata.[string tolower [lindex $comd 6]]" [lindex $comd 5] $payload
							firellbind $sck mark "-" [lindex $comd 6] [lindex $comd 5] $payload
						}
						"DELETE" {
							tnda unset "metadata/$::netname($sck)/[lindex $comd 5]/[ndcenc $payload]"
							firellbind $sck encap "-" "metadata.[string tolower $payload]" [lindex $comd 5] ""
							firellbind $sck mark "-" $payload [lindex $comd 5] ""
							# WARNING!!!! Pick ONE. The official scripts use MARK; you should too.
						}
					}
				}
			}
		}

		"TOPIC" {
			firellbind $sck topic "-" "-" [lindex $comd 2] [join $payload " "]
		}
		"QUIT" {
			if {![string is digit [string index [lindex $comd 0] 0]]} {
				set ocomd [lrange $comd 1 end]
				set on [lindex $comd 0]
				set comd [list [::ts6::nick2uid $::netname($sck) $on] {*}$ocomd]
				putloglev k * [format "Uh-oh, netsplit! %s -> %s has split" $on [::ts6::nick2uid $::netname($sck) $on]]
			}
			foreach {chan _} [tnda get "userchan/$::netname($sck)/[lindex $comd 0]"] {
				firellbind $sck part "-" "-" [ndadec $chan] [lindex $comd 0] $::netname($sck)
				tnda set "userchan/$::netname($sck)/[lindex $comd 0]/$chan" 0
				tnda set "channels/$::netname($sck)/$chan/status/[lindex $comd 0]" ""
			}

			tnda unset "login/$::netname($sck)/[lindex $comd 0]"
			tnda unset "nick/$::netname($sck)/[lindex $comd 0]"
			tnda set "oper/$::netname($sck)/[lindex $comd 0]" 0
			tnda unset "ident/$::netname($sck)/[lindex $comd 0]"
			tnda unset "rhost/$::netname($sck)/[lindex $comd 0]"
			tnda unset "vhost/$::netname($sck)/[lindex $comd 0]"
			tnda unset "rname/$::netname($sck)/[lindex $comd 0]"
			tnda unset "ipaddr/$::netname($sck)/[lindex $comd 0]"
			tnda set "metadata/$::netname($sck)/[lindex $comd 0]" [list]
			tnda unset "certfps/$::netname($sck)/[lindex $comd 0]"
			firellbind $sck quit "-" "-" [lindex $comd 0] $::netname($sck)
		}

		"KILL" {
			foreach {chan _} [tnda get "userchan/$::netname($sck)/[lindex $comd 2]"] {
				firellbind $sck part "-" "-" [ndadec $chan] [lindex $comd 2]
				tnda set "userchan/$::netname($sck)/[lindex $comd 2]/$chan" 0
			}
			tnda unset "login/$::netname($sck)/[lindex $comd 2]"
			tnda unset "nick/$::netname($sck)/[lindex $comd 2]"
			tnda set "oper/$::netname($sck)/[lindex $comd 2]" 0
			tnda unset "ident/$::netname($sck)/[lindex $comd 2]"
			tnda unset "ipaddr/$::netname($sck)/[lindex $comd 2]"
			tnda unset "rhost/$::netname($sck)/[lindex $comd 2]"
			tnda unset "vhost/$::netname($sck)/[lindex $comd 2]"
			tnda unset "rname/$::netname($sck)/[lindex $comd 2]"
			tnda set "metadata/$::netname($sck)/[lindex $comd 2]" [list]
			tnda unset "certfps/$::netname($sck)/[lindex $comd 2]"
			firellbind $sck quit "-" "-" [lindex $comd 2] $::netname($sck)
		}

		"ERROR" {
			putloglev s * "Recv'd an ERROR $payload from $::netname($sck)"
		}

		"WHOIS" {
			# Usually but not always for a local client.
			set num [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
			append num [::ts6::b64e $::sid($sck)]
			set targ [::ts6::nick2uid $::netname($sck) $payload]
			if {[tnda get "nick/$::netname($sck)/$targ"] == ""} {
				putl $sck [format ":%s 401 %s %s :No such user." $num [lindex $comd 0] $payload]
			} else {
				putl $sck [format ":%s 311 %s %s %s %s * :%s" $num [lindex $comd 0] [tnda get "nick/$::netname($sck)/$targ"] [tnda get "ident/$::netname($sck)/$targ"] [tnda get "vhost/$::netname($sck)/$targ"] [tnda get "rname/$::netname($sck)/$targ"]]
			}
			putl $sck [format ":%s 318 %s %s :End of /WHOIS list." $num [lindex $comd 0] $payload]
		}

		"CAPAB" {
			tnda set "netinfo/$::netname($sck)/euid" 0
			foreach {cw} [split $payload " "] {
				if {$cw == "EUID"} {tnda set "netinfo/$::netname($sck)/euid" 1}
			}
			tnda set "netinfo/$::netname($sck)/connected" 1
		}

		"PING" {
			set num [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
			append num [::ts6::b64e $::sid($sck)]
			if {[lindex $comd 3]==""} {set pong [lindex $comd 0]} {set pong [lindex $comd 3]}
			putl $sck [format ":%s PONG %s %s" $num $pong [lindex $comd 2]]
		}
	}
	} erreur]
	if {$erreno != 0} {puts stdout [join [list $erreno $erreur] " "]}
}

# irrelevant parameters should simply be ignored.
proc ::ts6::login {sck {osid "42"} {password "link"} {servname "net"} {servername services.invalid} {cfg {}}} {
	set num [string repeat "0" [expr {3-[string length [::ts6::b64e $osid]]}]]
	append num [::ts6::b64e $osid]
	global netname sid sock nettype socksid snames
	dictassign $cfg euid useeuid gecos gecos
	set snames($sck) $servername
	set netname($sck) $servname
	set nettype($servname) ts6
	set sock($servname) $sck
	set sid($sck) $osid
	set sid($servname) $osid
	tnda set "netinfo/$::netname($sck)/connected" 0
	tnda set "netinfo/$::netname($sck)/euid" 0
	#if {$halfops == ""} {tnda set "pfx/halfop" v} {tnda set "pfx/halfop" $halfops}
	#if {![info exists ::ts6(ownermode)]} {tnda set "pfx/owner" o} {tnda set "pfx/owner" $ownermode)}
	#if {![info exists ::ts6(protectmode)]} {tnda set "pfx/protect" o} {tnda set "pfx/protect" $protectmode}
	if {$useeuid == ""} {tnda set "netinfo/$::netname($sck)/euid" 1} {tnda set "netinfo/$::netname($sck)/euid" $useeuid}
	
	putl $sck "PASS $password TS 6 :$num"
	putl $sck "CAPAB :UNKLN BAN KLN RSFNC EUID ENCAP IE EX CLUSTER EOPMOD SVS SERVICES QS"
	putl $sck "SERVER $servername 1 :chary.tcl for Eggdrop and related bots"
	putl $sck "SVINFO 6 6 0 :[clock format [clock seconds] -format %s]"
	putl $sck ":$num VERSION"
#	llbind $sck mode - "* +*" ::ts6::checkop
#	llbind $sck mode - "* -*" ::ts6::checkdeop

	chan event $sck readable [list ::ts6::irc-main $sck]
}

#source services.conf

proc ::ts6::nick2uid {sck nick} {
	foreach {u n} [tnda get "nick/$::netname($sck)"] {
		if {[string tolower $n] == [string tolower $nick]} {return $u}
	}
	return ""
}
proc ::ts6::intclient2uid {sck nick} {
	foreach {u n} [tnda get "intclient/$::netname($sck)"] {
		if {[string tolower $n] == [string tolower $nick]} {return $u}
	}
	return ""
}
proc ::ts6::uid2nick {sck u} {
	return [tnda get "nick/$::netname($sck)/$u"]
}
proc ::ts6::uid2rname {sck u} {
	return [tnda get "rname/$::netname($sck)/$u"]
}
proc ::ts6::uid2rhost {sck u} {
	return [tnda get "rhost/$::netname($sck)/$u"]
}
proc ::ts6::uid2host {sck u} {
	return [tnda get "vhost/$::netname($sck)/$u"]
}
proc ::ts6::uid2ident {sck u} {
	return [tnda get "ident/$::netname($sck)/$u"]
}
proc ::ts6::nick2host {sck nick} {
	return [tnda get "vhost/$::netname($sck)/[nick2uid $netname $nick]"]
}
proc ::ts6::nick2ident {sck nick} {
	return [tnda get "ident/$::netname($sck)/[nick2uid $netname $nick]"]
}
proc ::ts6::nick2rhost {sck nick} {
	return [tnda get "rhost/$::netname($sck)/[nick2uid $netname $nick]"]
}
proc ::ts6::nick2ipaddr {sck nick} {
	return [tnda get "ipaddr/$::netname($sck)/[nick2uid $netname $nick]"]
}
proc ::ts6::getts {sck chan} {
	return [tnda get "channels/$::netname($sck)/[ndaenc $chan]/ts"]
}
proc ::ts6::getpfx {sck chan nick} {
	return [tnda get "channels/$::netname($sck)/[ndaenc $chan]/status/[::ts6::nick2uid $netname $nick]"]
}
proc ::ts6::getupfx {sck chan u} {
	return [tnda get "channels/$::netname($sck)/[ndaenc $chan]/status/$u"]
}
proc ::ts6::getpfxchars {sck modes} {
	set o ""
	foreach {c} [split $modes {}] {
		append o [nda get "netinfo/$::netname($sck)/prefix/$c"]
	}
	return $o
}
proc ::ts6::getmetadata {sck nick metadatum} {
	return [tnda get "metadata/$::netname($sck)/[::ts6::nick2uid $netname $nick]/[ndcenc $metadatum]"]
}
proc ::ts6::getcertfp {sck nick} {
	return [tnda get "certfps/$::netname($sck)/[::ts6::nick2uid $netname $nick]"]
}

proc ::ts6::checkop {f t m p} {
	set n [curctx net]
	set mc [string index $m 1]
	puts stdout [format ":%s MODE %s %s %s" $f $t $m $p]
	if {[tnda get "netinfo/$n/pfxchar/$mc"]==""} {::ts6::handlemode $f $t $m $p;return}
putloglev d * "up $mc $f $t $p $n"
  set chan [string map {/ [} [::base64::encode [string tolower $t]]]
  tnda set "channels/$n/$chan/status/$p" [format {%s%s} [string map [list $mc ""] [tnda get "channels/$n/$chan/status/$p"]] $mc]
}

proc ::ts6::checkdeop {f t m p} {
	set n [curctx net]
	set mc [string index $m 1]
	puts stdout [format ":%s MODE %s %s %s" $f $t $m $p]
	if {[tnda get "netinfo/$n/pfxchar/$mc"]==""} {::ts6::handlemode $f $t $m $p;return}
putloglev d * "down $mc $f $t $p $n"
  set chan [string map {/ [} [::base64::encode [string tolower $t]]]
  tnda set "channels/$n/$chan/status/$p" [string map [list $mc ""] [tnda get "channels/$n/$chan/status/$p"]]
}

proc ::ts6::handlemode {from t mode parm} {
	set n [curctx net]
	set chan [string map {/ [} [::base64::encode [string tolower $t]]]
	puts stdout [format ":%s MODE %s %s %s" $from $t $mode $parm]
	if {[string index $mode 0] == "+"} {set state 1} {set state 0}
	set mc [string index $mode 1]
	if {$state} {
		if {[lsearch -exact [split [tnda get "netinfo/$n/chmban"] {}] $mc] == -1} {tnda set "channels/$n/$chan/mode" [format {%s%s} [string map [list $mc ""] [tnda get "channels/$n/$chan/mode"]] $mc]}
		if {$parm != ""} {
			if {[lsearch -exact [split [tnda get "netinfo/$n/chmban"] {}] $mc] != -1} {
				set ban [tnda get "channels/$n/$chan/modes/[ndcenc $mc]"]
				lappend ban $parm
				tnda set "channels/$n/$chan/modes/[ndcenc $mc]" $ban
			} {
				tnda set "channels/$n/$chan/modes/[ndcenc $mc]" $parm
			}
		}
	} {
		if {[lsearch -exact [split [tnda get "netinfo/$n/chmban"] {}] $mc] == -1} {tnda set "channels/$n/$chan/mode" [string map [list $mc ""] [tnda get "channels/$n/$chan/mode"]]}
		if {$parm != "" || [lsearch -exact [split [tnda get "netinfo/$n/chmpartparm"] {}] $mc] != -1} {
			if {[lsearch -exact [split [tnda get "netinfo/$n/chmban"] {}] $mc] != -1} {
				set ban [tnda get "channels/$n/$chan/modes/[ndcenc $mc]"]
				lappend ban $parm
				tnda set "channels/$n/$chan/modes/[ndcenc $mc]" $ban
			} {
				if {$parm == ""} {
					tnda unset "channels/$n/$chan/modes/[ndcenc $mc]"
				} {
					tnda set "channels/$n/$chan/modes/[ndcenc $mc]" $parm
				}
			}
		}
	}
	puts stdout [format "Now, the state machine for $t looks like:"]
	puts stdout [tnda get "channels/$n/$chan"]
	puts stdout [tnda get "userchan/$n/$chan"]
}

proc ::ts6::putnow {sck intclient msg} {
	if {$intclient != ""} {
		set nick [% intclient2uid $intclient]
	} {
		set nick $sid($sck)
	}
	putl $sck [format ":%s %s" $nick $msg]
}
proc ::ts6::uid2intclient {sck u} {
	return [tnda get "intclient/$::netname($sck)/$u"]
}

proc ::ts6::getfreeuid {sck} {
set work 1
set cns [list]
foreach {_ cnum} [tnda get "intclient/$::netname($sck)"] {lappend cns $cnum}
while {0!=$work} {set num [expr {[rand 30000]+10000}];if {[lsearch -exact $cns $num]==-1} {set work 0}}
return $num
}

namespace export *
namespace ensemble create
}

#ts6 login $::sock
