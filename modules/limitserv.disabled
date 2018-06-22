$::maintype sendUid $::sock($::cs(netname)) "L" "limitserv" "services." "services." 47 "Channel Limit Adjustment Services"
foreach {chan is} [nda get "limitserv/regchan"] {
	if {1!=$is} {continue}
	$::maintype putjoin $::sock($::cs(netname)) 47 [::base64::decode [string map {[ /} $chan]] [nda get "regchan/$chan/ts"]
	tnda set "channels/$chan/ts" [nda get "regchan/$chan/$::netname($::sock($::cs(netname)))/ts"]
}
bind $::sock($::cs(netname)) request "l" "-" limitservjoin
bind $::sock($::cs(netname)) request "limitserv" "-" limitservjoin
bind $::sock($::cs(netname)) join "-" "-" limitservup
bind $::sock($::cs(netname)) part "-" "-" limitservdown
bind $::sock($::cs(netname)) pub "-" "!dolimit" limitservdochan

after 300000 {limitservdo}

proc limitservup {chan msg} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	if {""==[tnda get "limitserv/$::netname($::sock($::cs(netname)))/$ndacname"]} {set i 1} {set i [expr {[tnda get "limitserv/$::netname($::sock($::cs(netname)))/$ndacname"] + 1}]}
	tnda set "limitserv/$::netname($::sock($::cs(netname)))/$ndacname" $i
#	intlimitservdochan $chan
}

proc limitservdown {chan msg} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	if {""==[tnda get "limitserv/$::netname($::sock($::cs(netname)))/$ndacname"]} {set i 0} {set i [expr {[tnda get "limitserv/$::netname($::sock($::cs(netname)))/$ndacname"] - 1}]}
	tnda set "limitserv/$::netname($::sock($::cs(netname)))/$ndacname" $i
#	intlimitservdochan $chan
}

proc limitservjoin {chan ft} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	$::maintype putjoin $::sock($::cs(netname)) 47 $chan [nda get "regchan/$ndacname/ts"]
	nda set "limitserv/regchan/$ndacname" 1
}

proc limitservdo {} {
	foreach {chan is} [nda get "limitserv/regchan"] {
		if {1!=$is} {continue}
		$::maintype putmode $::sock($::cs(netname)) 47 [::base64::decode [string map {[ /} $chan]] "+l" [expr {[tnda get "limitserv/$::netname($::sock($::cs(netname)))/$chan"] + 10}] [nda get "regchan/$chan/ts"]
	}
	after 300000 {limitservdo}
}

proc limitservdochan {cname msg} {
	set chan [string map {/ [} [::base64::encode [string tolower $cname]]]
	set from [lindex $msg 0 0]
	if {150>[nda get "regchan/$chan/levels/[string tolower [tnda get "login/$::netname($::sock($::cs(netname)))/$from"]]"]} {
		$::maintype privmsg $::sock($::cs(netname)) 47 $cname "You must be at least halfop to manually trigger autolimit on the channel."
		return
	}
	$::maintype putmode $::sock($::cs(netname)) 47 $cname "+l" [expr {[tnda get "limitserv/$::netname($::sock($::cs(netname)))/$chan"] + 14}] [nda get "regchan/$chan/ts"]
}

proc intlimitservdochan {cname} {
	set chan [string map {/ [} [::base64::encode [string tolower $cname]]]
	$::maintype putmode $::sock($::cs(netname)) 47 $cname "+l" [expr {[tnda get "limitserv/$::netname($::sock($::cs(netname)))/$chan"] + 14}] [nda get "regchan/$chan/ts"]
}
