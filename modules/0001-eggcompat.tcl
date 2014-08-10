source chanserv.conf

bind $::sock mode "-" "+" bitchopcheck
bind $::sock mode "-" "-" protectopcheck
bind $::sock join "-" "-" autoopcheck

proc protectopcheck {mc ftp} {
	set f [lindex $ftp 0 0]
	set t [lindex $ftp 0 1]
	set p [lindex $ftp 0 2]
	if {"o"==$mc && ![channel get $t protectop]} {return}
	if {"h"==$mc && ![channel get $t protecthalfop]} {return}
	if {"v"==$mc && ![channel get $t protectvoice]} {return}
	switch -- $mc {
		"o" {
			if {[matchattr [tnda get "login/$::netname($::sock)/$p"] |omn $t]} {
				p10 putmode $::sock 77 $t +$mc "$p" [tnda get "channels/[ndaenc $t]/$::netname($::sock)/ts"]
			}
		}
		"h" {
			if {[matchattr [tnda get "login/$::netname($::sock)/$p"] |l $t]} {
				p10 putmode $::sock 77 $t +$mc "$p" [tnda get "channels/[ndaenc $t]/$::netname($::sock)/ts"]
			}
		}
		"v" {
			if {[matchattr [tnda get "login/$::netname($::sock)/$p"] |v $t]} {
				p10 putmode $::sock 77 $t +$mc "$p" [tnda get "channels/[ndaenc $t]/$::netname($::sock)/ts"]
			}
		}
	}
}

proc autoopcheck {c ft} {
	set f [lindex $ft 0];set t [lindex $ft 1]
	if {[matchattr [tnda get "login/$::netname($::sock)/$f"] omn|] && [channel get $c operit]} {
		p10 putmode $::sock 77 $c +o $f [tnda get "channels/[ndaenc $c]/$::netname($::sock)/ts"]
		return
	}
	if {[matchattr [tnda get "login/$::netname($::sock)/$f"] |omn $c] && [channel get $c autoop]} {
		p10 putmode $::sock 77 $c +o $f [tnda get "channels/[ndaenc $c]/$::netname($::sock)/ts"]
		return
	}
	if {[matchattr [tnda get "login/$::netname($::sock)/$f"] l|] && [channel get $c operit]} {
		p10 putmode $::sock 77 $c +h $f [tnda get "channels/[ndaenc $c]/$::netname($::sock)/ts"]
		return
	}
	if {[matchattr [tnda get "login/$::netname($::sock)/$f"] |l $c] && [channel get $c autohalfop]} {
		p10 putmode $::sock 77 $c +h $f [tnda get "channels/[ndaenc $c]/$::netname($::sock)/ts"]
		return
	}
	if {[matchattr [tnda get "login/$::netname($::sock)/$f"] v|] && [channel get $c operit]} {
		p10 putmode $::sock 77 $c +v $f [tnda get "channels/[ndaenc $c]/$::netname($::sock)/ts"]
		return
	}
	if {[matchattr [tnda get "login/$::netname($::sock)/$f"] |v $c] && [channel get $c autovoice]} {
		p10 putmode $::sock 77 $c +v $f [tnda get "channels/[ndaenc $c]/$::netname($::sock)/ts"]
		return
	}
}

proc bitchopcheck {mc ftp} {
	set f [lindex $ftp 0]
	set t [lindex $ftp 1]
	set p [lindex $ftp 2]
	puts stdout "$ftp"
	if {"o"==$mc && ![channel get $t bitch]} {return}
	if {"h"==$mc && ![channel get $t halfbitch]} {return}
	if {"v"==$mc && ![channel get $t voicebitch]} {return}
	switch -glob -- $mc {
		"o" {
			if {![matchattr [tnda get "login/$::netname($::sock)/$p"] |omn $t]} {
				puts stdout "M $t -$mc $p [nda get "regchan/[ndaenc $t]/ts"]"
				p10 putmode $::sock 77 $t "-$mc" "$p" [nda get "regchan/[ndaenc $t]/ts"]
			}
		}
		"h" {
			if {![matchattr [tnda get "login/$::netname($::sock)/$p"] |l $t]} {
				puts stdout "M $t -$mc $p [nda get "regchan/[ndaenc $t]/ts"]"
				p10 putmode $::sock 77 $t "-$mc" "$p" [nda get "regchan/[ndaenc $t]/ts"]
			}
		}
		"v" {
			if {![matchattr [tnda get "login/$::netname($::sock)/$p"] |v $t]} {
				puts stdout "M $t -$mc $p [nda get "regchan/[ndaenc $t]/ts"]"
				p10 putmode $::sock 77 $t "-$mc" "$p" [nda get "regchan/[ndaenc $t]/ts"]
			}
		}
	}
}

proc utimer {seconds tcl-command} {after [expr $seconds * 1000] ${tcl-command}}
proc timer {minutes tcl-command} {after [expr $minutes * 60 * 1000] ${tcl-command}}
proc utimers {} {set t {}; foreach a [after info] {lappend t "0 [lindex [after info $a] 0] $a"}; return $t}
proc timers {} {set t {}; foreach a [after info] {lappend t "0 [lindex [after info $a] 0] $a"}; return $t}
proc killtimer id {return [after cancel $id]}
proc killutimer id {return [after cancel $id]}
proc ndaenc {n} {
	return [string map {/ [} [::base64::encode [string tolower $n]]]
}

proc isbotnick {n} {return [expr {$n == $::botnick}]}

proc putserv {msg} {
	puts $::sock ":$::botnick $msg"
	puts stdout ":$::botnick $msg"
}

proc puthelp {msg} {
	puts $::sock ":$::botnick $msg"
}

proc putquick {msg} {
	puts $::sock ":$::botnick $msg"
}

proc putnow {msg} {
	puts $::sock ":$::botnick $msg"
}

proc ndadec {n} {
	return [::base64::decode [string map {[ /} $n]]
}

proc msgmt {from msg} {
	set handle [lindex $msg 0 0]
	set attr [lindex $msg 0 1]
	set chan [lindex $msg 0 2]
	p10 notice $::sock 77 $from "$handle $attr $chan Matchattr result: [matchattr $handle $attr $chan]"
}

bind $::sock msg 77 "matchattr" msgmt

proc matchattr {handle attr {chan "*"}} {
	set handle [string tolower $handle]
	if {-1!=[string first "&" $attr]} {set and 1} {set and 0}
	set gattr [lindex [split $attr "&|"] 0]
	set cattr [lindex [split $attr "&|"] 1]
	set isattrg 0
	foreach {c} [split [nda get "eggcompat/attrs/global/$handle"] {}] {
		foreach {k} [split $gattr {}] {
			if {$c == $k} {set isattrg 1}
		}
	}
	set isattrc 0
	if {"*"!=$chan} {
		foreach {c} [split [nda get "eggcompat/attrs/[ndaenc $chan]/$handle"] {}] {
			foreach {k} [split $cattr {}] {
				if {$c == $k} {set isattrc 1}
			}
		}
	}
	if {$and && ($isattrg == $isattrc) && ($isattrc == 1)} {return 1}
	if {!$and && ($isattrg || $isattrc)} {return 1}
	return 0
}

proc chattr {handle attr {chan "*"}} {
	set handle [string tolower $handle]
	if {$chan == "*"} {
		set del [list]
		set app ""
		set state app
		foreach {c} [split $attr {}] {
			if {"+"==$c} {set state app;continue}
			if {"-"==$c} {set state del;continue}
			if {$state=="del"} {
				lappend del $c ""
			}
			if {$state=="app"} {
				lappend del $c ""
				append app $c
			}
		}
		nda set "eggcompat/attrs/global/$handle" [join [concat [string map $del [nda get "eggcompat/attrs/global/$handle"]] $app] ""]
	} {
		set del [list]
		set app ""
		set state app
		foreach {c} [split $attr {}] {
			if {"+"==$c} {set state app;continue}
			if {"-"==$c} {set state del;continue}
			if {$state=="del"} {
				lappend del $c ""
			}
			if {$state=="app"} {
				lappend del $c ""
				append app $c
			}
		}
		puts stdout [ndaenc $chan]
		nda set "eggcompat/attrs/[ndaenc $chan]/$handle" [join [concat [string map $del [nda get "eggcompat/attrs/[ndaenc $chan]/$handle"]] $app] ""]
	}
}

proc channels {} {
	foreach {chan _} [nda get "regchan"] {
		lappend ret $chan
	}
	return $ret
}

namespace eval channel {
	proc ::channel::get {chan flag} {
		if {[::set enda [nda get "eggcompat/chansets/[ndaenc $chan]/[ndaenc [string map {+ ""} $flag]]"]]!=""} {return $enda} {return 0}
	}
	proc ::channel::set {chan flags} {
		if {[llength $flags] != 1} {
			foreach {flag} $flags {
				::set bit [string index $flag 0]
				if {$bit=="+"} {::set bitt 1} {::set bitt 0}
				::set flag [string range $flag 1 end]
				nda set "eggcompat/chansets/[ndaenc $chan]/[ndaenc [string map {+ ""} $flag]]" $bitt
			}
		} {
			::set bit [string index $flags 0]
			if {$bit=="+"} {::set bitt 1} {::set bitt 0}
			::set flag [string range $flags 1 end]
			nda set "eggcompat/chansets/[ndaenc $chan]/[ndaenc [string map {+ ""} $flags]]" $bitt
		}
	}
	namespace export *
	namespace ensemble create
}

proc validuser {n} {
	if {""==[nda get "usernames/$n"]} {return 0} {return 1}
}

bind $::sock msg 77 "chanset" msgchanset
bind $::sock msg 77 "chattr" msgchattr
bind $::sock msg 77 "setxtra" msgxtra
set botnick $cs(nick)
chattr $cs(admin) +mnolv

proc msgchanset {from msg} {
	set ndacname [ndaenc [lindex $msg 0 0]]
	set chanset [lindex $msg 0 1]
	if {300>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$from"]]"] && ![matchattr [tnda get "login/$::netname($::sock)/$from"] m|m [lindex $msg 0 0]]} {
		p10 notice $::sock 77 $from "Only channel super-operators (300) and above and network masters may use eggdrop-compatible chansets."
		return
	}
	channel set [lindex $msg 0 0] $chanset
	p10 notice $::sock 77 $from "Eggdrop compatible chanset $chanset set on [lindex $msg 0 0]."
}

proc msgchattr {from msg} {
	set ndacname [ndaenc [lindex $msg 0 2]]
	set handle [lindex $msg 0 0]
	set hand [lindex $msg 0 0]
	set attrs [lindex $msg 0 1]
	set chan [lindex $msg 0 2]
	set ch [lindex $msg 0 2]
	if {$chan==""} {
		set chan "*"
		set ch "global"
	}
	foreach {c} [split $attrs {}] {
		if {$c == "+"} {continue}
		if {$c == "-"} {continue}
		if {$c == "v"} {set $c "mn|lmno"}
		if {$c == "l"} {set $c "mn|mno"}
		if {$c == "o"} {set $c "mn|omn"}
		if {$c == "m"} {set $c "mn|mn"}
		if {$c == "n"} {set $c "n|n"}
		if {![matchattr [tnda get "login/$::netname($::sock)/$from"] $c $chan]} {
			p10 notice $::sock 77 $from "You may only give flags you already possess (Any of flags $c required to set $attrs)."
			return
		}
	}
	if {"*"!=$chan} {chattr $hand $attrs} {chattr $hand $attrs $chan}
	p10 notice $::sock 77 $from "Global flags for $hand are now [nda get "eggcompat/attrs/global/[string tolower $handle]"]"
	if {$ch != "global"} {p10 notice $::sock 77 $from "Flags on $chan for $hand are now [nda get "eggcompat/attrs/$ndacname/[string tolower $handle]"]"}
}

proc nick2hand {nick} {
	foreach {uid nic} [tnda get "nick"] {
		if {$nick == $nic} {return [tnda get "login/$::netname($::sock)/$uid"]}
	}
}

proc getuser {nick datafield {dataval "body"}} {
	return [nda get "usernames/$nick/setuser/[ndaenc $datafield]/[ndaenc $dataval]"]
}

proc setuser {nick datafield {dataval "body"} val} {
	return [nda set "usernames/$nick/setuser/[ndaenc $datafield]/[ndaenc $dataval]" $val]
}

proc msgxtra {from msg} {
	if {[set log [tnda get "login/$::netname($::sock)/$from"]]==""} {
		p10 notice $::sock 77 $from "Until you've registered with the bot, you have no business setting XTRA values."
		return
	}
	set subfield [lindex $msg 0 0]
	set value [join [lrange [lindex $msg 0] 1 end] " "]
	setuser $log "XTRA" $subfield $value
	p10 notice $::sock 77 $from "Set your user record XTRA $subfield to $value."
}

proc chandname2name {channame} {return $channame}
proc channame2dname {channame} {return $channame}

proc islinked {bot} {return 0}
