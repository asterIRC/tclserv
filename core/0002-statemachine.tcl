
proc nick2uid {sck nick} {
	foreach {u n} [tnda get "nick/$::netname($sck)"] {
		if {[string tolower $n] == [string tolower $nick]} {return $u}
	}
	return ""
}
proc intclient2uid {sck nick} {
	foreach {u n} [tnda get "intclient/$::netname($sck)"] {
		if {[string tolower $n] == [string tolower $nick]} {return $u}
	}
	return ""
}
proc uid2nick {sck u} {
	return [tnda get "nick/$::netname($sck)/$u"]
}
proc uid2rhost {sck u} {
	return [tnda get "rhost/$::netname($sck)/$u"]
}
proc uid2host {sck u} {
	return [tnda get "vhost/$::netname($sck)/$u"]
}
proc uid2ident {sck u} {
	return [tnda get "ident/$::netname($sck)/$u"]
}
proc nick2host {sck nick} {
	return [tnda get "vhost/$::netname($sck)/[nick2uid $netname $nick]"]
}
proc nick2ident {sck nick} {
	return [tnda get "ident/$::netname($sck)/[nick2uid $netname $nick]"]
}
proc nick2rhost {sck nick} {
	return [tnda get "rhost/$::netname($sck)/[nick2uid $netname $nick]"]
}
proc nick2ipaddr {sck nick} {
	return [tnda get "ipaddr/$::netname($sck)/[nick2uid $netname $nick]"]
}
proc getts {sck chan} {
	return [tnda get "channels/$::netname($sck)/[ndaenc $chan]/ts"]
}
proc getpfx {sck chan nick} {
	return [tnda get "channels/$::netname($sck)/[ndaenc $chan]/modes/[nick2uid $netname $nick]"]
}
proc getupfx {sck chan u} {
	return [tnda get "channels/$::netname($sck)/[ndaenc $chan]/modes/$u"]
}
proc getpfxchars {sck modes} {
	set o ""
	foreach {c} [split $modes {}] {
		append o [nda get "netinfo/$::netname($sck)/prefix/$c"]
	}
	return $o
}
proc getmetadata {sck nick metadatum} {
	return [tnda get "metadata/$::netname($sck)/[nick2uid $netname $nick]/[ndcenc $metadatum]"]
}
proc getcertfp {sck nick} {
	return [tnda get "certfps/$::netname($sck)/[nick2uid $netname $nick]"]
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

proc uid2intclient {sck u} {
	return [tnda get "intclient/$::netname($sck)/$u"]
}

proc getfreeuid {sck} {
set work 1
set cns [list]
foreach {_ cnum} [tnda get "intclient/$::netname($sck)"] {lappend cns $cnum}
while {0!=$work} {set num [expr {[rand 30000]+10000}];if {[lsearch -exact $cns $num]==-1} {set work 0}}
return $num
}
