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

proc matchattr {handle attr {chan "*"}} {
	if {$chan == "*"} {
		set isattr 0
		foreach {c} [split [nda get "eggcompat/attrs/global/$handle"] {}] {
			foreach {k} [split $attr {}] {
				if {$c == $k} {set isattr 1}
			}
		}
	} {
		set isattr 0
		foreach {c} [split [nda get "eggcompat/attrs/[ndaenc $chan]/$handle"] {}] {
			foreach {k} [split $attr {}] {
				if {$c == $k} {set isattr 1}
			}
		}
	}
	return $isattr
}

proc chattr {handle attr {chan "*"}} {
	if {$chan == "*"} {
		foreach {c} [split $attr {}] {
			switch -glob -- $c {
				"+" {set state app}
				"-" {set state del}
				"*" {
					if {$state=="del"} {
						lappend del $c ""
					}
					if {$state=="app"} {
						append app $c
					}
				}
			}
		}
		nda set "eggcompat/attrs/global/$handle" [join [concat [string map $del [nda get "eggcompat/attrs/global/$handle"] $app]] ""]
	} {
		foreach {c} [split $attr {}] {
			switch -glob -- $c {
				"+" {set state app}
				"-" {set state del}
				"*" {
					if {$state=="del"} {
						lappend del $c ""
					}
					if {$state=="app"} {
						append app $c
					}
				}
			}
		}
		nda set "eggcompat/attrs/[ndaenc $chan]/$handle" [join [concat [string map $del [nda get "eggcompat/attrs/[ndaenc $chan]/$handle"] $app]] ""]
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
	proc ::channel::set {chan flag} {
		::set bit [string index $flag 0]
		if {$bit=="+"} {::set bitt 1} {::set bitt 0}
		::set flag [string range $flag 1 end]
		return [nda set "eggcompat/chansets/[ndaenc $chan]/[ndaenc [string map {+ ""} $flag]]" $bitt]
	}
	namespace export *
	namespace ensemble create
}

proc validuser {n} {
	if {""==[nda get "usernames/$n"]} {return 0} {return 1}
}

bind msg 77 "chanset" msgchanset
bind msg 77 "setxtra" msgxtra
set botnick $cs(nick)

proc msgchanset {from msg} {
	set ndacname [ndaenc [lindex $msg 0 0]]
	set chanset [lindex $msg 0 1]
	if {300>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$from"]]"]} {
		notice $::sock 77 $from "Only channel super-operators (300) and above may use eggdrop-compatible chansets."
	}
	channel set [lindex $msg 0 0] $chanset
	notice $::sock 77 $from "Eggdrop compatible chanset $chanset set on [lindex $msg 0 0]."
}

proc nick2hand {nick} {
	foreach {uid nic} [tnda get "nick"] {
		if {$nick == $nic} {return [tnda get "login/$uid"]}
	}
}

proc getuser {nick datafield {dataval "body"}} {
	return [nda get "usernames/$nick/setuser/[ndaenc $datafield]/[ndaenc $dataval]"]
}

proc setuser {nick datafield {dataval "body"} val} {
	return [nda set "usernames/$nick/setuser/[ndaenc $datafield]/[ndaenc $dataval]" $val]
}

proc msgxtra {from msg} {
	if {[set log [tnda get "login/$from"]]==""} {
		notice $::sock 77 $from "Until you've registered with the bot, you have no business setting XTRA values."
		return
	}
	set subfield [lindex $msg 0 0]
	set value [join [lrange [lindex $msg 0] 1 end] " "]
	setuser $log "XTRA" $subfield $value
	notice $::sock 77 $from "Set your user record XTRA $subfield to $value."
}

proc chandname2name {channame} {return $channame}
proc channame2dname {channame} {return $channame}

proc islinked {bot} {return 0}
