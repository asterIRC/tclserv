proc sendUid {sck nick ident host dhost uid {realname "* Unknown *"}} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	set sl [format "%s N %s 1 %s %s %s +oik AAAAAA %s%s :%s" $sid $nick [clock format [clock seconds] -format %s] $ident $host $sid $sendnn $realname]
	tnda set "intclient/${sid}${sendnn}" $uid
	puts $sck $sl
	puts stdout $sl
}

proc privmsg {sck uid targ msg} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format "%s%s P %s :%s" $sid $sendnn $targ $msg]
	puts stdout [format "%s%s P %s :%s" $sid $sendnn $targ $msg]
}

proc kick {sck uid targ tn msg} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format "%s%s K %s %s :%s" $sid $sendnn $targ $tn $msg]
}

proc notice {sck uid targ msg} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format "%s%s O %s :%s" $sid $sendnn $targ $msg]
}

proc setacct {sck targ msg} {
	global sid
	puts $sck [format "%s AC %s R %s" $sid $targ $msg]
	tnda set "login/$targ" $msg
}

proc bind {type client comd script} {
	set moretodo 1
	while {0!=$moretodo} {
		set bindnum [rand 1 10000000]
		if {[tnda get "binds/$type/$client/$comd/$bindnum"]!=""} {} {set moretodo 0}
	}
	tnda set "binds/$type/$client/$comd/$bindnum" $script
	return $bindnum
}

proc unbind {type client comd id} {
	tnda set "binds/$type/$client/$comd/$id" ""
}

proc putmode {sck uid targ mode parm ts} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format "%s%s M %s %s %s" $sid $sendnn $targ $mode $parm $ts]
}

proc putjoin {sck uid targ ts} {
	global sid
	set sendid [b64e $uid]
	set sendnn [string repeat "A" [expr {3-[string length $sendid]}]]
	append sendnn $sendid
	puts $sck [format "%s B %s %s %s%s:o" $sid $targ $ts $sid $sendnn]
	puts stdout [format "%s B %s %s %s%s:o" $sid $targ $ts $sid $sendnn]

}

proc callbind {type client comd args} {
	if {""!=[tnda get "binds/$type/$client/$comd"]} {foreach {id script} [tnda get "binds/$type/$client/$comd"] {$script [lindex $args 0] [lrange $args 1 end]};return}
	if {""!=[tnda get "binds/$type/-/$comd"]} {foreach {id script} [tnda get "binds/$type/-/$comd"] {$script [lindex $args 0] [lrange $args 1 end]};return}
}

proc p10-main {sck} {
	global sid sock
	if {[eof $sck]} {puts stderr "duckfuck.";exit}
	gets $sck line
	set line [string trim $line "\r\n"]
	set gotsplitwhere [string first " :" $line]
	if {$gotsplitwhere==-1} {set comd [split $line " "]} {set comd [split [string range $line 0 [expr {$gotsplitwhere - 1}]] " "]}
	set payload [split [string range $line [expr {$gotsplitwhere + 2}] end] " "]
	puts stdout [join $comd " "]
	switch -nocase -- [lindex $comd 1] {
		"P" {
			if {[string index [lindex $comd 2] 0] == "#"} {
				set client chan
				callbind pub "-" [string tolower [lindex $payload 0]] [lindex $comd 2] [lindex $comd 0] [lrange $payload 1 end]
				callbind evnt "-" "chanmsg" [lindex $comd 0] [lindex $comd 2] [lrange $payload 0 end]
			} {
				set client [tnda get "intclient/[lindex $comd 2]"]
				callbind msg $client [string tolower [lindex $payload 0]] [lindex $comd 0] [lrange $payload 1 end]
			}
		}

		"O" {
			if {[string index [lindex $comd 2] 0] == "#"} {
				set client chan
				callbind pubnotc "-" [string tolower [lindex $payload 0]] [lindex $comd 2] [lindex $comd 0] [lrange $payload 1 end]
				callbind pubnotc-m "-" [string tolower [lindex $payload 0]] [lindex $comd 2] [lindex $comd 0] [lrange $payload 1 end]
			} {
				set client [tnda get "intclient/[lindex $comd 2]"]
				callbind notc $client [string tolower [lindex $payload 0]] [lindex $comd 0] [lrange $payload 1 end]
			}
		}

		"M" {
			if {[string length [lindex $comd 0]] != 2} {if {[lindex $comd 2] == [tnda get "nick/[lindex $comd 0]"]} {
				foreach {c} [split [lindex $comd 3] {}] {
					switch -- $c {
						"+" {set state 1}
						"-" {set state 0}
						"o" {tnda set "oper/[lindex $comd 0]" $state}
					}
				}
			} } {
				set ctr 3
				foreach {c} [split [lindex $comd 3] {}] {
					switch -regexp -- $c {
						"\\\+" {set state 1}
						"\\\-" {set state 0}
						"[aCcDdiMmNnOpQRrSsTtZz]" {callbind mode "-" [expr {$state ? "+" : "-"}] $c [lindex $comd 0] [lindex $comd 2]}
						"[belLkohv]" {callbind mode "-" [expr {$state ? "+" : "-"}] $c [lindex $comd 0] [lindex $comd 2] [lindex $comd [incr ctr]]}
					}
				}
			}
		}

		"C" {
			callbind create "-" "-" [lindex $comd 2] [lindex $comd 0]
			callbind join "-" "-" [lindex $comd 2] [lindex $comd 0]
			set chan [string map {/ [} [::base64::encode [string tolower [lindex $comd 2]]]]
			tnda set "channels/$chan/ts" [lindex $comd 3]
		}

		"OM" {
			if {[string length [lindex $comd 0]] != 2} {if {[lindex $comd 2] == [tnda get "nick/[lindex $comd 0]"]} {
				foreach {c} [split [lindex $comd 3] {}] {
					switch -- $c {
						"+" {set state 1}
						"-" {set state 0}
						"o" {tnda set "oper/[lindex $comd 0]" $state}
					}
				}
			} } {
				set ctr 3
				foreach {c} [split [lindex $comd 3] {}] {
					switch -regexp -- $c {
						"\\\+" {set state 1}
						"\\\-" {set state 0}
						"[aCcDdiMmNnOpQRrSsTtZz]" {callbind mode "-" [expr {$state ? "+" : "-"}] $c [lindex $comd 0] [lindex $comd 2]}
						"[belLkohv]" {callbind mode "-" [expr {$state ? "+" : "-"}] $c [lindex $comd 0] [lindex $comd 2] [lindex $comd [incr ctr]]}
					}
				}
			}
		}

		"B" {
			puts $sck "$sid EB"
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
			tnda set "channels/$chan/ts" [lindex $comd 3]
			foreach {nick} [split [lindex $comd $four] ","] {
				set n [split $nick ":"]
				set un [lindex $n 0]
				set uo [lindex $n 1]
				if {""!=$uo} {tnda set "channels/$chan/modes/$un" $uo}
				callbind join "-" "-" [lindex $comd 2] $un
			}

		}

		"J" {
			callbind join "-" "-" [lindex $comd 2] [lindex $comd 0]
		}

		"L" {
			callbind part "-" "-" [lindex $comd 2] [lindex $comd 0]
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
					tnda set "login/[lindex $comd $num]" $loggedin
				}

				if {""!=$fakehost} {
					tnda set "vhost/[lindex $comd $num]" $fakehost
				}

				puts $sck "$sid O #o :conn $line"

				tnda set "nick/[lindex $comd $num]" [lindex $comd 2]
				tnda set "oper/[lindex $comd $num]" $oper
				tnda set "ident/[lindex $comd $num]" [lindex $comd 5]
				tnda set "rhost/[lindex $comd $num]" [lindex $comd 6]
				callbind conn "-" "-" [lindex $comd $num]
			} {
				puts $sck "$sid O #o :nch [tnda get "nick/[lindex $comd 0]"] [lindex $comd 2]"
				callbind nch "-" "-" [lindex $comd $num] [tnda get "nick/[lindex $comd 0]"] [lindex $comd 2]
				tnda set "nick/[lindex $comd 0]" [lindex $comd 2]
			}
		}

		"Q" {
			tnda set "login/[lindex $comd 0]" ""
			tnda set "nick/[lindex $comd 0]" ""
			tnda set "oper/[lindex $comd 0]" 0
			tnda set "ident/[lindex $comd 0]" ""
			tnda set "rhost/[lindex $comd 0]" ""
			tnda set "vhost/[lindex $comd 0]" ""
		}

		"D" {
			tnda set "login/[lindex $comd 2]" ""
			tnda set "nick/[lindex $comd 2]" ""
			tnda set "oper/[lindex $comd 2]" 0
			tnda set "ident/[lindex $comd 2]" ""
			tnda set "rhost/[lindex $comd 2]" ""
			tnda set "vhost/[lindex $comd 2]" ""
		}

		"G" {
			puts $sck "$sid Z [lindex $comd 3] [lindex $comd 2] [lindex $comd 4]"
		}
	}
}

proc p10-burst {sck} {
	global servername sid password
	set sid [string repeat "A" [expr {2-[b64e $::numeric]}]]
	append sid [b64e $::numeric]
	puts $sck "PASS :$password"
	puts $sck "SERVER $servername 0 [clock format [clock seconds] -format %s] [clock format [clock seconds] -format %s] J10 $sid\]\]\] 0 :Services for IRC Networks"
	puts stdout "PASS :$password"
	puts stdout "SERVER $servername 0 [clock format [clock seconds] -format %s] [clock format [clock seconds] -format %s] J10 $sid\]\]\] 0 :Services for IRC Networks"
}


source services.conf

set sid [string repeat "A" [expr {2-[b64e $numeric]}]]
append sid [b64e $numeric]
