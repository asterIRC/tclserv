source chanserv.conf
sendUid $sock $cs(nick) $cs(ident) $cs(host) $cs(host) 77 "Channels Server"
bind msg 77 "register" regchan
bind msg 77 "adduser" adduserchan
#bind msg 77 "deluser" deluserchan
bind msg 77 "up" upchan
bind msg 77 "down" downchan
bind msg 77 "hello" regnick
bind msg 77 "chpass" chpassnick
bind msg 77 "login" idnick
bind msg 77 "help" chanhelp
bind mode "-" "+" checkop
bind mode "-" "-" checkdeop
bind create "-" "-" checkcreate

foreach {chan _} [nda get "regchan"] {
	putjoin $::sock 77 [::base64::decode [string map {[ /} $chan]] [nda get "regchan/$chan/ts"]
	tnda set "channels/$chan/ts" [tnda get "channels/$chan/ts"]
}

proc checkop {mc ftp} {
	set f [lindex $ftp 0 0]
	set t [lindex $ftp 0 1]
	set p [lindex $ftp 0 2]
	if {"o"!=$mc} {return}
	set chan [string map {/ [} [::base64::encode [string tolower $t]]]
	tnda set "channels/$chan/modes/$p" "[tnda get "channels/$chan/modes/$p"]o"
}

proc checkcreate {mc ftp} {
	set chan [string map {/ [} [::base64::encode [string tolower $mc]]]
	tnda set "channels/$chan/modes/$ftp" "o"
	puts stdout "channels/$chan/modes/$ftp"
}

proc checkdeop {mc ftp} {
	set f [lindex $ftp 0 0]
	set t [lindex $ftp 0 1]
	set p [lindex $ftp 0 2]
	if {"o"!=$mc} {return}
	set chan [string map {/ [} [::base64::encode [string tolower $t]]]
	tnda set "channels/$chan/modes/$p" [string map {o ""} [tnda get "channels/$chan/modes/$p"]]
}

proc chanhelp {from msg} {
	notice $::sock 77 $from "                             --- ChanServ Help ---"
	notice $::sock 77 $from "ChanServ provides channel auto op and basic protection (depending on loaded scripts)"
	notice $::sock 77 $from "to registered channels."
	notice $::sock 77 $from "                           -!- Commands available -!-"
	notice $::sock 77 $from "register <channel> - Register a channel to your username. "
	notice $::sock 77 $from "up <channel> - Ops you if you have level on the channel for this username."
	notice $::sock 77 $from "down <channel> - Removes all channel user modes affecting your nick."
	notice $::sock 77 $from "hello <username> <password> - Register a username."
	notice $::sock 77 $from "login <username> <password> - Log in to a username."
}

proc regchan {from msg} {
	if {""==[tnda get "login/$from"]} {notice $::sock 77 $from "You fail at life.";return}
	set cname [lindex $msg 0 0]
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {[string length [nda get "regchan/$ndacname"]] != 0} {
		notice $::sock 77 $from "You fail at life."
		notice $::sock 77 $from "Channel already exists."
		return
	}
	if {-1==[string first "o" [tnda get "channels/$ndacname/modes/$from"]]} {
		notice $::sock 77 $from "You fail at life."
		notice $::sock 77 $from "You are not an operator."
		return
	}
	notice $::sock 77 $from "Guess what? :)"
	nda set "regchan/$ndacname/levels/[tnda get "login/$from"]" 500
	nda set "regchan/$ndacname/ts" [tnda get "channels/$ndacname/ts"]
	putjoin $::sock 77 $cname [tnda get "channels/$ndacname/ts"]
}

proc adduserchan {from msg} {
	if {""==[tnda get "login/$from"]} {notice $::sock 77 $from "You fail at life.";return}
	set cname [lindex $msg 0 0]
	set adduser [lindex $msg 0 1]
	set addlevel [lindex $msg 0 2]
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {![string is -integer $addlevel]} {return}
	if {$addlevel > [nda get "regchan/$ndacname/levels/[tnda get "login/$from"]"]} {notice $::sock 77 $from "You can't do that; you're not the channel's Dave";return}
	if {[nda get "regchan/$ndacname/levels/$adduser"] > [nda get "regchan/$ndacname/levels/[tnda get "login/$from"]"]} {notice $::sock 77 $from "You can't do that; the person you're changing the level of is more like Dave than you.";return}
	if {$adduser == [tnda get "login/$from"]} {notice $::sock 77 $from "You can't change your own level, even if you're downgrading. Sorreh :/";return}
	notice $::sock 77 $from "Guess what? :) User added."
	nda set "regchan/$ndacname/levels/$adduser" $addlevel
}

proc upchan {from msg} {
	puts stdout [nda get regchan]
	if {""==[tnda get "login/$from"]} {notice $::sock 77 $from "You fail at life.";return}
	set cname [lindex $msg 0 0]
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {1>[nda get "regchan/$ndacname/levels/[tnda get "login/$from"]"]} {
		notice $::sock 77 $from "You fail at life."
		notice $::sock 77 $from "Channel not registered to you."
		return
	}
	set lev [nda get "regchan/$ndacname/levels/[tnda get "login/$from"]"]
	set sm "+"
	set st ""
	if {$lev > 1} {set sm "v"}
	if {$lev > 150} {set sm "h"}
	if {$lev > 200} {set sm "o"}
	putmode $::sock 77 $cname $sm $from [tnda get "channels/$ndacname/ts"]
}

proc regnick {from msg} {
	set uname [lindex $msg 0 0]
	if {[string first "/" $uname] != -1} {return}
	set pw [lindex $msg 0 1]
	if {""!=[nda get "usernames/[string tolower $uname]"]} {
		notice $::sock 77 $from "You fail at life."
		notice $::sock 77 $from "Account already exists; try LOGIN"
		return
	}
	nda set "usernames/[string tolower $uname]/password" [pwhash $pw]
	setacct $::sock $from $uname
}

proc chpassnick {from msg} {
	set uname [lindex $msg 0 0]
	if {[string first "/" $uname] != -1} {return}
	set pw [lindex $msg 0 1]
	set newpw [lindex $msg 0 2]
	set checkpw [split [nda get "usernames/[string tolower $uname]/password"] "/"]
	set ispw [pwhash $pw]

	if {$ispw != [nda get "usernames/[string tolower $uname]/password"]} {
		notice $::sock 77 $from "You fail at life."
		notice $::sock 77 $from "Wrong pass."
		return
	}
	nda set "usernames/[string tolower $uname]/password" [pwhash $newpw]
	notice $::sock 77 $from "Password changed."
}

proc idnick {from msg} {
	set uname [lindex $msg 0 0]
	if {[string first "/" $uname] != -1} {return}
	set pw [lindex $msg 0 1]
	set checkpw [split [nda get "usernames/[string tolower $uname]/password"] "/"]
	set ispw [pwhash $pw]
	if {$ispw == [nda get "usernames/[string tolower $uname]/password"]} {
		notice $::sock 77 $from "You have successfully logged in as $uname."
		setacct $::sock $from $uname
	} {
		notice $::sock 77 $from "You cannot log in as $uname. You have the wrong password."
	}
}
