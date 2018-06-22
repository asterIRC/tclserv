namespace eval ts6 {
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


if {[info commands putdcc] != [list putdcc]} {
	proc putdcc {idx text} {
		puts $idx $text
	}
}

if {[info commands putcmdlog] != [list putcmdlog]} {
	proc putcmdlog {text} {
		puts -nonewline stdout "(command) "
		puts stdout $text
	}
}

namespace eval ts6 {

proc ::ts6::sendUid {sck nick ident host dhost uid {realname "* Unknown *"} {modes "+oiS"} {server ""}} {
	if {""==$server} {set server $::sid($sck)}
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $server]]}]]
	append sid [::ts6::b64e $server]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	if {![tnda get "ts6/$::netname($sck)/euid"]} {
		set sl [format ":%s UID %s 1 %s %s %s %s 0 %s%s :%s" $sid $nick [clock format [clock seconds] -format %s] $modes $ident $host $sid $sendnn $realname]
	} {
		set sl [format ":%s EUID %s 1 %s %s %s %s 0 %s%s %s * :%s" $sid $nick [clock format [clock seconds] -format %s] $modes $ident $dhost $sid $sendnn $host $realname]
	}
	tnda set "intclient/$::netname($sck)/${sid}${sendnn}" $uid
	tnda set "nick/$::netname($sck)/${sid}${sendnn}" $nick
	putdcc $sck $sl
}

proc ::ts6::topic {sck uid targ topic} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
	append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putdcc $sck [format ":%s%s TOPIC %s :%s" $sid $sendnn $targ $topic]
}

proc ::ts6::setnick {sck uid newnick} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
	append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putdcc $sck [format ":%s%s NICK %s :%s" $sid $sendnn $newnick [clock format [clock seconds] -format %s]]
}

proc ::ts6::sethost {sck targ topic} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
	append sid [::ts6::b64e $::sid($sck)]
	if {![tnda get "ts6/$::netname($sck)/euid"]} {
		putdcc $sck [format ":%s ENCAP * CHGHOST %s %s" $sid $targ $topic]
	} {
		putdcc $sck [format ":%s CHGHOST %s %s" $sid $targ $topic]
	}
}

proc ::ts6::sendSid {sck sname sid {realname "In use by Services"}} {
set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
append sid [::ts6::b64e $::sid($sck)]
	set sl [format ":%s SID %s 1 %s :%s" [::ts6::b64e $sid] $sname [::ts6::b64e $sid] $realname]
	putdcc $sck $sl
}

proc ::ts6::privmsg {sck uid targ msg} {
set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putdcc $sck [format ":%s%s PRIVMSG %s :%s" $sid $sendnn $targ $msg]
}

proc ::ts6::metadata {sck targ direction type {msg ""}} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
	append sid [::ts6::b64e $::sid($sck)]
	if {[string toupper $direction] != "ADD" && [string toupper $direction] != "DELETE"} {putcmdlog "failed METADATA attempt (invalid arguments)";return} ;#no that didn't work
	if {[string toupper $direction] == "ADD"} {
		tnda set "metadata/$::netname($sck)/$targ/[ndaenc $type]" $msg
		putdcc $sck [format ":%s ENCAP * METADATA %s %s %s :%s" $sid [string toupper $direction] $targ [string toupper $type] $msg]
	}
	if {[string toupper $direction] == "DELETE"} {
		tnda set "metadata/$::netname($sck)/$targ/[ndaenc $type]" ""
		putdcc $sck [format ":%s ENCAP * METADATA %s %s :%s" $sid [string toupper $direction] $targ [string toupper $type]]
	}
}

proc ::ts6::kick {sck uid targ tn msg} {
set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putdcc $sck [format ":%s%s KICK %s %s :%s" $sid $sendnn $targ $tn $msg]
}

proc ::ts6::notice {sck uid targ msg} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putdcc $sck [format ":%s%s NOTICE %s :%s" $sid $sendnn $targ $msg]
}

proc ::ts6::part {sck uid targ msg} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putdcc $sck [format ":%s%s PART %s :%s" $sid $sendnn $targ $msg]
}

proc ::ts6::quit {sck uid msg} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putdcc $sck [format ":%s%s QUIT :%s" $sid $sendnn $msg]
	tnda set "intclient/$::netname($sck)/${sid}${sendnn}" ""
	tnda set "nick/$::netname($sck)/${sid}${sendnn}" ""
}

proc ::ts6::setacct {sck targ msg} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	putdcc $sck [format ":%s ENCAP * SU %s %s" $sid $targ $msg]
	tnda set "login/$::netname($sck)/$targ" $msg
}

proc ::ts6::putmotd {sck targ msg} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	putdcc $sck [format ":%s 372 %s :- %s" $sid $targ $msg]
}

proc ::ts6::putmotdend {sck targ} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	putdcc $sck [format ":%s 376 %s :End of global MOTD." $sid $targ]
}

proc ::ts6::putmode {sck uid targ mode parm ts} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putdcc $sck [format ":%s%s TMODE %s %s %s %s" $sid $sendnn $ts $targ $mode $parm]
}

proc ::ts6::putjoin {sck uid targ ts} {
	set sid [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]];append sid [::ts6::b64e $::sid($sck)]
	set sendid [::ts6::b64e $uid]
	set sendnn [string repeat "A" [expr {6-[string length $sendid]}]]
	append sendnn $sendid
	putdcc $sck [format ":%s SJOIN %s %s + :%s%s" $sid $ts $targ $sid $sendnn]
}

proc ::ts6::irc-main {sck} {
	global sid sock
	if {[eof $sck]} {close $sck}
	gets $sck line
	set line [string trim $line "\r\n"]
	set one [string match ":*" $line]
	set line [string trimleft $line ":"]
	set gotsplitwhere [string first " :" $line]
	if {$gotsplitwhere==-1} {set comd [split $line " "]} {set comd [split [string range $line 0 [expr {$gotsplitwhere - 1}]] " "]}
	set payload [split [string range $line [expr {$gotsplitwhere + 2}] end] " "]
	#putcmdlog [join $comd " "]
	if {[lindex $comd 0] == "PING"} {putdcc $sck "PONG $::servername :$payload"}
	if {[lindex $comd 0] == "SERVER"} {putdcc $sck "VERSION"}
	switch -nocase -- [lindex $comd $one] {
		"479" {putcmdlog $payload}

		"005" {
			foreach {tok} [lrange $comd 3 end] {
				foreach {key val} [split $tok "="] {
					if {$key == "PREFIX"} {
						# We're in luck! Server advertises its PREFIX in VERSION reply to servers.
						set v [string range $val 1 end]
						set mod [split $v ")"]
						set modechar [split [lindex $mod 1] {}]
						set modepref [split [lindex $mod 0] {}]
						foreach {c} $modechar {x} $modepref {
							nda set "ts6/$::netname($sck)/prefix/$c" $x
						}
						foreach {x} $modechar {c} $modepref {
							nda set "ts6/$::netname($sck)/pfxchar/$c" $x
						}
						putcmdlog [nda get "ts6/$::netname($sck)/prefix"]
						putcmdlog [nda get "ts6/$::netname($sck)/pfxchar"]
					}
				}
			}
		}

		"PRIVMSG" {
			if {[string index [lindex $comd 2] 0] == "#" || [string index [lindex $comd 2] 0] == "&" || [string index [lindex $comd 2] 0] == "!" || [string index [lindex $comd 2] 0] == "+" || [string index [lindex $comd 2] 0] == "."} {
				set client chan
				callbind $sck pub "-" [string tolower [lindex $payload 0]] [lindex $comd 2] [lindex $comd 0] [lrange $payload 1 end]
				callbind $sck evnt "-" "chanmsg" [lindex $comd 0] [lindex $comd 2] [lrange $payload 0 end]
			} {
				set client [tnda get "intclient/$::netname($sck)/[lindex $comd 2]"]
				callbind $sck msg $client [string tolower [lindex $payload 0]] [lindex $comd 0] [lrange $payload 1 end]
				callbind $sck "evnt" "-" "privmsg" [lindex $comd 0] [lindex $comd 2] [lrange $payload 0 end]
			}
		}

		"NOTICE" {
			if {![tnda get "ts6/$::netname($sck)/connected"]} {return}
			if {[string index [lindex $comd 2] 0] == "#" || [string index [lindex $comd 2] 0] == "&" || [string index [lindex $comd 2] 0] == "!" || [string index [lindex $comd 2] 0] == "+" || [string index [lindex $comd 2] 0] == "."} {
				set client chan
				callbind $sck pubnotc "-" [string tolower [lindex $payload 0]] [lindex $comd 2] [lindex $comd 0] [lrange $payload 1 end]
				callbind $sck pubnotc-m "-" [string tolower [lindex $payload 0]] [lindex $comd 2] [lindex $comd 0] [lrange $payload 1 end]
				callbind $sck "evnt" "-" "channotc" [lindex $comd 0] [lindex $comd 2] [lrange $payload 0 end]
			} {
				set client [tnda get "intclient/$::netname($sck)/[lindex $comd 2]"]
				callbind $sck notc $client [string tolower [lindex $payload 0]] [lindex $comd 0] [lrange $payload 1 end]
				callbind $sck "evnt" "-" "privnotc" [lindex $comd 0] [lindex $comd 2] [lrange $payload 0 end]
			}
		}

		"MODE" {
			if {[lindex $comd 3] == [tnda get "nick/$::netname($sck)/[lindex $comd 0]"]} {
				foreach {c} [split [lindex $comd 4] {}] {
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
			if {""==[tnda get "channels/$::netname($sck)/$chan/ts"]} {callbind $sck create "-" "-" [lindex $comd 3] [lindex $comd 0] $::netname($sck)}
			callbind $sck join "-" "-" [lindex $comd 3] [lindex $comd 0] $::netname($sck)
			tnda set "channels/$::netname($sck)/$chan/ts" [lindex $comd 2]
			tnda set "userchan/$::netname($sck)/[lindex $comd 0]/$chan" 1
		}

		"TMODE" {
			set ctr 4
			set state 1
			foreach {c} [split [lindex $comd 4] {}] {
				switch -regexp -- $c {
					"\\\+" {set state 1}
					"-" {set state 0}
					"[ABCcDdiMmNnOpPQRrSsTtZz]" {callbind $sck mode "-" [expr {$state ? "+" : "-"}] $c [lindex $comd 0] [lindex $comd 3] "" $::netname($sck)}
					"[beljfxqIaykohv]" {callbind $sck mode "-" [expr {$state ? "+" : "-"}] $c [lindex $comd 0] [lindex $comd 3] [lindex $comd [incr ctr]] $::netname($sck)}
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
			tnda set "channels/$::netname($sck)/$chan/ts" [lindex $comd 2]
			foreach {nick} $payload {
				set un ""
				set uo ""
				set state uo
				foreach {c} [split $nick {}] {
					if {[string is integer $c]} {set state un}
					if {$state == "uo"} {set c [nda get "ts6/$::netname($sck)/pfxchar/$c"] ; }
					if {"un"==$state} {append un $c}
					if {"uo"==$state} {append uo $c}
				}
				callbind $sck join "-" "-" [lindex $comd 3] $un $::netname($sck)
						putcmdlog "$un+$uo"
				if {""!=$uo} {tnda set "channels/$::netname($sck)/$chan/modes/$un" $uo
					foreach {c} [split $uo {}] {
						putcmdlog "$un+$c"
						callbind $sck mode "-" + $c $un [lindex $comd 3] $un $::netname($sck)
					}
				}
			}

		}

		"PART" {
			callbind $sck part "-" "-" [lindex $comd 2] [lindex $comd 0] $::netname($sck)
			set chan [string map {/ [} [::base64::encode [string tolower [lindex $comd 2]]]]
			tnda set "userchan/$::netname($sck)/[lindex $comd 0]/$chan" 0
		}

		"KICK" {
			callbind $sck part "-" "-" [lindex $comd 2] [lindex $comd 3] $::netname($sck)
		}

		"NICK" {
			tnda set "nick/$::netname($sck)/[lindex $comd 0]" [lindex $comd 2]
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
			tnda set "rname/$::netname($sck)/[lindex $comd $num]" $payload
			putcmdlog "New user at $::netname($sck) [lindex $comd $num] [lindex $comd 2]![lindex $comd 6]@[tnda get "rhost/$::netname($sck)/[lindex $comd $num]"] (vhost [tnda get "vhost/$::netname($sck)/[lindex $comd $num]"]) :$payload"
			callbind $sck conn "-" "-" [lindex $comd $num]
		}

		"ENCAP" {
			putcmdlog [join [list $comd "--" $payload] " "]
			switch -nocase -- [lindex $comd 3] {
				"SASL" {
					#don't bother
				}
				"SU" {
					if {$payload == ""} {set payload [lindex $comd 5]}
					tnda set "login/$::netname($sck)/[lindex $comd 4]" $payload
					if {$payload == ""} {callbind $sck logout "-" "-" [lindex $comd 4]} {callbind $sck login "-" "-" [lindex $comd 4] $payload}
				}
				"CERTFP" {
					tnda set "certfps/$::netname($sck)/[lindex $comd 0]" $payload
					callbind $sck encap "-" "certfp" [lindex $comd 0] $payload
				}
				"METADATA" {
					switch -nocase -- [lindex $comd 4] {
						"ADD" {
							tnda set "metadata/$::netname($sck)/[lindex $comd 5]/[ndaenc [lindex $comd 6]]" $payload
							callbind $sck encap "-" "metadata.[string tolower [lindex $comd 6]]" [lindex $comd 5] $payload
						}
						"DELETE" {
							tnda set "metadata/$::netname($sck)/[lindex $comd 5]/[ndaenc $payload]" ""
							callbind $sck encap "-" "metadata.[string tolower $payload]" [lindex $comd 5] ""
						}
					}
				}
			}
		}

		"TOPIC" {
			callbind $sck topic "-" "-" [lindex $comd 2] [join $payload " "]
		}
		"QUIT" {
			if {![string is digit [string index [lindex $comd 0] 0]]} {
				set ocomd [lrange $comd 1 end]
				set on [lindex $comd 0]
				set comd [list [::ts6::nick2uid $::netname($sck) $on] {*}$ocomd]
				putcmdlog "Uh-oh, netsplit! $on -> [::ts6::nick2uid $::netname($sck) $on] has split"
			}
			foreach {chan _} [tnda get "userchan/$::netname($sck)/[lindex $comd 0]"] {
				callbind $sck part "-" "-" [ndadec $chan] [lindex $comd 0] $::netname($sck)
				tnda set "userchan/$::netname($sck)/[lindex $comd 0]/$chan" 0
			}

			tnda set "login/$::netname($sck)/[lindex $comd 0]" ""
			tnda set "nick/$::netname($sck)/[lindex $comd 0]" ""
			tnda set "oper/$::netname($sck)/[lindex $comd 0]" 0
			tnda set "ident/$::netname($sck)/[lindex $comd 0]" ""
			tnda set "rhost/$::netname($sck)/[lindex $comd 0]" ""
			tnda set "vhost/$::netname($sck)/[lindex $comd 0]" ""
			tnda set "rname/$::netname($sck)/[lindex $comd 0]" ""
			tnda set "metadata/$::netname($sck)/[lindex $comd 0]" [list]
			tnda set "certfps/$::netname($sck)/[lindex $comd 0]" ""
			callbind $sck quit "-" "-" [lindex $comd 0] $::netname($sck)
		}

		"KILL" {
			foreach {chan _} [tnda get "userchan/$::netname($sck)/[lindex $comd 2]"] {
				callbind $sck part "-" "-" [ndadec $chan] [lindex $comd 2]
				tnda set "userchan/$::netname($sck)/[lindex $comd 2]/$chan" 0
			}
			tnda set "login/$::netname($sck)/[lindex $comd 2]" ""
			tnda set "nick/$::netname($sck)/[lindex $comd 2]" ""
			tnda set "oper/$::netname($sck)/[lindex $comd 2]" 0
			tnda set "ident/$::netname($sck)/[lindex $comd 2]" ""
			tnda set "rhost/$::netname($sck)/[lindex $comd 2]" ""
			tnda set "vhost/$::netname($sck)/[lindex $comd 2]" ""
			tnda set "rname/$::netname($sck)/[lindex $comd 2]" ""
			tnda set "metadata/$::netname($sck)/[lindex $comd 2]" [list]
			tnda set "certfps/$::netname($sck)/[lindex $comd 2]" ""
		}

		"ERROR" {
			putcmdlog "Recv'd an ERROR $payload from $::netname($sck)"
		}

		"CAPAB" {
			tnda set "ts6/$::netname($sck)/euid" 0
			foreach {cw} [split $payload " "] {
				if {$cw == "EUID"} {tnda set "ts6/$::netname($sck)/euid" 1}
			}
			tnda set "ts6/$::netname($sck)/connected" 1
		}

		"PING" {
			set num [string repeat "0" [expr {3-[string length [::ts6::b64e $::sid($sck)]]}]]
			append num [::ts6::b64e $::sid($sck)]
			if {[lindex $comd 3]==""} {set pong [lindex $comd 0]} {set pong [lindex $comd 3]}
			putdcc $sck ":$num PONG $pong [lindex $comd 2]"
		}
	}
}

proc ::ts6::login {sck {osid "42"} {password "link"} {servname "net"}} {
	set num [string repeat "0" [expr {3-[string length [::ts6::b64e $osid]]}]]
	append num [::ts6::b64e $osid]
	global netname sid sock nettype
	set netname($sck) $servname
	set nettype($servname) ts6
	set sock($servname) $sck
	set sid($sck) $osid
	set sid($servname) $osid
	tnda set "ts6/$::netname($sck)/connected" 0
	tnda set "ts6/$::netname($sck)/euid" 0
	if {![info exists ::ts6(halfops)]} {tnda set "pfx/halfop" v} {tnda set "pfx/halfop" $::ts6(halfops)}
	if {![info exists ::ts6(ownermode)]} {tnda set "pfx/owner" o} {tnda set "pfx/owner" $::ts6(ownermode)}
	if {![info exists ::ts6(protectmode)]} {tnda set "pfx/protect" o} {tnda set "pfx/protect" $::ts6(protectmode)}
	if {![info exists ::ts6(euid)]} {set ::ts6(euid) 1}
	putdcc $sck "PASS $password TS 6 :$num"
	putdcc $sck "CAPAB :EUID ENCAP IE EX CLUSTER EOPMOD SVS SERVICES"
	putdcc $sck "SERVER $::servername 1 :chary.tcl for Eggdrop and related bots"
	putdcc $sck "SVINFO 6 6 0 :[clock format [clock seconds] -format %s]"
	putdcc $sck ":$num VERSION"
	bind $sck mode - + ::ts6::checkop
	bind $sck mode - - ::ts6::checkdeop
}

#source services.conf

proc ::ts6::nick2uid {netname nick} {
	foreach {u n} [tnda get "nick/$netname"] {
		if {[string tolower $n] == [string tolower $nick]} {return $u}
	}
}
proc ::ts6::intclient2uid {netname nick} {
	foreach {u n} [tnda get "intclient/$netname"] {
		if {[string tolower $n] == [string tolower $nick]} {return $u}
	}
}
proc ::ts6::uid2nick {netname u} {
	return [tnda get "nick/$netname/$u"]
}
proc ::ts6::uid2rhost {netname u} {
	return [tnda get "rhost/$netname/$u"]
}
proc ::ts6::uid2host {netname u} {
	return [tnda get "host/$netname/$u"]
}
proc ::ts6::uid2ident {netname u} {
	return [tnda get "ident/$netname/$u"]
}
proc ::ts6::nick2host {netname nick} {
	return [tnda get "host/$netname/[nick2uid $netname $nick]"]
}
proc ::ts6::nick2ident {netname nick} {
	return [tnda get "ident/$netname/[nick2uid $netname $nick]"]
}
proc ::ts6::nick2rhost {netname nick} {
	return [tnda get "rhost/$netname/[nick2uid $netname $nick]"]
}
proc ::ts6::getts {netname chan} {
	return [tnda get "channels/$netname/[ndaenc $chan]/ts"]
}
proc ::ts6::getpfx {netname chan nick} {
	return [tnda get "channels/$netname/[ndaenc $chan]/modes/[::ts6::nick2uid $netname $nick]"]
}
proc ::ts6::getupfx {netname chan u} {
	return [tnda get "channels/$netname/[ndaenc $chan]/modes/$u"]
}
proc ::ts6::getpfxchars {netname modes} {
	set o ""
	foreach {c} [split $modes {}] {
		append o [nda get "ts6/$netname/prefix/$c"]
	}
	return $o
}
proc ::ts6::getmetadata {netname nick metadatum} {
	return [tnda get "metadata/$netname/[::ts6::nick2uid $netname $nick]/[ndaenc $metadatum]"]
}
proc ::ts6::getcertfp {netname nick} {
	return [tnda get "certfps/$netname/[::ts6::nick2uid $netname $nick]"]
}

proc ::ts6::checkop {mc ftp} {
	set f [lindex $ftp 0]
	set t [lindex $ftp 1]
	set p [lindex $ftp 2]
	set n [lindex $ftp 3]
	if {[nda get "ts6/$n/pfxchar/$mc"]==""} {return}
putcmdlog "up $mc $f $t $p $n"
  set chan [string map {/ [} [::base64::encode [string tolower $t]]]
  tnda set "channels/$n/$chan/modes/$p" "[string map [list $mc ""] [tnda get "channels/$n/$chan/modes/$p"]]$mc"
}

proc ::ts6::checkdeop {mc ftp} {
	set f [lindex $ftp 0]
	set t [lindex $ftp 1]
	set p [lindex $ftp 2]
	set n [lindex $ftp 3]
	if {[nda get "ts6/$n/pfxchar/$mc"]==""} {return}
putcmdlog "down $mc $f $t $p $n"
  set chan [string map {/ [} [::base64::encode [string tolower $t]]]
  tnda set "channels/$n/$chan/modes/$p" "[string map [list $mc ""] [tnda get "channels/$n/$chan/modes/$p"]]"
}

proc ::ts6::getfreeuid {net} {
set work 1
set cns [list]
foreach {_ cnum} [tnda get "intclient/$net"] {lappend cns $cnum}
while {0!=$work} {set num [expr {[rand 300000]+10000}];if {[lsearch -exact $cns $num]==-1} {set work 0}}
return $num
}

namespace export *
namespace ensemble create
}

#ts6 login $::sock
