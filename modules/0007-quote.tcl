$::maintype sendUid $::sock "Q" "quoteserv" "services." "services." 107 "Quote Storage Services"
foreach {chan is} [nda get "quoteserv/regchan"] {
	if {1!=$is} {continue}
	$::maintype putjoin $::sock 107 [::base64::decode [string map {[ /} $chan]] [nda get "regchan/$chan/ts"]
	tnda set "channels/$chan/ts" [nda get "regchan/$chan/$::netname($::sock)/ts"]
}
bind $::sock request "q" "-" quoteservjoin
bind $::sock request "quoteserv" "-" quoteservjoin
bind $::sock pub "-" "!quote" quoteservdo
bind $::sock pub "-" "!q" quoteservdo

proc quoteservjoin {chan msg} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	$::maintype putjoin $::sock 107 $chan [nda get "regchan/$ndacname/ts"]
	nda set "quoteserv/regchan/$ndacname" 1
}

proc quoteservenabled {chan} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	return [nda get "quoteserv/regchan/$ndacname"]
}

proc quoteservdo {chan msg} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	if {![quoteservenabled $chan]} {return}
	# Q isn't in channel, no need to check quotes
	set from [lindex $msg 0 0]
	set subcmd [lindex $msg 1 0]
	set para [lrange [lindex $msg 1] 1 end]
	switch -nocase -glob -- $subcmd {
		"sea*" {
			set ptn "*[join $para " "]*"
			set qts [quotesearch $chan $ptn]
			if {[llength $qts]} {$::maintype privmsg $::sock 107 $chan "\[\002Quotes\002\] Found quotes numbered #[join $qts ",#"]"} {
				$::maintype privmsg $::sock 107 $chan "\[\002Quotes\002\] No quotes found for pattern"
			}
		}
		"vi*1st*ma*" {
			set ptn "*[join $para " "]*"
			set qts [quotesearch $chan $ptn]
			if {[llength $qts]} {set qtn [lindex $qts 0];$::maintype privmsg $::sock 107 $chan "\[\002Quotes\002\] Quote number #$qtn:";$::maintype privmsg $::sock 107 $chan "\[\002Quotes\002\] [nda get "quoteserv/quotes/$ndacname/$qtn"]"} {
				$::maintype privmsg $::sock 107 $chan "\[\002Quotes\002\] No quotes found for pattern"
			}
		}
		"ad*" {
			set qt [join $para " "]
			set qtn [expr {([llength [nda get "quoteserv/quotes/$ndacname"]]/2)+3}]
			nda set "quoteserv/quotes/$ndacname/$qtn" $qt
			$::maintype privmsg $::sock 107 $chan "\[\002Quotes\002\] Added quote number #$qtn to database."
		}
		"de*" {
			set qtn "[lindex $para 0]"
			if {![string is integer $qtn]} {$::maintype privmsg $::sock 107 $chan "\[\002Quotes\002\] Please use a valid integer (without the #)"}
			if {150>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$::netname($::sock)/$from"]]"]} {$::maintype privmsg $::sock 107 $chan "\[\002Quotes\002\] Check your privilege."}
			nda set "quoteserv/quotes/$ndacname/$qtn" ""
			$::maintype privmsg $::sock 107 $chan "\[\002Quotes\002\] Blanked quote number #$qtn in database."
		}
		"vi*" {
			set qtn "[lindex $para 0]"
			if {![string is integer $qtn]} {$::maintype privmsg $::sock 107 $chan "\[\002Quotes\002\] Please use a valid integer (without the #)"}
			set qt [nda get "quoteserv/quotes/$ndacname/$qtn"]
			if {$qt != ""} {
				$::maintype privmsg $::sock 107 $chan "\[\002Quotes\002\] Quote number #$qtn:"
				$::maintype privmsg $::sock 107 $chan "\[\002Quotes\002\] $qt"
			}
		}
		"he*" {
			set helpfile {             ---- Quotes Help ----
!quote search - Search for quotes matching
!quote view1stmatch - Search for quotes matching and view first matching quote.
!quote view - View quote
!quote add - Add quote.
!quote del - Delete quote. Requires halfops or above.
End of help for Q.}
			foreach {helpline} [split $helpfile "\r\n"] {
				$::maintype notice $::sock 107 $from $helpline
			}
		}
	}
}

proc quotesearch {chan pattern} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	set ret [list]
	foreach {qnum qvalue} [nda get "quoteserv/quotes/$ndacname"] {
		if {[string match -nocase $pattern $qvalue]} {lappend ret $qnum}
	}
	return $ret
}

