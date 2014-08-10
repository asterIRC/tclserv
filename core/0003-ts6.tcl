# Because TS6 ircds are highly configurable, we start in Charybdis mode without
# an idea what modes are permissible. This is to aid ChanServ.
if {![info exists ::ts6(halfops)]} {set halfops 0} {set halfops $::ts6(halfops)}
if {![info exists ::ts6(euid)]} {set ::ts6(euid) 1}

namespace eval ts6 {
set sid [string repeat "0" [expr {3-[string length [b64e $::numeric]]}]]
append sid [b64e $::numeric]

proc ::ts6::sendUid {sck nick ident host dhost uid {realname "* Unknown *"} {modes "+oiS"} {server ""}} {
	if {""==$server} {set server $::numeric}
	set sid [string repeat "0" [expr {3-[string length [b64e $server]]}]]
	append sid [b64e $server]
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	if {!$::ts6(euid)} {
		set sl [format ":%s UID %s 1 %s %s %s 0 %s%s :%s" $sid $nick [clock format [clock seconds] -format %s] $modes $ident $host $sid $sendnn $realname]
	} {
		set sl [format ":%s EUID %s 1 %s %s %s 0 %s%s * * :%s" $sid $nick [clock format [clock seconds] -format %s] $modes $ident $host $sid $sendnn $realname]
	}
	tnda set "intclient/$::netname($sck)/$::netname($::sock)/${sid}${sendnn}" $uid
	puts $sck $sl
}

proc ::ts6::sendSid {sck sname sid {realname "In use by Services"}} {
	set sl [format ":%s SID %s 1 %s :%s" [b64e $::sid] $sname [b64e $sid] $realname]
	puts $sck $sl
}

proc ::ts6::privmsg {sck uid targ msg} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format ":%s%s PRIVMSG %s :%s" $sid $sendnn $targ $msg]
}

proc ::ts6::kick {sck uid targ tn msg} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format ":%s%s KICK %s %s :%s" $sid $sendnn $targ $tn $msg]
}

proc ::ts6::notice {sck uid targ msg} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format ":%s%s NOTICE %s :%s" $sid $sendnn $targ $msg]
}

proc ::ts6::setacct {sck targ msg} {
	global sid
	puts $sck [format ":%s ENCAP * SU %s %s" $sid $targ $msg]
	tnda set "login/$::netname($sck)/$::netname($::sock)/$targ" $msg
}

proc ::ts6::bind {type client comd script} {
	set moretodo 1
	while {0!=$moretodo} {
		set bindnum [rand 1 10000000]
		if {[tnda get "binds/$type/$client/$comd/$bindnum"]!=""} {} {set moretodo 0}
	}
	tnda set "binds/$type/$client/$comd/$::netname($::sock)/$bindnum" $script
	return $bindnum
}

proc ::ts6::unbind {type client comd id} {
	tnda set "binds/$type/$client/$comd/$::netname($::sock)/$id" ""
}

proc ::ts6::putmode {sck uid targ mode parm ts} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format "%s%s M %s %s %s" $sid $sendnn $targ $mode $parm $ts]
}

proc ::ts6::putjoin {sck uid targ ts} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format "%s B %s %s %s%s:o" $sid $targ $ts $sid $sendnn]
	puts stdout [format "%s B %s %s %s%s:o" $sid $targ $ts $sid $sendnn]

}

proc ::ts6::callbind {sock type client comd args} {
	puts stdout [tnda get "binds/mode"]
	if {""!=[tnda get "binds/$sock/$type/$client/$comd"]} {
		foreach {id script} [tnda get "binds/$sock/$type/$client/$comd"] {
			$script [lindex $args 0] [lrange $args 1 end]
		};return
	}
	#if {""!=[tnda get "binds/$type/-/$comd"]} {foreach {id script} [tnda get "binds/$type/-/$comd"] {$script [lindex $args 0] [lrange $args 1 end]};return}
}

proc ::ts6::irc-main {sck} {
	global sid sock
	if {[eof $sck]} {close $sck}
	gets $sck line
	set line [string trim $line "\r\n"]
	set one [string match ":*" $line]
	set gotsplitwhere [string first " :" $line]
	if {$gotsplitwhere==-1} {set comd [split $line " "]} {set comd [split [string range $line 1 [expr {$gotsplitwhere - 1}]] " "]}
	set payload [split [string range $line [expr {$gotsplitwhere + 2}] end] " "]
	puts stdout [join $comd " "]
	switch -nocase -- [lindex $comd $one] {
		"005" {
			foreach {tok} [lrange $comd [expr {$comd+1}] end] {
				foreach {key val} [split $tok "="] {
					if {$key == "PREFIX"} {
						# We're in luck! Server advertises its PREFIX in VERSION reply to servers.
						set v [string range $val 1 end]
						set mod [split $v ")"]
						set modechar [split [lindex $mod 0] {}]
						set modepref [split [lindex $mod 1] {}]
						foreach {c} $modechar {x} $modepref {
							tnda set "ts6/$::netname($sck)/prefix/$::netname($::sock)/$modepref" $modechar
						}
					}
				}
			}
		}

		"105" {
			foreach {tok} [lrange $comd [expr {$comd+1}] end] {
				foreach {key val} [split $tok "="] {
					if {$key == "PREFIX"} {
						# We're in luck! Server advertises its PREFIX in VERSION reply to servers.
						set v [string range $val 1 end]
						set mod [split $v ")"]
						set modechar [split [lindex $mod 0] {}]
						set modepref [split [lindex $mod 1] {}]
						foreach {c} $modechar {x} $modepref {
							tnda set "ts6/$::netname($sck)/prefix/$::netname($::sock)/$modepref" $modechar
						}
					}
				}
			}
		}

		"PRIVMSG" {
			if {[string index [lindex $comd 2] 0] == "#"} {
				set client chan
				callbind $sck pub "-" [string tolower [lindex $payload 0]] [lindex $comd 2] [lindex $comd 0] [lrange $payload 1 end]
				callbind $sck evnt "-" "chanmsg" [lindex $comd 0] [lindex $comd 2] [lrange $payload 0 end] ts6
			} {
				set client [tnda get "intclient/$::netname($sck)/[lindex $comd 2]"]
				callbind $sck msg $client [string tolower [lindex $payload 0]] [lindex $comd 0] [lrange $payload 1 end]
				callbind $sck "evnt" "-" "privmsg" [lindex $comd 0] [lindex $comd 2] [lrange $payload 0 end] ts6
			}
		}

		"NOTICE" {
			if {[string index [lindex $comd 2] 0] == "#"} {
				set client chan
				callbind $sck pubnotc "-" [string tolower [lindex $payload 0]] [lindex $comd 2] [lindex $comd 0] [lrange $payload 1 end]
				callbind $sck pubnotc-m "-" [string tolower [lindex $payload 0]] [lindex $comd 2] [lindex $comd 0] [lrange $payload 1 end]
				callbind $sck "evnt" "-" "channotc" [lindex $comd 0] [lindex $comd 2] [lrange $payload 0 end] ts6
			} {
				set client [tnda get "intclient/$::netname($sck)/[lindex $comd 2]"]
				callbind $sck notc $client [string tolower [lindex $payload 0]] [lindex $comd 0] [lrange $payload 1 end]
				callbind $sck "evnt" "-" "privnotc" [lindex $comd 0] [lindex $comd 2] [lrange $payload 0 end] ts6
			}
		}

		"MODE" {
			if {[lindex $comd 3] == [tnda get "nick/$::netname($sck)/[lindex $comd 0]"]} {
				foreach {c} [split [lindex $comd 4] {}] {
					switch -- $c {
						"+" {set state 1}
						"-" {set state 0}
						"o" {tnda set "oper/$::netname($sck)/$::netname($::sock)/[lindex $comd 0]" $state}
					}
				}
			}
		}

		"JOIN" {
			set chan [string map {/ [} [::base64::encode [string tolower [lindex $comd 2]]]]
			if {""==[tnda get "channels/$::netname($sck)/$chan/ts"]} {callbind $sck create "-" "-" [lindex $comd 2] [lindex $comd 0]}
			callbind $sck join "-" "-" [lindex $comd 2] [lindex $comd 0]
			tnda set "channels/$::netname($sck)/$chan/$::netname($::sock)/ts" [lindex $comd 3]
		}

		"TMODE" {
			set ctr 3
			foreach {c} [split [lindex $comd 3] {}] {
				switch -regexp -- $c {
					"\\\+" {set state 1}
					"\\\-" {set state 0}
					"[CcDdiMmNnOpPQRrSsTtZz]" {callbind $sck mode "-" [expr {$state ? "+" : "-"}] $c [lindex $comd 0] [lindex $comd 2] $::netname($sck)}
					"[beljfqIaykohv]" {callbind $sck mode "-" [expr {$state ? "+" : "-"}] $c [lindex $comd 0] [lindex $comd 2] [lindex $comd [incr ctr]] $::netname($sck)}
				}
			}
		}

		"SJOIN" {
			set chan [string map {/ [} [::base64::encode [string tolower [lindex $comd 3]]]]
			if {[string index [lindex $comd 4] 0] == "+"} {
				set four 5
				if {[string match "*l*" [lindex $comd 4]]} {incr four}
				if {[string match "*f*" [lindex $comd 4]]} {incr four}
				if {[string match "*j*" [lindex $comd 4]]} {incr four}
				if {[string match "*k*" [lindex $comd 4]]} {incr four}
			} {
				set four 4
			}
			tnda set "channels/$::netname($sck)/$chan/$::netname($::sock)/ts" [lindex $comd 2]
			foreach {nick} [split [lindex $comd $four] " "] {
				set un ""
				set uo ""
				set state uo
				foreach {c} [split $nick {}] {
					if {[string is integer $c]} {set state un}
					if {$state == "uo"} {set c [tnda get "ts6/$::netname($sck)/prefixe/$c"]}
					append $state $c
				}
				if {""!=$uo} {tnda set "channels/$::netname($sck)/$chan/modes/$::netname($::sock)/$un" $uo}
				callbind $sck join "-" "-" [lindex $comd 3] $un
			}

		}

		"PART" {
			callbind $sck part "-" "-" [lindex $comd 2] [lindex $comd 0]
		}

		"KICK" {
			callbind $sck part "-" "-" [lindex $comd 2] [lindex $comd 3]
		}

		"EUID" {
			set num 9
			set ctr 1
			set oper 0
			set loggedin [lindex $comd 11]
			set realhost [lindex $comd 10]
			set modes [lindex $comd 4]
			if {[string match "*o*" $modes]} {set oper 1}
			if {"*"!=$loggedin} {
				tnda set "login/$::netname($sck)/$::netname($::sock)/[lindex $comd $num]" $loggedin
			}
			if {"*"!=$realhost} {
				tnda set "rhost/$::netname($sck)/$::netname($::sock)/[lindex $comd $num]" $realhost
			} {
				tnda set "rhost/$::netname($sck)/$::netname($::sock)/[lindex $comd $num]" [lindex $comd 6]
			}
			tnda set "nick/$::netname($sck)/$::netname($::sock)/[lindex $comd $num]" [lindex $comd 2]
			tnda set "oper/$::netname($sck)/$::netname($::sock)/[lindex $comd $num]" $oper
			tnda set "ident/$::netname($sck)/$::netname($::sock)/[lindex $comd $num]" [lindex $comd 5]
			tnda set "vhost/$::netname($sck)/$::netname($::sock)/[lindex $comd $num]" [lindex $comd 6]
			callbind $sck conn "-" "-" [lindex $comd $num]
		}

		"QUIT" {
			tnda set "login/$::netname($sck)/$::netname($::sock)/[lindex $comd 0]" ""
			tnda set "nick/$::netname($sck)/$::netname($::sock)/[lindex $comd 0]" ""
			tnda set "oper/$::netname($sck)/$::netname($::sock)/[lindex $comd 0]" 0
			tnda set "ident/$::netname($sck)/$::netname($::sock)/[lindex $comd 0]" ""
			tnda set "rhost/$::netname($sck)/$::netname($::sock)/[lindex $comd 0]" ""
			tnda set "vhost/$::netname($sck)/$::netname($::sock)/[lindex $comd 0]" ""
		}

		"KILL" {
			tnda set "login/$::netname($sck)/$::netname($::sock)/[lindex $comd 2]" ""
			tnda set "nick/$::netname($sck)/$::netname($::sock)/[lindex $comd 2]" ""
			tnda set "oper/$::netname($sck)/$::netname($::sock)/[lindex $comd 2]" 0
			tnda set "ident/$::netname($sck)/$::netname($::sock)/[lindex $comd 2]" ""
			tnda set "rhost/$::netname($sck)/$::netname($::sock)/[lindex $comd 2]" ""
			tnda set "vhost/$::netname($sck)/$::netname($::sock)/[lindex $comd 2]" ""
		}

		"PING" {
			puts $sck ":$sid PONG [lindex $comd 3] [lindex $comd 2]"
		}
	}
}

proc ::ts6::login {sck {sid $::numeric} {password $::password}} {
	set num [string repeat "0" [expr {3-[string length [b64e $sid]]}]]
	append num [b64e $::numeric]
	puts $sck "PASS $password TS 6 :$num"
	puts $sck "SERVER $servername 1 :Services for IRC Networks"
	puts $sck "SVINFO 6 6 0 :[clock format [clock seconds] -format %s]"
	puts $sck ":$sid VERSION"
}


#source services.conf
namespace export *
namespace ensemble create
}

#ts6 login $::sock
