#source chanserv.conf

#llbind [curctx sock] mode "-" "+" bitchopcheck
#llbind [curctx sock] mode "-" "-" protectopcheck
#llbind [curctx sock] join "-" "-" autoopcheck

proc protectopcheck {mc f t p} {
	if {"o"==$mc && ![channel get $t protectop]} {return}
	if {"h"==$mc && ![channel get $t protecthalfop]} {return}
	if {"v"==$mc && ![channel get $t protectvoice]} {return}
	switch -- $mc {
		"o" {
			if {[matchattr [tnda get "login/[curctx net]/$p"] omn|omn $t]} {
				[curctx proto] putmode [curctx sock] 77 $t +$mc "$p" [tnda get "channels/[curctx net]/[ndaenc $t]/ts"]
			}
		}
		"h" {
			if {[matchattr [tnda get "login/[curctx net]/$p"] l|l $t]} {
				[curctx proto] putmode [curctx sock] 77 $t +$mc "$p" [tnda get "channels/[curctx net]/[ndaenc $t]/ts"]
			}
		}
		"v" {
			if {[matchattr [tnda get "login/[curctx net]/$p"] v|v $t]} {
				[curctx proto] putmode [curctx sock] 77 $t +$mc "$p" [tnda get "channels/[curctx net]/[ndaenc $t]/ts"]
			}
		}
	}
}

proc finduserbyid {n} {
	tnda get "login/[curctx net]/$f"
}

proc autoopcheck {c f} {
	set globe 0
	if {[channel get $c operit]} {set globe 1}
	if {[channel get $c autoop]} {set auto nmo} {set auto ""}
	if {[channel get $c autohalfop]} {append auto l}
	if {[channel get $c autovoice]} {append auto v}
	tcs:opcheck $c $f $globe $auto
}

proc tcs:opcheck {c f {globe 0} {auto nmolv}} {
#	puts stdout "$c $f"
	if {[matchattr [tnda get "login/[curctx net]/$f"] |k $c]} {
		# obviously optimised for charybdis... ???
		[curctx proto] putmode [curctx sock] 77 $c +b "*![tnda get "ident/[curctx net]/$f"]@[tnda get "vhost/[curctx net]/$f"]" [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		[curctx proto] kick [curctx sock] 77 $c $f "Autokicked (+k attribute)"
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] n|] && $globe} {
		[curctx proto] putmode [curctx sock] 77 $c +[tnda get "pfx/owner"] $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] |n $c] && ([string first "o" $auto] != -1)} {
		[curctx proto] putmode [curctx sock] 77 $c +[tnda get "pfx/owner"] $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}

	if {[matchattr [tnda get "login/[curctx net]/$f"] m|] && $globe} {
		[curctx proto] putmode [curctx sock] 77 $c +[tnda get "pfx/protect"] $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] |m $c] && ([string first "o" $auto] != -1)} {
		[curctx proto] putmode [curctx sock] 77 $c +[tnda get "pfx/protect"] $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}

	if {[matchattr [tnda get "login/[curctx net]/$f"] a|]} {
		[curctx proto] putmode [curctx sock] 77 $c +o $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] o|] && $globe} {
		[curctx proto] putmode [curctx sock] 77 $c +o $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] |o $c] && ([string first "o" $auto] != -1)} {
		[curctx proto] putmode [curctx sock] 77 $c +o $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] l|] && $globe} {
		[curctx proto] putmode [curctx sock] 77 $c +[tnda get "pfx/halfop"] $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] |l $c] && ([string first "h" $auto] != -1)} {
		[curctx proto] putmode [curctx sock] 77 $c +[tnda get "pfx/halfop"] $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] v|] && $globe} {
		[curctx proto] putmode [curctx sock] 77 $c +v $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] |v $c] && ([string first "v" $auto] != -1)} {
		[curctx proto] putmode [curctx sock] 77 $c +v $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
}

proc bitchopcheck {mc ftp} {
	set f [lindex $ftp 0]
	set t [lindex $ftp 1]
	set p [lindex $ftp 2]
	puts stdout "$ftp"
	if {[tnda get "pfx/owner"]==$mc && ![channel get $t bitch]} {return} {if {[tnda get "pfx/owner"] != q} {set mc q}}
	if {[tnda get "pfx/protect"]==$mc && ![channel get $t bitch]} {return} {if {[tnda get "pfx/protect"] != a} {set mc a}}
	if {"o"==$mc && ![channel get $t bitch]} {return}
	if {"h"==$mc && ![channel get $t halfbitch]} {return}
	if {"v"==$mc && ![channel get $t voicebitch]} {return}
	switch -glob -- $mc {
		"q" {
			if {![matchattr [tnda get "login/[curctx net]/$p"] n|n $t]} {
				puts stdout "M $t -$mc $p [nda get "regchan/[ndaenc $t]/ts"]"
				[curctx proto] putmode [curctx sock] 77 $t "-$mc" "$p" [nda get "regchan/[ndaenc $t]/ts"]
			}
		}
		"a" {
			if {![matchattr [tnda get "login/[curctx net]/$p"] mn|mn $t]} {
				puts stdout "M $t -$mc $p [nda get "regchan/[ndaenc $t]/ts"]"
				[curctx proto] putmode [curctx sock] 77 $t "-$mc" "$p" [nda get "regchan/[ndaenc $t]/ts"]
			}
		}
		"o" {
			if {![matchattr [tnda get "login/[curctx net]/$p"] aomn|omn $t]} {
				puts stdout "M $t -$mc $p [nda get "regchan/[ndaenc $t]/ts"]"
				[curctx proto] putmode [curctx sock] 77 $t "-$mc" "$p" [nda get "regchan/[ndaenc $t]/ts"]
			}
		}
		"h" {
			if {![matchattr [tnda get "login/[curctx net]/$p"] l|l $t]} {
				puts stdout "M $t -$mc $p [nda get "regchan/[ndaenc $t]/ts"]"
				[curctx proto] putmode [curctx sock] 77 $t "-$mc" "$p" [nda get "regchan/[ndaenc $t]/ts"]
			}
		}
		"v" {
			if {![matchattr [tnda get "login/[curctx net]/$p"] v|v $t]} {
				puts stdout "M $t -$mc $p [nda get "regchan/[ndaenc $t]/ts"]"
				[curctx proto] putmode [curctx sock] 77 $t "-$mc" "$p" [nda get "regchan/[ndaenc $t]/ts"]
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

proc isbotnick {n} {return [expr {$n == $::globuctx}]}

set globctx ""
set globuctx ""

proc setctx {ctx} {
	global globctx
	if {[catch [list set ::sock($ctx)] erre] > 0} {return} ; # silently crap out
	set globctx $ctx
}

proc setuctx {ctx} {
	global globuctx
	if {[% nick2uid $ctx] == ""} {return} ; # silently crap out
	set globuctx [% uid2intclient [% nick2uid $ctx]]
}

proc % {c args} {
	set ul [list [curctx proto] $c [curctx sock]]
	foreach {a} $args {lappend ul $a}
	uplevel 1 $a
}

proc curctx {{type .net}} {
	if {$::globctx == ""} {return ""}
	switch -exact -- [format ".%s" [string tolower $type]] {
		.sock {
			return $::sock($::globctx)
		}
		.net {
			return $::globctx
		}
		.unum {
			return $::globuctx
		}
		.uid {
			return [% intclient2uid $::globuctx]
		}
		.user {
			return [% uid2nick [% intclient2uid $::globuctx]]
		}
		.proto {
			return $::nettype($::globctx)
		}
	}
}

foreach {pname} [list putserv puthelp putquick putnow] {
	proc $pname {msg} {
		puts [curctx sock] [[curctx proto] formprefix [curctx sock] $msg]
	}
}

proc msgmt {from msg} {
	set handle [lindex $msg 0]
	set attr [lindex $msg 1]
	set chan [lindex $msg 2]
	[curctx proto] notice [curctx sock] 77 $from "$handle $attr $chan Matchattr result: [matchattr $handle $attr $chan]"
}

#llbind [curctx sock] msg 77 "matchattr" msgmt

proc matchattr {handle attr {chan "*"}} {
	set handle [string tolower $handle]
	if {-1!=[string first "&" $attr]} {set and 1} {set and 0}
	set gattr [lindex [split $attr "&|"] 0]
	set cattr [lindex [split $attr "&|"] 1]
	set isattrg 0
	foreach {c} [split [nda get "eggcompat/[curctx net]/attrs/global/$handle"] {}] {
		foreach {k} [split $gattr {}] {
			if {$c == $k} {set isattrg 1}
		}
	}
	set isattrc 0
	if {"*"!=$chan} {
		foreach {c} [split [nda get "eggcompat/[curctx net]/attrs/[ndaenc $chan]/$handle"] {}] {
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
		nda set "eggcompat/[curctx net]/attrs/global/$handle" [join [concat [string map $del [nda get "eggcompat/[curctx net]/attrs/global/$handle"]] $app] ""]
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
		nda set "eggcompat/[curctx net]/attrs/[ndaenc $chan]/$handle" [join [concat [string map $del [nda get "eggcompat/[curctx net]/attrs/[ndaenc $chan]/$handle"]] $app] ""]
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
		if {[::set enda [nda get "eggcompat/[curctx net]/chansets/[ndaenc $chan]/[ndaenc [string map {+ ""} $flag]]"]]!=""} {return $enda} {return 0}
	}
	proc ::channel::set {chan flags} {
		if {[llength $flags] != 1} {
			foreach {flag} $flags {
				::set bit [string index $flag 0]
				if {$bit=="+"} {::set bitt 1} {::set bitt 0}
				::set flag [string range $flag 1 end]
				nda set "eggcompat/[curctx net]/chansets/[ndaenc $chan]/[ndaenc [string map {+ ""} $flag]]" $bitt
			}
		} {
			::set bit [string index $flags 0]
			if {$bit=="+"} {::set bitt 1} {::set bitt 0}
			::set flag [string range $flags 1 end]
			nda set "eggcompat/[curctx net]/chansets/[ndaenc $chan]/[ndaenc [string map {+ ""} $flags]]" $bitt
		}
	}
	namespace export *
	namespace ensemble create
}

proc validuser {n} {
	if {""==[nda get "usernames/$n"]} {return 0} {return 1}
}

#llbind [curctx sock] msg 77 "chanset" msgchanset
#llbind [curctx sock] msg 77 "chattr" msgchattr
#llbind [curctx sock] msg 77 "setxtra" msgxtra
#set botnick $cs(nick)
#chattr $cs(admin) +mnolv

proc msgchanset {from msg} {
	set ndacname [ndaenc [lindex $msg 0 0]]
	set chanset [lindex $msg 0 1]
	if {300>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$from"]]"] && ![matchattr [tnda get "login/[curctx net]/$from"] m|m [lindex $msg 0 0]]} {
		[curctx proto] notice [curctx sock] 77 $from "Only channel super-operators (300) and above and network masters may use eggdrop-compatible chansets."
		return
	}
	channel set [lindex $msg 0 0] $chanset
	[curctx proto] notice [curctx sock] 77 $from "Eggdrop compatible chanset $chanset set on [lindex $msg 0 0]."
}

proc msgchattr {from msg} {
	set ndacname [ndaenc [lindex $msg 0 2]]
	set handle [lindex $msg 0 0]
	set hand [lindex $msg 0 0]
	set attrs [lindex $msg 0 1]
	set chan [lindex $msg 0 2]
	set ch [lindex $msg 0 2]
	foreach {c} [split $attrs {}] {
		if {$c == "+"} {continue}
		if {$c == "-"} {continue}
		if {$c == "k"} {set c "mn|mnol"}
		if {$c == "v"} {set c "mn|lmno"}
		if {$c == "l"} {set c "mn|mno"}
		if {$c == "o"} {set c "mn|omn"}
		if {$c == "m"} {set c "mn|mn"}
		if {$c == "n"} {set c "n|n"}
		if {$c == "a"} {set c "mn|"}
		if {![matchattr [tnda get "login/[curctx net]/$from"] $c $chan]} {
			[curctx proto] notice [curctx sock] 77 $from "You may only give flags you already possess (Any of flags $c required to set $attrs)."
			return
		}
	}
	if {""==$chan} {chattr $hand $attrs} {chattr $hand $attrs $chan}
	[curctx proto] notice [curctx sock] 77 $from "Global flags for $hand are now [nda get "eggcompat/[curctx net]/attrs/global/[string tolower $handle]"]"
	if {""==[nda get "regchan/$ndacname/levels/[string tolower $hand]"]} {nda set "regchan/$ndacname/levels/[string tolower $hand]" 1}
	if {$ch != ""} {[curctx proto] notice [curctx sock] 77 $from "Flags on $chan for $hand are now [nda get "eggcompat/[curctx net]/attrs/$ndacname/[string tolower $handle]"]"}
}

proc nick2hand {nick} {
	foreach {uid nic} [tnda get "nick"] {
		if {$nick == $nic} {return [tnda get "login/[curctx net]/$uid"]}
	}
}

proc uid2hand {uid} {
	return [tnda get "login/[curctx net]/$uid"]
}

proc getuser {nick datafield {dataval "body"}} {
	return [nda get "usernames/$nick/setuser/[ndaenc $datafield]/[ndaenc $dataval]"]
}

proc setuser {nick datafield {dataval "body"} val} {
	return [nda set "usernames/$nick/setuser/[ndaenc $datafield]/[ndaenc $dataval]" $val]
}

proc msgxtra {from msg} {
	if {[set log [tnda get "login/[curctx net]/$from"]]==""} {
		[curctx proto] notice [curctx sock] 77 $from "Until you've registered with the bot, you have no business setting XTRA values."
		return
	}
	set subfield [lindex $msg 0 0]
	set value [join [lrange [lindex $msg 0] 1 end] " "]
	setuser $log "XTRA" $subfield $value
	[curctx proto] notice [curctx sock] 77 $from "Set your user record XTRA $subfield to $value."
}

proc chandname2name {channame} {return $channame}
proc channame2dname {channame} {return $channame}

proc islinked {bot} {return 0}

proc operHasPrivilege {n i p} {
	# this bit requires irca.
	set metadatum [tnda get "metadata/$n/$i/[ndcenc PRIVS]"]
	set md [split $metadatum " "]
	set pl [split $p " ,"]
	foreach {pv} $pl {
		if {[lsearch $md $pv] != -1} {return 1}
	}
	return 0
}

proc operHasAllPrivileges {n i p} {
	# this bit requires irca.
	set metadatum [tnda get "metadata/$n/$i/[ndcenc PRIVS]"]
	set md [split $metadatum " "]
	set pl [split $p " ,"]
	foreach {pv} $pl {
		if {[lsearch $md $pv] == -1} {return 0}
	}
	return 1
}

proc isop {chan id} {
	return [ismode $chan $id o]
}

proc isvoice {chan id} {
	return [ismode $chan $id v]
}

proc ishalf {chan id} {
	return [ismode $chan $id h]
}

proc ismode {chan id mode} {
	if {[string first $mode [[curctx proto] getupfx [curctx sock] $chan $id]] != -1} {return 1} {return 0}
}

proc ismodebutnot {chan id mode} {
	if {[string length [[curctx proto] getupfx [curctx sock] $chan $id]] > 0 && [string first $mode [[curctx proto] getupfx [curctx sock] $chan $id]] == -1} {return 1} {return 0}
}

# rules are odd. you should store the bind return in a variable to unbind it.
# flags aren't part of the bind define.
proc bind {type flag text script} {
	set ctxsock [curctx sock]
	set ctxuser [curctx unum]
	return [llbind $ctxsock $type $ctxuser [list matchthenrun $ctxsock $ctxuser $flag $script]]
}

proc matchthenrun {sock user flags script args} {
	#setctx $sock
	foreach {a} $args {
		lappend script $a
	}
#	matchattr [uid2hand $user] $flags
	eval $script
}
