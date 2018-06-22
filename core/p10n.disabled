
namespace eval p10n {
set sid [string repeat "A" [expr {2-[string length [b64e $::numeric]]}]]
append sid [b64e $::numeric]

proc ::p10n::sendUid {sck nick ident host dhost uid {realname "* Unknown *"} {modes "+oik"} {server ""}} {
	if {""==$server} {set server $::numeric}
	set sid [string repeat "A" [expr {2-[string length [b64e $server]]}]]
	append sid [b64e $server]
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	set sl [format "%s N %s 1 %s %s %s %s AAAAAA %s%s :%s" $sid $nick [clock format [clock seconds] -format %s] $ident $host $modes $sid $sendnn $realname]
	tnda set "intclient/$::netname($sck)/${sid}${sendnn}" $uid
	puts $sck $sl
}

proc ::p10n::sendSid {sck sname sid {realname "In use by Services"}} {
	set sl [format "%s S %s 2 %s %s P10 %s]]] 0 :%s" [b64e $::sid] $sname [clock format [clock seconds] -format %s] [clock format [clock seconds] -format %s] [b64e $sid] $realname]
	puts $sck $sl
}

proc ::p10n::topic {sck uid targ topic} {
	set sid [string repeat "A" [expr {2-[string length [b64e $::numeric]]}]]
	append sid [b64e $::numeric]
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format "%s%s T %s :%s" $sid $sendnn $targ $topic]
}

proc ::p10n::privmsg {sck uid targ msg} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format "%s%s P %s :%s" $sid $sendnn $targ $msg]
}

proc ::p10n::kick {sck uid targ tn msg} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format "%s%s K %s %s :%s" $sid $sendnn $targ $tn $msg]
}

proc ::p10n::kill {sck uid tn msg} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format "%s%s D %s :%s" $sid $sendnn $tn $msg]
}

proc ::p10n::notice {sck uid targ msg} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format "%s%s O %s :%s" $sid $sendnn $targ $msg]
}

proc ::p10n::setacct {sck targ msg} {
	global sid
	puts $sck [format "%s AC %s R %s" $sid $targ $msg]
	tnda set "login/$::netname($sck)/$targ" $msg
}

proc ::p10n::putwallop {sck msg} {
	global sid
	puts $sck [format "%s WA :%s" $sid $msg]
}

proc ::p10n::sethost {sck uid targ msg} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format "%s%s SH %s %s %s" $sid $sendnn $targ [tnda get "ident/$::netname($sck)/$targ"] $msg]
	puts $sck [format "%s FA %s %s" $sid $targ $msg]
	puts stdout [format "%s SH %s %s %s" $sid $targ [tnda get "ident/$::netname($sck)/$targ"] $msg]
	tnda set "vhost/$::netname($sck)/$targ" $msg
}

proc ::p10n::bind {sock type client comd script} {
	set moretodo 1
	while {0!=$moretodo} {
		set bindnum [rand 1 10000000]
		if {[tnda get "binds/$sock/$type/$client/$comd/$bindnum"]!=""} {} {set moretodo 0}
	}
	tnda set "binds/$sock/$type/$client/$comd/$bindnum" $script
	puts stdout "binds/$sock/$type/$client/$comd/$bindnum [tnda get "binds/$sock/$type/$client/$comd"]"
	return $bindnum
}

proc ::p10n::unbind {sock type client comd id} {
	tnda set "binds/$sock/$type/$client/$comd/$id" ""
}

proc ::p10n::putmode {sck uid targ mode parm ts} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format "%s%s M %s %s %s" $sid $sendnn $targ $mode $parm $ts]
}

proc ::p10n::putmotd {sck targ line} {
	global sid
	puts $sck [format "%s 372 %s :- %s" $sid $targ $line]
}

proc ::p10n::mark {sck targ type line} {
	global sid
	puts $sck [format "%s MK %s %s :%s" $sid $targ $type $line]
	puts stdout [format "%s MK %s %s :%s" $sid $targ $type $line]
}

proc ::p10n::putmotdend {sck targ} {
	global sid
	puts $sck [format "%s 376 %s :End of global MOTD." $sid $targ]
}

proc ::p10n::putjoin {sck uid targ ts} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format "%s B %s %s %s%s:o" $sid $targ $ts $sid $sendnn]
	puts stdout [format "%s B %s %s %s%s:o" $sid $targ $ts $sid $sendnn]

}

proc ::p10n::callbind {sock type client comd args} {
	puts stdout "[tnda get "binds/$sock/$type/$client/$comd"]"
	if {""!=[tnda get "binds/$sock/$type/$client/$comd"]} {
		foreach {id script} [tnda get "binds/$sock/$type/$client/$comd"] {
			$script [lindex $args 0] [lrange $args 1 end]
		};return
	}
	#if {""!=[tnda get "binds/$type/-/$comd"]} {foreach {id script} [tnda get "binds/$type/-/$comd"] {$script [lindex $args 0] [lrange $args 1 end]};return}
}

proc ::p10n::irc-main {sck} {
	global sid sock
	if {[eof $sck]} {puts stderr "duckfuck.";exit}
	gets $sck line
	set line [string trim $line "\r\n"]
	set gotsplitwhere [string first " :" $line]
	if {$gotsplitwhere==-1} {set comd [split $line " "]} {set comd [split [string range $line 0 [expr {$gotsplitwhere - 1}]] " "]}
	set payload [split [string range $line [expr {$gotsplitwhere + 2}] end] " "]
	switch -nocase -- [lindex $comd 1] {
		"P" {
			if {[string index [lindex $comd 2] 0] == "#"} {
				set client chan
				callbind $sck pub "-" [string tolower [lindex $payload 0]] [lindex $comd 2] [lindex $comd 0] [lrange $payload 1 end] p10
				callbind $sck evnt "-" "chanmsg" [lindex $comd 0] [lindex $comd 2] [lrange $payload 0 end] p10
			} {
				set client [tnda get "intclient/$::netname($sck)/[lindex $comd 2]"]
				callbind $sck msg $client [string tolower [lindex $payload 0]] [lindex $comd 0] [lrange $payload 1 end] p10
				callbind $sck "evnt" "-" "privmsg" [lindex $comd 0] [lindex $comd 2] [lrange $payload 0 end] p10
			}
		}

		"O" {
			if {[string index [lindex $comd 2] 0] == "#"} {
				set client chan
				callbind $sck pubnotc "-" [string tolower [lindex $payload 0]] [lindex $comd 2] [lindex $comd 0] [lrange $payload 1 end] p10
				callbind $sck pubnotc-m "-" [string tolower [lindex $payload 0]] [lindex $comd 2] [lindex $comd 0] [lrange $payload 1 end] p10
				callbind $sck "evnt" "-" "channotc" [lindex $comd 0] [lindex $comd 2] [lrange $payload 0 end] p10
			} {
				set client [tnda get "intclient/$::netname($sck)/[lindex $comd 2]"]
				callbind $sck notc $client [string tolower [lindex $payload 0]] [lindex $comd 0] [lrange $payload 1 end]
				callbind $sck "evnt" "-" "privnotc" [lindex $comd 0] [lindex $comd 2] [lrange $payload 0 end] p10
			}
		}

		"M" {
			puts stdout [join [list {*}$comd {*}$payload] " "]
			if {[string index [lindex $comd 2] 0] != "#"} {if {[lindex $comd 2] == [tnda get "nick/$::netname($sck)/[lindex $comd 0]"]} {
				foreach {c} [split [lindex $comd 3] {}] {
					switch -- $c {
						"+" {set state 1}
						"-" {set state 0}
						"o" {tnda set "oper/$::netname($sck)/[lindex $comd 0]" $state}
					}
				}
			} } {
				set ctr 3
				foreach {c} [split [lindex $comd 3] {}] {
					switch -regexp -- $c {
						"\\\+" {set state 1}
						"-" {set state 0}
						"[aCcDdiMmNnOpQRrSsTtZz]" {callbind $sck mode "-" [expr {$state ? "+" : "-"}] $c [lindex $comd 0] [lindex $comd 2] $::netname($sck)}
						"[belLkohv]" {callbind $sck mode "-" [expr {$state ? "+" : "-"}] $c [lindex $comd 0] [lindex $comd 2] [lindex $comd [incr ctr]] $::netname($sck)}
					}
				}
			}
		}

		"C" {
			callbind $sck create "-" "-" [lindex $comd 2] [lindex $comd 0] $::netname($sck)
			callbind $sck join "-" "-" [lindex $comd 2] [lindex $comd 0] $::netname($sck)
			set chan [string map {/ [} [::base64::encode [string tolower [lindex $comd 2]]]]
			tnda set "channels/$::netname($sck)/$chan/$::netname($sck)/ts" [lindex $comd 3]
		}

		"T" {
			callbind $sck topic "-" "-" [lindex $comd 2] [join $payload " "]
		}

		"OM" {
			set ctr 3
			foreach {c} [split [lindex $comd 3] {}] {
				switch -regexp -- $c {
					"\\\+" {set state 1}
					"\\\-" {set state 0}
					"[aCcDdiMmNnOpQRrSsTtZz]" {callbind $sck mode "-" [expr {$state ? "+" : "-"}] $c [lindex $comd 0] [lindex $comd 2]}
					"[belLkohv]" {callbind $sck mode "-" [expr {$state ? "+" : "-"}] $c [lindex $comd 0] [lindex $comd 2] [lindex $comd [incr ctr]]}
				}
			}
		}

		"B" {
			set chan [string map {/ [} [::base64::encode [string tolower [lindex $comd 2]]]]
			puts stdout "$chan"
			if {[string index [lindex $comd 4] 0] == "+"} {
				set four 5
				if {[string match "*l*" [lindex $comd 4]]} {incr four}
				if {[string match "*L*" [lindex $comd 4]]} {incr four}
				if {[string match "*k*" [lindex $comd 4]]} {incr four}
			} {
				set four 4
			}
			tnda set "channels/$::netname($sck)/$chan/$::netname($sck)/ts" [lindex $comd 3]
			foreach {nick} [split [lindex $comd $four] ","] {
				set n [split $nick ":"]
				set un [lindex $n 0]
				set uo [lindex $n 1]
				if {""!=$uo} {tnda set "channels/$::netname($sck)/$chan/modes/$::netname($sck)/$un" $uo}
				callbind $sck join "-" "-" [lindex $comd 2] $un
			}

		}

		"J" {
			callbind $sck join "-" "-" [lindex $comd 2] [lindex $comd 0]
		}

		"MO" {
			callbind $sck motd "-" "-" [lindex $comd 0]
		}

		"L" {
			callbind $sck part "-" "-" [lindex $comd 2] [lindex $comd 0]
		}

		"AC" {
			tnda set "login/$::netname($sck)/[lindex $comd 2]" [lindex $comd 3]
			callbind $sck account "-" "-" [lindex $comd 2] [lindex $comd 3]
		}

		"K" {
			callbind $sck part "-" "-" [lindex $comd 2] [lindex $comd 3]
		}

		"EB" {
			puts $sck "$sid EA"
		}

		"N" {
			if {[llength $comd] >= 5} {
				set num 8
				set ctr 1
				set oper 0
				set loggedin ""
				set fakehost ""
				set modes ""
				if {[string index [lindex $comd 7] 0] == "+"} {set modes [string range [lindex $comd 7] 1 end]; incr num}
				foreach {c} [split $modes {}] {
					puts stdout "$ctr $comd"
					switch -exact -- $c {
						"o" {set oper 1}
						"r" {incr ctr;incr num; set loggedin [lindex $comd [expr {$ctr+6}]]}
						"C" {incr ctr;incr num; set fakehost [lindex $comd [expr {$ctr+6}]]}
						"c" {incr ctr;incr num; set fakehost [lindex $comd [expr {$ctr+6}]]}
						"f" {incr ctr;incr num; set fakehost [lindex $comd [expr {$ctr+6}]]}
						"h" {incr ctr;incr num; set fakehost [lindex [split [lindex $comd [expr {$ctr+7}]] "@"] 1]}
					}
				}

				if {""!=$loggedin} {
					tnda set "login/$::netname($sck)/[lindex $comd $num]" $loggedin
				}

				if {""!=$fakehost} {
					tnda set "vhost/$::netname($sck)/[lindex $comd $num]" $fakehost
				}

				tnda set "nick/$::netname($sck)/[lindex $comd $num]" [lindex $comd 2]
				tnda set "oper/$::netname($sck)/[lindex $comd $num]" $oper
				tnda set "ident/$::netname($sck)/[lindex $comd $num]" [lindex $comd 5]
				tnda set "rhost/$::netname($sck)/[lindex $comd $num]" [lindex $comd 6]
				callbind $sck conn "-" "-" [lindex $comd $num]
			} {
				callbind $sck nch "-" "-" [lindex $comd 0] [tnda get "nick/$::netname($sck)/[lindex $comd 0]"] [lindex $comd 2]
				tnda set "nick/$::netname($sck)/[lindex $comd 0]" [lindex $comd 2]
			}
		}

		"Q" {
			tnda set "login/$::netname($sck)/[lindex $comd 0]" ""
			tnda set "nick/$::netname($sck)/[lindex $comd 0]" ""
			tnda set "oper/$::netname($sck)/[lindex $comd 0]" 0
			tnda set "ident/$::netname($sck)/[lindex $comd 0]" ""
			tnda set "rhost/$::netname($sck)/[lindex $comd 0]" ""
			tnda set "vhost/$::netname($sck)/[lindex $comd 0]" ""
		}

		"D" {
			tnda set "login/$::netname($sck)/[lindex $comd 2]" ""
			tnda set "nick/$::netname($sck)/[lindex $comd 2]" ""
			tnda set "oper/$::netname($sck)/[lindex $comd 2]" 0
			tnda set "ident/$::netname($sck)/[lindex $comd 2]" ""
			tnda set "rhost/$::netname($sck)/[lindex $comd 2]" ""
			tnda set "vhost/$::netname($sck)/[lindex $comd 2]" ""
		}

		"G" {
			puts $sck "$sid Z [lindex $comd 3] [lindex $comd 2] [lindex $comd 4]"
		}
	}
}

proc ::p10n::login {sck} {
	global servername sid password
	tnda set "pfx/owner" o
	tnda set "pfx/protect" o
	tnda set "pfx/halfop" h
	set sid [string repeat "A" [expr {2-[string length [b64e $::numeric]]}]]
	append sid [b64e $::numeric]
	puts $sck "PASS :$password"
	puts $sck "SERVER $servername 1 [clock format [clock seconds] -format %s] [clock format [clock seconds] -format %s] J10 $sid\]\]\] +s6h :Services for IRC Networks ($::netname($sck))"
	puts $sck "$sid EB"
	puts stdout "PASS :$password"
	puts stdout "SERVER $servername 1 [clock format [clock seconds] -format %s] [clock format [clock seconds] -format %s] J10 $sid\]\]\] 0 :Services for IRC Networks"
}


#source services.conf
namespace export *
namespace ensemble create
}

#p10 login $::sock
