$::maintype sendUid $::sock "L" "limitserv" "services." "services." 47 "Channel Limit Adjustment Services"
foreach {chan is} [nda get "limitserv/regchan"] {
	if {1!=$is} {continue}
	$::maintype putjoin $::sock 47 [::base64::decode [string map {[ /} $chan]] [nda get "regchan/$chan/ts"]
	tnda set "channels/$chan/ts" [nda get "regchan/$chan/$::netname($::sock)/ts"]
}
bind $::sock request "l" "-" limitservjoin
bind $::sock request "limitserv" "-" limitservjoin
bind $::sock join "-" "-" limitservup
bind $::sock part "-" "-" limitservdown
bind $::sock pub "-" "!dolimit" limitservdochan

after 300000 {limitservdo}

proc limitservup {chan msg} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	if {""==[tnda get "limitserv/$::netname($::sock)/$ndacname"]} {set i 1} {set i [expr {[tnda get "limitserv/$::netname($::sock)/$ndacname"] + 1}]}
	tnda set "limitserv/$::netname($::sock)/$ndacname" $i
#	intlimitservdochan $chan
}

proc limitservdown {chan msg} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	if {""==[tnda get "limitserv/$::netname($::sock)/$ndacname"]} {set i 0} {set i [expr {[tnda get "limitserv/$::netname($::sock)/$ndacname"] - 1}]}
	tnda set "limitserv/$::netname($::sock)/$ndacname" $i
#	intlimitservdochan $chan
}

proc limitservjoin {chan ft} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	$::maintype putjoin $::sock 47 $chan [nda get "regchan/$ndacname/ts"]
	nda set "limitserv/regchan/$ndacname" 1
}

proc limitservdo {} {
	foreach {chan is} [nda get "limitserv/regchan"] {
		if {1!=$is} {continue}
		$::maintype putmode $::sock 47 [::base64::decode [string map {[ /} $chan]] "+l" [expr {[tnda get "limitserv/$::netname($::sock)/$chan"] + 10}] [nda get "regchan/$chan/ts"]
	}
	after 300000 {limitservdo}
}

proc limitservdochan {cname msg} {
	set chan [string map {/ [} [::base64::encode [string tolower $cname]]]
	set from [lindex $msg 0 0]
	if {150>[nda get "regchan/$chan/levels/[string tolower [tnda get "login/$::netname($::sock)/$from"]]"]} {
		$::maintype privmsg $::sock 47 $cname "You must be at least halfop to manually trigger autolimit on the channel."
		return
	}
	$::maintype putmode $::sock 47 $cname "+l" [expr {[tnda get "limitserv/$::netname($::sock)/$chan"] + 14}] [nda get "regchan/$chan/ts"]
}

proc intlimitservdochan {cname} {
	set chan [string map {/ [} [::base64::encode [string tolower $cname]]]
	$::maintype putmode $::sock 47 $cname "+l" [expr {[tnda get "limitserv/$::netname($::sock)/$chan"] + 14}] [nda get "regchan/$chan/ts"]
}
