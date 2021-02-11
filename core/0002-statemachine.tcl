
proc nick2uid {nick} {
	set sck [curctx sock]
	foreach {u n} [tnda get "nick/[curctx net]"] {
		if {[string tolower $n] == [string tolower $nick]} {return $u}
	}
	return ""
}
proc intclient2uid {nick} {
	set sck [curctx sock]
	foreach {u n} [tnda get "intclient/[curctx net]"] {
		if {[string tolower $n] == [string tolower $nick]} {return $u}
	}
	return ""
}
proc intclient2nick {nick} {
	set sck [curctx sock]
	foreach {u n} [tnda get "intclient/[curctx net]"] {
		if {[string tolower $n] == [string tolower $nick]} {return [uid2nick $u]}
	}
	return ""
}
proc uid2nick {u} {
	set sck [curctx sock]
	return [tnda get "nick/[curctx net]/$u"]
}
proc uid2rhost {u} {
	set sck [curctx sock]
	return [tnda get "rhost/[curctx net]/$u"]
}
proc uid2host {u} {
	set sck [curctx sock]
	return [tnda get "vhost/[curctx net]/$u"]
}
proc uid2ident {u} {
	set sck [curctx sock]
	return [tnda get "ident/[curctx net]/$u"]
}
proc nick2host {nick} {
	set sck [curctx sock]
	return [tnda get "vhost/[curctx net]/[nick2uid $netname $nick]"]
}
proc nick2ident {nick} {
	set sck [curctx sock]
	return [tnda get "ident/[curctx net]/[nick2uid $netname $nick]"]
}
proc nick2rhost {nick} {
	set sck [curctx sock]
	return [tnda get "rhost/[curctx net]/[nick2uid $netname $nick]"]
}
proc nick2ipaddr {nick} {
	set sck [curctx sock]
	return [tnda get "ipaddr/[curctx net]/[nick2uid $netname $nick]"]
}
proc getts {chan} {
	set sck [curctx sock]
	return [tnda get "channels/[curctx net]/[ndaenc $chan]/ts"]
}
proc getpfx {chan nick} {
	set sck [curctx sock]
	return [tnda get "channels/[curctx net]/[ndaenc $chan]/modes/[nick2uid $netname $nick]"]
}
proc getupfx {chan u} {
	return [tnda get "channels/[curctx net]/[ndaenc $chan]/modes/$u"]
	set sck [curctx sock]
}
proc getpfxchars {modes} {
	set sck [curctx sock]
	set o ""
	foreach {c} [split $modes {}] {
		append o [nda get "netinfo/[curctx net]/prefix/$c"]
	}
	return $o
}
proc getmetadata {nick metadatum} {
	set sck [curctx sock]
	return [tnda get "metadata/[curctx net]/[nick2uid $netname $nick]/[ndcenc $metadatum]"]
}
proc getcertfp {nick} {
	set sck [curctx sock]
	return [tnda get "certfps/[curctx net]/[nick2uid $netname $nick]"]
}

proc checkop {mc s c p n} {
	set f $s
	set t $c
	if {[tnda get "netinfo/$n/pfxchar/$mc"]==""} {return}
putcmdlog "up $mc $f $t $p $n"
  set chan [string map {/ [} [::base64::encode [string tolower $t]]]
  tnda set "channels/$n/$chan/modes/$p" [format {%s%s} [string map [list $mc ""] [tnda get "channels/$n/$chan/modes/$p"]] $mc]
}

proc checkdeop {mc s c p n} {
	set f $s
	set t $c
	if {[tnda get "netinfo/$n/pfxchar/$mc"]==""} {return}
putcmdlog "down $mc $f $t $p $n"
  set chan [string map {/ [} [::base64::encode [string tolower $t]]]
  tnda set "channels/$n/$chan/modes/$p" [string map [list $mc ""] [tnda get "channels/$n/$chan/modes/$p"]]
}

proc uid2intclient {u} {
	set sck [curctx sock]
	return [tnda get "intclient/[curctx net]/$u"]
}

proc getfreeuid {} {
	set sck [curctx sock]
set work 1
set cns [list]
foreach {_ cnum} [tnda get "intclient/[curctx net]"] {lappend cns $cnum}
while {0!=$work} {set num [expr {[rand 30000]+10000}];if {[lsearch -exact $cns $num]==-1} {set work 0}}
return $num
}
