sendUid $::sock "L" "limitserv" "services." "services." 47 "Channel Limit Adjustment Services"
foreach {chan is} [nda get "limitserv/regchan"] {
	if {1!=$is} {continue}
	putjoin $::sock 47 [::base64::decode [string map {[ /} $chan]] [nda get "regchan/$chan/ts"]
	tnda set "channels/$chan/ts" [nda get "regchan/$chan/ts"]
}
bind request "l" "-" limitservjoin
bind request "limitserv" "-" limitservjoin
bind join "-" "-" limitservup
bind part "-" "-" limitservdown
bind pub "-" "!dolimit" limitservdochan

after 60000 {limitservdo}

proc limitservup {chan msg} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	if {""==[tnda get "limitserv/$ndacname"]} {set i 1} {set i [expr {[tnda get "limitserv/$ndacname"] + 1}]}
	tnda set "limitserv/$ndacname" $i
}

proc limitservdown {chan msg} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	if {""==[tnda get "limitserv/$ndacname"]} {set i 0} {set i [expr {[tnda get "limitserv/$ndacname"] - 1}]}
	tnda set "limitserv/$ndacname" $i
}

proc limitservjoin {chan msg} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	putjoin $::sock 47 $chan [nda get "regchan/$ndacname/ts"]
	nda set "limitserv/regchan/$ndacname" 1
}

proc limitservdo {} {
	foreach {chan is} [nda get "limitserv/regchan"] {
		if {1!=$is} {continue}
		putmode $::sock 47 [::base64::decode [string map {[ /} $chan]] "+l" [expr {[tnda get "limitserv/$chan"] + 10}] [nda get "regchan/$chan/ts"]
	}
	after 60000 {limitservdo}
}

proc limitservdochan {cname msg} {
	set chan [string map {/ [} [::base64::encode [string tolower $cname]]]
	set from [lindex $msg 0 0]
	if {150>[nda get "regchan/$chan/levels/[string tolower [tnda get "login/$from"]]"]} {
		privmsg $::sock 47 $cname "You must be at least halfop to manually trigger autolimit on the channel."
		return
	}
	putmode $::sock 47 $cname "+l" [expr {[tnda get "limitserv/$chan"] + 10}] [nda get "regchan/$chan/ts"]
}
