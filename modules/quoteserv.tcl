blocktnd quoteserv
blocktnd qshelp

source quoteserv.help

bind - evnt - confloaded quoteserv.connect

proc quoteserv.connect {arg} {
	puts stdout [format "there are %s quoteserv blocks" [set blocks [tnda get "openconf/[ndcenc quoteserv]/blocks"]]]
	for {set i 1} {$i < ($blocks + 1)} {incr i} {
		after 1000 [list quoteserv.oneintro [tnda get [format "openconf/%s/hdr%s" [ndcenc quoteserv] $i]] [tnda get [format "openconf/%s/n%s" [ndcenc quoteserv] $i]]]
	}
}

proc quoteserv.find6sid {n s {hunting 0}} {
	# we're trying to get the sid of the server named $s
	# if hunting, we're looking for the first splat match
	set servs [tnda get "servers/$n"]
	foreach {.k dv} $servs {
		set k [string toupper [ndadec ${.k}]]
		# name description uplink sid - we only need two
		dictassign $dv name sname
		if {$hunting} {
			if {[string match [string tolower $s] [string tolower $sname]] == 1} {return $k}
		} {
			if {[string tolower $s] == [string tolower $sname]} {return $k}
		}
	}
	return ""
}

proc quoteserv.oneintro {headline block} {
	set net [lindex $headline 0]
	set nsock $::sock($net)
	setctx $net
	dictassign $block logchan logchan nick nick ident ident host host modes modes realname realname operflags rehashprivs idcommand nspass \
		nickserv nickserv nsserv nsserv
	tnda set "quoteserv/[curctx net]/operflags" $rehashprivs
	tnda set "quoteserv/[curctx net]/logchan" $logchan
	#tnda set "quoteserv/[curctx net]/nspass" $nspass
	setctx $net
	$::nettype($net) sendUid $nsock $nick $ident $host $host [set ourid [$::nettype($net) getfreeuid $net]] [expr {($realname == "") ? "* Debug Service *" : $realname}] $modes
	tnda set "quoteserv/[curctx net]/ourid" $ourid
#	bind $nsock pub - ".metadata" [list quoteserv.pmetadata $net]
#	bind $nsock pub - ".rehash" [list quoteserv.crehash $net]
	if {[string length $nspass] != 0 && [string length $nickserv] != 0} {
		# only works if nettype is ts6!
		if {[string first [quoteserv.find6sid $net $nsserv] [$::nettype($net) nick2uid $net $nickserv]] == 0} {
			$::nettype($net) privmsg $nsock $ourid $nickserv $nspass
		} {
			$::nettype($net) privmsg $nsock $ourid $logchan [gettext quoteserv.impostornickserv $nickserv [$::nettype($net) nick2uid $n $nickserv] $nsserv [quoteserv.find6sid $net $nsserv]]
		}
	}
	after 650 $::nettype($net) putjoin $nsock $ourid $logchan
	after 700 [list $::nettype($net) putmode $nsock $ourid $logchan "+ao" [format "%s %s" [$::nettype($net) intclient2uid $net $ourid] [$::nettype($net) intclient2uid $net $ourid]]]
#	bind $nsock msg [tnda get "quoteserv/[curctx net]/ourid"] "metadata" [list quoteserv.metadata $net]
#	bind $nsock msg [tnda get "quoteserv/[curctx net]/ourid"] "rehash" [list quoteserv.rehash $net]
#	bind $nsock pub - "gettext" [list quoteserv.gettext $net]
#	puts stdout "bind $nsock msg [tnda get "quoteserv/[curctx net]/ourid"] metadata [list quoteserv.metdata $net]"
	puts stdout [format "Connected for %s: %s %s %s" $net $nick $ident $host]
	bind $nsock pub - "!quote" [list quoteservdo $net]
	bind $nsock evnt - privmsg [list qs.pmdo $net]
	puts stdout $::nd
	foreach {chan is} [nda get "quoteserv/[curctx net]/regchan"] {
		puts stdout "to join $chan on [curctx]"
		if {1!=$is} {continue}
		quoteservjoin [ndadec $chan] 0
#		[curctx proto] putjoin [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] [::base64::decode [string map {[ /} $chan]] [nda get "regchan/$chan/ts"]
#		tnda set "channels/$chan/ts" [nda get "regchan/$chan/$::netname([curctx sock])/ts"]
	}
}

proc qs.pmdo {n i t m} {
	set whoarewe [tnda get "intclient/$n/$t"]
	if {$whoarewe != [tnda get "quoteserv/[curctx net]/ourid"]} {return}
	quoteservdo $n 0 $i $m
}

proc quoteservjoin {chan {setting 1}} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	puts stdout "to join $chan on [curctx]"
	[curctx proto] putjoin [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan
	[curctx proto] putmode [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan "+ao" \
		[format "%s %s" [[curctx proto] intclient2uid [curctx net] [tnda get "quoteserv/[curctx net]/ourid"]]\
		 [[curctx proto] intclient2uid [curctx net] [tnda get "quoteserv/[curctx net]/ourid"]]]
	if {$setting} {nda set "quoteserv/[curctx net]/regchan/$ndacname" 1}
}

proc quoteservpart {chan {who "the script"} {msg isunused}} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	[curctx proto] putpart [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.left $who]
	nda set "quoteserv/[curctx net]/regchan/$ndacname" 0
	nda unset "quoteserv/[curctx net]/regchan/$ndacname"
}

proc quoteservenabled {chan} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	if {[nda get "quoteserv/[curctx net]/regchan/$ndacname"] == 1} {return 1} {return 0}
}


if 0 {
here's the program with the gettext

quoteserv.impostornickserv ^C14>^C5>^C4>^C NickServ specified in config file (nick %s, UID %s, intended server %s, whose SID is "%s" - check links if blank) i$
quoteserv.results ^C14>^C3>^C9>^C Quotes: Found results numbered %s
quoteserv.noresults ^C14>^C5>^C4>^C Quotes: Found NO results for your search.
quoteserv.qheader ^C14>^C2>^C12>^C Quote number %s, by %s:
quoteserv.quote ^C14>^C2>^C12>^C %s
quoteserv.added ^C14>^C3>^C9>^C Added quote number %s to database.
quoteserv.usevalidint ^C14>^C5>^C4>^C Please use a valid integer, without the #.
quoteserv.enopriv ^C14>^C5>^C4>^C You do not have the required privileges to execute the command queued (requires flags +%s in ChanServ, or oper permissions %$
quoteserv.removed ^C14>^C3>^C9>^C Removed quote number %s (by %s) from database.
quoteserv.removedcontents ^C14>^C2>^C12>^C Removed quote was: %s
}

proc quoteservdo {n chan from m} {
	setctx $n
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	if {![quoteservenabled $chan] && $chan != 0} {return}
	# Q isn't in channel, no need to check quotes
	set subcmd [lindex [split $m " "] 0]
	set para [lrange [split $m " "] 1 end]
	set opara [lrange [split $m " "] 1 end]
	switch -nocase -glob -- $subcmd {
		"se*" {
			if {$chan == 0} {
				set chan $from
				set ndacname [string map {/ [} [::base64::encode [string tolower [lindex $opara 0]]]]
				set para [lrange $para 1 end]
				if {![quoteservenabled [lindex $opara 0]]} {return}
			}
			set ptn [format "*%s*" [join $para " "]]
			set qts [quotesearch $chan $ptn]
			if {[llength $qts] != 0} {
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.results #[join $qts ", #"]]
			} {
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.noresults]
			}
		}
		"vi*1st*ma*" {
			if {$chan == 0} {
				set chan $from
				set ndacname [string map {/ [} [::base64::encode [string tolower [lindex $opara 0]]]]
				set para [lrange $para 1 end]
				if {![quoteservenabled [lindex $opara 0]]} {return}
			}
			set ptn [format "*%s*" [join $para " "]]
			set qts [quotesearch $chan $ptn]
			if {[llength $qts]} {
				set qtn [lindex $qts 0]
				set qt [nda get "quoteserv/[curctx net]/quotes/$ndacname/q$qtn"]
				set qb [nda get "quoteserv/[curctx net]/quotes/$ndacname/u$qtn"]
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.qheader $qtn $qb]
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.quote $qt]
			} {
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.noresults]
			}
		}
		"ad*" {
			if {$chan == 0} {
				set chan $from
				set ndacname [string map {/ [} [::base64::encode [string tolower [lindex $opara 0]]]]
				set para [lrange $para 1 end]
				if {![quoteservenabled [lindex $opara 0]]} {return}
			}
			set qt [join $para " "]
			set qtn [expr {([llength [nda get "quoteserv/[curctx net]/quotes/$ndacname"]]/6)+1}]
			nda set "quoteserv/[curctx net]/quotes/$ndacname/q$qtn" $qt
			nda set "quoteserv/[curctx net]/quotes/$ndacname/u$qtn" [format "(%s) %s!%s@%s" [tnda get "login/[curctx net]/$from"] [[curctx proto] uid2nick [curctx net] $from] [[curctx proto] uid2ident [curctx net] $from] [[curctx proto] uid2host [curctx net] $from]]
			nda set "quoteserv/[curctx net]/quotes/$ndacname/a$qtn" [string tolower [tnda get "login/[curctx net]/$from"]]
			[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.added $qtn]
		}
		"gad*" {
			set qt [join $para " "]
			set qtn [expr {([llength [nda get "quoteserv/[curctx net]/quotes/$ndacname"]]/6)+3}]
			if {![operHasPrivilege [curctx net] $from [tnda get "quoteserv/[curctx net]/operflags"]]} {
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.enopriv [tnda get "quoteserv/[curctx net]/operflags"]]
			} {
				nda set "quoteserv/[curctx net]/gquotes/q$qtn" $qt
				nda set "quoteserv/[curctx net]/gquotes/u$qtn" [format "(%s) %s!%s@%s" [tnda get "login/[curctx net]/$from"] [[curctx proto] uid2nick [curctx net] $from] [[curctx proto] uid2ident [curctx net] $from] [[curctx proto] uid2host [curctx net] $from]]
				nda set "quoteserv/[curctx net]/gquotes/a$qtn" [tnda get "login/[curctx net]/$from"]
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.added $qtn]
			}
		}
		"de*" {
			if {$chan == 0} {
				set chan $from
				set ndacname [string map {/ [} [::base64::encode [string tolower [lindex $opara 0]]]]
				set para [lrange $para 1 end]
				if {![quoteservenabled [lindex $opara 0]]} {return}
			}
			set qtn [lindex $para 0]
			if {![string is integer $qtn]} {
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.usevalidint]
			}
			if {[ismodebutnot $chan $from v] || [operHasPrivilege [curctx net] $from [tnda get "quoteserv/[curctx net]/operflags"]] || [string tolower [uid2hand $from]] == [nda get "quoteserv/[curctx net]/quotes/$ndacname/a$qtn"]} {
				set qt [nda get "quoteserv/[curctx net]/quotes/$ndacname/q$qtn"]
				set qb [nda get "quoteserv/[curctx net]/quotes/$ndacname/u$qtn"]
				set qa [nda get "quoteserv/[curctx net]/quotes/$ndacname/a$qtn"]
				nda unset "quoteserv/[curctx net]/quotes/$ndacname/q$qtn"
				nda unset "quoteserv/[curctx net]/quotes/$ndacname/u$qtn"
				nda unset "quoteserv/[curctx net]/quotes/$ndacname/a$qtn"
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.removed $qtn $qb]
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.removedcontents $qt]
			} {
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.enopriv [tnda get "quoteserv/[curctx net]/operflags"]]
			}
		}
		"gde*" {
			set qtn [lindex $para 0]
			if {![string is integer $qtn]} {[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.usevalidint]}
			if {[operHasPrivilege [curctx net] $from [tnda get "quoteserv/[curctx net]/operflags"]]} {
				nda unset "quoteserv/[curctx net]/gquotes/q$qtn" ""
				nda unset "quoteserv/[curctx net]/gquotes/u$qtn" ""
				nda unset "quoteserv/[curctx net]/gquotes/a$qtn" ""
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan "\[\002Quotes\002\] Blanked quote number #$qtn in database."
			} {
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.enopriv [tnda get "quoteserv/[curctx net]/operflags"]]
			}
		}
		"jo*" {
			if {$chan == 0} {
				set chan $from
			}
			set tochan [lindex $para 0]
			if {[ismodebutnot $tochan $from v] || [operHasPrivilege [curctx net] $from [tnda get "quoteserv/[curctx net]/operflags"]]} {
				quoteservjoin $tochan
			} {
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.enopriv [tnda get "quoteserv/[curctx net]/operflags"]]
			}
		}
		"goa*" - "pa*" - "le*" {
			if {$chan == 0} {
				set chan $from
			}
			set tochan [lindex $para 0]
			if {[ismodebutnot $tochan $from v] || [operHasPrivilege [curctx net] $from [tnda get "quoteserv/[curctx net]/operflags"]]} {
				quoteservpart $tochan [format "(%s) %s!%s@%s" [tnda get "login/[curctx net]/$from"] [[curctx proto] uid2nick [curctx net] $from] [[curctx proto] uid2ident [curctx net] $from] [[curctx proto] uid2host [curctx net] $from]]
			} {
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.enopriv [tnda get "quoteserv/[curctx net]/operflags"]]
			}
		}
		"vi*" {
			if {$chan == 0} {
				set chan $from
				set ndacname [string map {/ [} [::base64::encode [string tolower [lindex $opara 0]]]]
				set para [lrange $para 1 end]
				if {![quoteservenabled [lindex $opara 0]]} {return}
			}
			set qtn [lindex $para 0]
			if {![string is integer $qtn]} {[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.usevalidint]}
			set qt [nda get "quoteserv/[curctx net]/quotes/$ndacname/q$qtn"]
			set qb [nda get "quoteserv/[curctx net]/quotes/$ndacname/u$qtn"]
			if {$qt != ""} {
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.qheader $qtn $qb]
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.quote $qt]
			} {
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.noresults]
			}
		}
		"gvi*" {
			set qtn [lindex $para 0]
			if {![string is integer $qtn]} {[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.usevalidint]}
			set qt [nda get "quoteserv/[curctx net]/gquotes/q$qtn"]
			set qb [nda get "quoteserv/[curctx net]/gquotes/u$qtn"]
			if {$qt != ""} {
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.qheader $qtn $qb]
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.quote $qt]
			} {
				[curctx proto] privmsg [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.noresults]
			}
		}
		"he*" {
#			set helpfile {             ---- Quotes Help ----
#!quote search - Search for quotes matching
#!quote view1stmatch - Search for quotes matching and view first matching quote.
#!quote view - View quote
#!quote add - Add quote.
#!quote del - Delete quote. Requires halfops or above.
#End of help for Q.}
			set helplist [tnda get "openconf/[ndcenc qshelp]/n1"]
			dictassign $helplist main helpfile
			foreach {helpline} $helpfile {
				[curctx proto] notice [curctx sock] [tnda get "quoteserv/[curctx net]/ourid"] $from $helpline
			}
		}
	}
}

proc requestq {n i m} {
}

proc quotesearch {chan pattern} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	set ret [list]
	foreach {qnum qvalue} [nda get "quoteserv/[curctx net]/quotes/$ndacname"] {
		if {[string index $qnum 0] != "q"} {continue}
		if {[string match -nocase $pattern $qvalue]} {lappend ret [string range $qnum 1 end]}
	}
	return $ret
}
