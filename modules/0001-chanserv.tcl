source chanserv.conf
sendUid $sock $cs(nick) $cs(ident) $cs(host) $cs(host) 77 "Channels Server"
bind msg 77 "register" regchan
bind msg 77 "adduser" adduserchan
bind msg 77 "users" lsuchan
bind msg 77 "lsu" lsuchan
#bind msg 77 "deluser" deluserchan
bind msg 77 "up" upchan
bind pub "-" "@up" upchanfant
bind pub "-" "@rand" randfant
bind pub "-" "@request" requestbot
bind msg 77 "down" downchan
bind msg 77 "hello" regnick
bind msg 77 "chpass" chpassnick
bind msg 77 "login" idnick
bind msg 77 "help" chanhelp
bind mode "-" "+" checkop
bind mode "-" "-" checkdeop
bind create "-" "-" checkcreate

proc randfant {cname msg} {
	set from [lindex $msg 0 0]
	set froni [tnda get "nick/$from"]
	if {![string is integer [lindex $msg 1 0]] ||![string is integer [lindex $msg 1 1]]} {return}
	if {(""==[lindex $msg 1 0]) || (""==[lindex $msg 1 1])} {return}
	if {[lindex $msg 1 0] == [lindex $msg 1 1]} {privmsg $::sock 77 $cname "\002$froni:\002 Your request would have caused a divide by zero and was not processed.";return}
	privmsg $::sock 77 $cname "\002$froni:\002 Your die rolled [rand [lindex $msg 1 0] [lindex $msg 1 1]]"
}

proc lsuchan {from msg} {
	set cname [lindex $msg 0 0]
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {[string length [nda get "regchan/$ndacname"]] == 0} {
		notice $::sock 77 $from "You fail at life."
		notice $::sock 77 $from "Channel does not exist."
		return
	}
	set xses [nda get "regchan/$ndacname/levels"]
	notice $::sock 77 $from "Access | Username"
	notice $::sock 77 $from "-------+------------"
	foreach {nick lev} $xses {
		if {$lev == 0} {continue}
		# Case above? User not actually on access list
		set nl [format "%3d" $lev]
		notice $::sock 77 $from "  $nl  | $nick"
	}
	notice $::sock 77 $from "-------+------------"
	notice $::sock 77 $from "       | End of access list"
}

proc upchanfant {cname msg} {
	set from [lindex $msg 0 0]
	if {""==[tnda get "login/$from"]} {notice $::sock 77 $from "You fail at life.";return}
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {1>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$from"]]"]} {
		privmsg $::sock 77 $cname "You fail at life."
		privmsg $::sock 77 $cname "Channel not registered to you."
		return
	}
	set lev [nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$from"]]"]
	set sm "+"
	set st ""
	if {$lev >= 1} {set sm "v"}
	if {$lev >= 150} {set sm "h"}
	if {$lev >= 200} {set sm "o"}
	putmode $::sock 77 $cname $sm $from [tnda get "channels/$ndacname/ts"]
}

proc requestbot {cname msg} {
	set from [lindex $msg 0 0]
	set bot [lindex $msg 1 0]
	if {""==[tnda get "login/$from"]} {notice $::sock 77 $from "You fail at life.";return}
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {150>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$from"]]"]} {
		privmsg $::sock 77 $cname "You fail at life."
		privmsg $::sock 77 $cname "You must be at least halfop to request $bot."
		return
	}
	callbind request [string tolower $bot] "-" $cname
}

foreach {chan _} [nda get "regchan"] {
	putjoin $::sock 77 [::base64::decode [string map {[ /} $chan]] [nda get "regchan/$chan/ts"]
	tnda set "channels/$chan/ts" [nda get "regchan/$chan/ts"]
	putmode $::sock 77 [::base64::decode [string map {[ /} $chan]] "+nt" "" [nda get "regchan/$chan/ts"]
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
	notice $::sock 77 $from "adduser <channel> <user name> <add level> - Add a username to the channel access list."
	notice $::sock 77 $from "up <channel> - (@up) Ops you if you have level on the channel for this username."
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
	callbind "reg" "-" "-" $cname [tnda get "channels/$ndacname/ts"]
}

proc adduserchan {from msg} {
	if {""==[tnda get "login/$from"]} {notice $::sock 77 $from "You fail at life.";return}
	set cname [lindex $msg 0 0]
	set adduser [lindex $msg 0 1]
	set addlevel [lindex $msg 0 2]
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {![string is integer $addlevel]} {return}
	if {$addlevel > [nda get "regchan/$ndacname/levels/[tnda get "login/$from"]"]} {notice $::sock 77 $from "You can't do that; you're not the channel's Dave";return}
	if {[nda get "regchan/$ndacname/levels/$adduser"] > [nda get "regchan/$ndacname/levels/[tnda get "login/$from"]"]} {notice $::sock 77 $from "You can't do that; the person you're changing the level of is more like Dave than you.";return}
	if {$adduser == [tnda get "login/$from"]} {notice $::sock 77 $from "You can't change your own level, even if you're downgrading. Sorreh :/";return}
	notice $::sock 77 $from "Guess what? :) User added."
	nda set "regchan/$ndacname/levels/[string tolower $adduser]" $addlevel
}

proc upchan {from msg} {
	puts stdout [nda get regchan]
	if {""==[tnda get "login/$from"]} {notice $::sock 77 $from "You fail at life.";return}
	set cname [lindex $msg 0 0]
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {1>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$from"]]"]} {
		notice $::sock 77 $from "You fail at life."
		notice $::sock 77 $from "Channel not registered to you."
		return
	}
	set lev [nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$from"]]"]
	set sm "+"
	set st ""
	if {$lev >= 1} {set sm "v"}
	if {$lev >= 150} {set sm "h"}
	if {$lev >= 200} {set sm "o"}
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
	callbind evnt "-" "login" $from $uname
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
		callbind evnt "-" "login" $from $uname
	} {
		notice $::sock 77 $from "You cannot log in as $uname. You have the wrong password."
	}
}
