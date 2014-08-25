$::maintype sendUid $sock $cs(nick) $cs(ident) $cs(host) $cs(host) 77 "Channels Server"
bind $::sock msg 77 "register" regchan
bind $::sock msg 77 "adduser" adduserchan
bind $::sock msg 77 "users" lsuchan
bind $::sock msg 77 "lsu" lsuchan
bind $::sock msg 77 "convertop" convertop
#bind $::sock msg 77 "deluser" deluserchan
bind $::sock msg 77 "up" upchan
bind $::sock pub "-" "@up" upchanfant
bind $::sock pub "-" "@rand" randfant
bind $::sock pub "-" "@request" requestbot
bind $::sock msg 77 "down" downchan
bind $::sock msg 77 "hello" regnick
bind $::sock msg 77 "chpass" chpassnick
bind $::sock msg 77 "login" idnick
bind $::sock msg 77 "help" chanhelp
bind $::sock msg 77 "topic" chantopic
bind $::sock msg 77 "cookie" authin
bind $::sock msg 77 "cauth" cookieauthin
bind $::sock mode "-" "+" checkop
bind $::sock mode "-" "-" checkdeop
bind $::sock topic "-" "-" checktopic
bind $::sock create "-" "-" checkcreate

proc checktopic {chan topic} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	if {[channel get $chan topiclock]} {$::maintype topic $::sock 77 "$chan" "[nda get "regchan/$ndacname/topic"]"}
}

proc chantopic {from msg} {
	set cname [lindex $msg 0 0]
	set topic [join [lrange [lindex $msg 0] 1 end] " "]
	if {""==[tnda get "login/$::netname($::sock)/$from"]} {$::maintype notice $::sock 77 $from "You fail at life.";return}
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {150>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$::netname($::sock)/$from"]]"] && ![matchattr [tnda get "login/$::netname($::sock)/$from"] lmno|lmno $cname]} {
		$::maintype privmsg $::sock 77 $cname "You must be at least halfop to change the stored channel topic."
		return
	}
	nda set "regchan/$ndacname/topic" "$topic"
	$::maintype topic $::sock 77 "$cname" "$topic"
	$::maintype privmsg $::sock 77 "$cname" "[tnda get "nick/$::netname($::sock)/$from"] ([tnda get "login/$::netname($::sock)/$from"]) changed topic."
}

proc authin {from msg} {
	set uname [lindex $msg 0 0]
	if {[string first "/" $uname] != -1} {return}
	$::maintype notice $::sock 77 $from "CHALLENGE [set cookie [b64e [rand 1000000000 9999999999]]] SHA1"
	tnda set "cookieauth/$from/cookie" $cookie
	tnda set "cookieauth/$from/name" "$uname"
}

proc cookieauthin {from msg} {
	set uname [lindex $msg 0 0]
	set response [lindex $msg 0 1]
	if {[string first "/" $uname] != -1} {return}
	if {$response == ""} {return}
	set checkresp "[tnda get "cookieauth/$from/name"]:[nda get "usernames/[string tolower $uname]/password"]:[tnda get "cookieauth/$from/cookie"]"
	set isresp [pwhash "$checkresp"]
	puts stdout "$response $isresp $checkresp"
	if {$response == $isresp} {
		$::maintype notice $::sock 77 $from "You have successfully logged in as $uname."
		$::maintype setacct $::sock $from $uname
		callbind $::sock evnt "-" "login" $from $uname
	} {
		$::maintype notice $::sock 77 $from "You used the wrong password; try again."
	}
}

proc randfant {cname msg} {
	set from [lindex $msg 0 0]
	set froni [tnda get "nick/$::netname($::sock)/$from"]
	if {![string is integer [lindex $msg 1 0]] ||![string is integer [lindex $msg 1 1]]} {return}
	if {(""==[lindex $msg 1 0]) || (""==[lindex $msg 1 1])} {return}
	if {[lindex $msg 1 0] == [lindex $msg 1 1]} {$::maintype privmsg $::sock 77 $cname "\002$froni:\002 Your request would have caused a divide by zero and was not processed.";return}
	$::maintype privmsg $::sock 77 $cname "\002$froni:\002 Your die rolled [rand [lindex $msg 1 0] [lindex $msg 1 1]]"
}

proc lsuchan {from msg} {
	set cname [lindex $msg 0 0]
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {[string length [nda get "regchan/$ndacname"]] == 0} {
		$::maintype notice $::sock 77 $from "You fail at life."
		$::maintype notice $::sock 77 $from "Channel does not exist."
		return
	}
	set xses [nda get "regchan/$ndacname/levels"]
	$::maintype notice $::sock 77 $from "Access | Flags  | Username"
	$::maintype notice $::sock 77 $from "-------+------------------"
	foreach {nick lev} $xses {
		if {$lev == 0} {continue}
		# Case above? User not actually on access list
		set nl [format "%3d" $lev]
		set repeats [string repeat " " [expr {6-[string length [nda get "eggcompat/attrs/$ndacname/$nick"]]}]]
	$::maintype notice $::sock 77 $from "  $nl  | $repeats[string range [nda get "eggcompat/attrs/$ndacname/$nick"] 0 5] | $nick"
	}
	$::maintype notice $::sock 77 $from "-------+------------------"
	$::maintype notice $::sock 77 $from "       | End of access list"
}

proc upchanfant {cname msg} {
	set from [lindex $msg 0 0]
	if {""==[tnda get "login/$::netname($::sock)/$from"]} {$::maintype notice $::sock 77 $from "You fail at life.";return}
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {(1>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$::netname($::sock)/$from"]]"]) && ![matchattr [tnda get "login/$::netname($::sock)/$from"] aolvmn|olvmn $cname]} {
		$::maintype privmsg $::sock 77 $cname "You fail at life."
		$::maintype privmsg $::sock 77 $cname "Channel not registered to you."
		return
	}
	set lev [nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$::netname($::sock)/$from"]]"]
	set sm "+"
	set st ""
	if {""!=[nda get "eggcompat/attrs/$ndacname/[tnda get "login/$::netname($::sock)/$from"]"]} {
		if {[matchattr [tnda get "login/$::netname($::sock)/$from"] |v $cname]} {set sm v}
		if {[matchattr [tnda get "login/$::netname($::sock)/$from"] |l $cname]} {set sm [tnda get "pfx/halfop"]}
		if {[matchattr [tnda get "login/$::netname($::sock)/$from"] |o $cname]} {set sm o}
		if {[matchattr [tnda get "login/$::netname($::sock)/$from"] |m $cname]} {set sm [tnda get "pfx/protect"]}
		if {[matchattr [tnda get "login/$::netname($::sock)/$from"] |n $cname]} {set sm [tnda get "pfx/owner"]}
	} {
		if {$lev >= 1} {set sm "v"; append st "v"}
		if {$lev >= 150} {set sm "h"; append st "l"}
		if {$lev >= 200} {set sm "o"; append st "o"}
		if {$lev >= 300} {append st "m"}
		if {$lev >= 500} {append st "n"}
		chattr [tnda get "login/$::netname($::sock)/$from"] +$st $cname
	}
	$::maintype putmode $::sock 77 $cname +$sm $from [tnda get "channels/$::netname($::sock)/$ndacname/ts"]
}

proc convertop {from msg} {
	if {""==[tnda get "login/$::netname($::sock)/$from"]} {$::maintype notice $::sock 77 $from "You fail at life.";return}
	set cname [lindex $msg 0 0]
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {500>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$::netname($::sock)/$from"]]"]} {
		$::maintype notice $::sock 77 $from "You fail at life."
		$::maintype notice $::sock 77 $from "You must be the founder to request an oplevel-to-flags conversion."
		return
	}
	foreach {login lev} [nda get "regchan/$ndacname/levels"] {
		set st ""
		if {$lev >= 1} {append st "v"}
		if {$lev >= 150} {append st "l"}
		if {$lev >= 200} {append st "o"}
		if {$lev >= 300} {append st "m"}
		if {$lev >= 500} {append st "n"}
		chattr $login +$st $cname
	}
	$::maintype notice $::sock 77 $from "Converted all access levels to flags."
	lsuchan $from $msg
}

proc requestbot {cname msg} {
	set from [lindex $msg 0 0]
	set bot [lindex $msg 1 0]
	if {""==[tnda get "login/$::netname($::sock)/$from"]} {$::maintype notice $::sock 77 $from "You fail at life.";return}
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {150>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$::netname($::sock)/$from"]]"] && ![matchattr [tnda get "login/$::netname($::sock)/$from"] lmno|lmno $cname]} {
		$::maintype privmsg $::sock 77 $cname "You fail at life."
		$::maintype privmsg $::sock 77 $cname "You must be at least halfop to request $bot."
		return
	}
	callbind $::sock request [string tolower $bot] "-" $cname
}

foreach {chan _} [nda get "regchan"] {
	$::maintype putjoin $::sock 77 [::base64::decode [string map {[ /} $chan]] [nda get "regchan/$chan/ts"]
	tnda set "channels/$chan/ts" [nda get "regchan/$chan/$::netname($::sock)/ts"]
	$::maintype putmode $::sock 77 [::base64::decode [string map {[ /} $chan]] "+nt" "" [nda get "regchan/$chan/ts"]
	if {[channel get [::base64::decode [string map {[ /} $chan]] topiclock]} {$::maintype topic $::sock 77 [::base64::decode [string map {[ /} $chan]] [nda get "regchan/$chan/topic"]}
}

proc checkop {mc ftp} {
	set f [lindex $ftp 0 0]
	set t [lindex $ftp 0 1]
	set p [lindex $ftp 0 2]
	if {"o"!=$mc} {return}
	set chan [string map {/ [} [::base64::encode [string tolower $t]]]
	tnda set "channels/$chan/modes/$p" "[tnda get "channels/$chan/modes/$::netname($::sock)/$::netname($::sock)/$p"]o"
}

proc checkcreate {mc ftp} {
	set chan [string map {/ [} [::base64::encode [string tolower $mc]]]
	tnda set "channels/$chan/modes/$::netname($::sock)/$ftp" "o"
	puts stdout "channels/$chan/modes/$ftp"
}

proc checkdeop {mc ftp} {
	set f [lindex $ftp 0 0]
	set t [lindex $ftp 0 1]
	set p [lindex $ftp 0 2]
	if {"o"!=$mc} {return}
	set chan [string map {/ [} [::base64::encode [string tolower $t]]]
	tnda set "channels/$chan/modes/$p" [string map {o ""} [tnda get "channels/$chan/modes/$::netname($::sock)/$::netname($::sock)/$p"]]
}

proc chanhelp {from msg} {
	set fp [open ./chanserv.help r]
	set data [split [read $fp] "\r\n"]
	close $fp
	foreach {line} $data {
		$::maintype notice $::sock 77 $from "$line"
	}
}

proc regchan {from msg} {
	if {""==[tnda get "login/$::netname($::sock)/$from"]} {$::maintype notice $::sock 77 $from "You fail at life.";return}
	set cname [lindex $msg 0 0]
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {[string length [nda get "regchan/$ndacname"]] != 0} {
		$::maintype notice $::sock 77 $from "You fail at life."
		$::maintype notice $::sock 77 $from "Channel already exists."
		return
	}
	if {-1==[string first "o" [tnda get "channels/$::netname($::sock)/$ndacname/modes/$from"]]} {
		$::maintype notice $::sock 77 $from "You fail at life."
		$::maintype notice $::sock 77 $from "You are not an operator."
		return
	}
	$::maintype notice $::sock 77 $from "Guess what? :)"
	nda set "regchan/$ndacname/levels/[tnda get "login/$::netname($::sock)/$from"]" 500
	nda set "regchan/$ndacname/ts" [tnda get "channels/$::netname($::sock)/$ndacname/ts"]
	$::maintype putjoin $::sock 77 $cname [tnda get "channels/$::netname($::sock)/$ndacname/ts"]
	chattr [tnda get "login/$::netname($::sock)/$from"] +mno $cname
	callbind $::sock "reg" "-" "-" $cname [tnda get "channels/$::netname($::sock)/$ndacname/ts"]
}

proc adduserchan {from msg} {
	if {""==[tnda get "login/$::netname($::sock)/$from"]} {$::maintype notice $::sock 77 $from "You fail at life.";return}
	set cname [lindex $msg 0 0]
	set adduser [lindex $msg 0 1]
	set addlevel [lindex $msg 0 2]
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {![string is integer $addlevel]} {return}
	if {$addlevel > [nda get "regchan/$ndacname/levels/[tnda get "login/$::netname($::sock)/$from"]"]} {$::maintype notice $::sock 77 $from "You can't do that; you're not the channel's Dave";return}
	if {[nda get "regchan/$ndacname/levels/$adduser"] > [nda get "regchan/$ndacname/levels/[tnda get "login/$::netname($::sock)/$from"]"]} {$::maintype notice $::sock 77 $from "You can't do that; the person you're changing the level of is more like Dave than you.";return}
	if {$adduser == [tnda get "login/$::netname($::sock)/$from"]} {$::maintype notice $::sock 77 $from "You can't change your own level, even if you're downgrading. Sorreh :/$::netname($::sock)/";return}
	$::maintype notice $::sock 77 $from "Guess what? :) User added."
	nda set "regchan/$ndacname/levels/[string tolower $adduser]" $addlevel
}

proc upchan {from msg} {
	puts stdout [nda get regchan]
	if {""==[tnda get "login/$::netname($::sock)/$from"]} {$::maintype notice $::sock 77 $from "You fail at life.";return}
	set cname [lindex $msg 0 0]
	set ndacname [string map {/ [} [::base64::encode [string tolower $cname]]]
	if {1>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$::netname($::sock)/$from"]]"] && ![matchattr [tnda get "login/$::netname($::sock)/$from"] aolvmn|olvmn $cname]} {
		$::maintype notice $::sock 77 $from "You fail at life."
		$::maintype notice $::sock 77 $from "Channel not registered to you."
		return
	}
	set lev [nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$::netname($::sock)/$from"]]"]
	set sm "+"
	set st ""
	if {""!=[nda get "eggcompat/attrs/$ndacname/[tnda get "login/$::netname($::sock)/$from"]"]} {
		if {[matchattr [tnda get "login/$::netname($::sock)/$from"] |v $cname]} {set sm v}
		if {[matchattr [tnda get "login/$::netname($::sock)/$from"] |l $cname]} {set sm [tnda get "pfx/halfop"]}
		if {[matchattr [tnda get "login/$::netname($::sock)/$from"] |o $cname]} {set sm o}
		if {[matchattr [tnda get "login/$::netname($::sock)/$from"] |m $cname]} {set sm [tnda get "pfx/protect"]}
		if {[matchattr [tnda get "login/$::netname($::sock)/$from"] |n $cname]} {set sm [tnda get "pfx/owner"]}
	} {
		if {$lev >= 1} {set sm "v"; append st "v"}
		if {$lev >= 150} {set sm "h"; append st "l"}
		if {$lev >= 200} {set sm "o"; append st "o"}
		if {$lev >= 300} {append st "m"}
		if {$lev >= 500} {append st "n"}
		chattr [tnda get "login/$::netname($::sock)/$from"] +$st $cname
	}
	$::maintype putmode $::sock 77 $cname +$sm $from [tnda get "channels/$::netname($::sock)/$ndacname/ts"]
}

proc regnick {from msg} {
	set uname [lindex $msg 0 0]
	if {[string first "/" $uname] != -1} {return}
	set pw [lindex $msg 0 1]
	if {""!=[nda get "usernames/[string tolower $uname]"]} {
		$::maintype notice $::sock 77 $from "You fail at life."
		$::maintype notice $::sock 77 $from "Account already exists; try LOGIN"
		return
	}
	nda set "usernames/[string tolower $uname]/password" [pwhash $pw]
	$::maintype setacct $::sock $from $uname
	callbind $::sock evnt "-" "login" $from $uname
}

proc chpassnick {from msg} {
	set uname [lindex $msg 0 0]
	if {[string first "/" $uname] != -1} {return}
	set pw [lindex $msg 0 1]
	set newpw [lindex $msg 0 2]
	set checkpw [split [nda get "usernames/[string tolower $uname]/password"] "/"]
	set ispw [pwhash $pw]

	if {$ispw != [nda get "usernames/[string tolower $uname]/password"]} {
		$::maintype notice $::sock 77 $from "You fail at life."
		$::maintype notice $::sock 77 $from "Wrong pass."
		return
	}
	nda set "usernames/[string tolower $uname]/password" [pwhash $newpw]
	$::maintype notice $::sock 77 $from "Password changed."
}

proc idnick {from msg} {
	set uname [lindex $msg 0 0]
	if {[string first "/" $uname] != -1} {return}
	set pw [lindex $msg 0 1]
	set checkpw [split [nda get "usernames/[string tolower $uname]/password"] "/"]
	set ispw [pwhash $pw]
	if {$ispw == [nda get "usernames/[string tolower $uname]/password"]} {
		$::maintype notice $::sock 77 $from "You have successfully logged in as $uname."
		$::maintype setacct $::sock $from $uname
		callbind $::sock evnt "-" "login" $from $uname
	} {
		$::maintype notice $::sock 77 $from "You cannot log in as $uname. You have the wrong password."
	}
}
