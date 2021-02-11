blocktnd quoteserv
blocktnd qshelp

source quoteserv.help

llbind - evnt - alive quoteserv.connect

proc quoteserv.connect {arg} {
	puts stdout [format "there are %s quoteserv blocks" [set blocks [tnda get "openconf/[ndcenc quoteserv]/blocks"]]]
	for {set i 1} {$i < ($blocks + 1)} {incr i} {
		if {[string tolower [lindex [tnda get [format "openconf/%s/hdr%s" [ndcenc quoteserv] $i]] 0]] != [string tolower $arg]} {continue}
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
	% sendUid $nick $ident $host $host [set ourid [% getfreeuid]] [expr {($realname == "") ? "* Quote Service *" : $realname}] $modes
	tnda set "quoteserv/[curctx net]/ourid" $ourid
#	llbind $nsock pub - ".metadata" [list quoteserv.pmetadata $net]
#	llbind $nsock pub - ".rehash" [list quoteserv.crehash $net]
	if {[string length $nspass] != 0 && [string length $nickserv] != 0} {
		# only works if nettype is ts6!
		if {[string first [quoteserv.find6sid $net $nsserv] [% nick2uid $nickserv]] == 0} {
			% privmsg $ourid $nickserv $nspass
		} {
			% privmsg $ourid $logchan [gettext quoteserv.impostornickserv $nickserv [nick2uid $nickserv] $nsserv [quoteserv.find6sid $net $nsserv]]
		}
	}
	after 650 % putjoin $ourid $logchan
	after 700 [list % putmode $ourid $logchan "+ao" [format "%s %s" [% intclient2uid $ourid] [% intclient2uid $ourid]]]
#	llbind $nsock msg [tnda get "quoteserv/[curctx net]/ourid"] "metadata" [list quoteserv.metadata $net]
#	llbind $nsock msg [tnda get "quoteserv/[curctx net]/ourid"] "rehash" [list quoteserv.rehash $net]
#	llbind $nsock pub - "gettext" [list quoteserv.gettext $net]
#	puts stdout "llbind $nsock msg [tnda get "quoteserv/[curctx net]/ourid"] metadata [list quoteserv.metdata $net]"
	puts stdout [format "Connected for %s: %s %s %s" $net $nick $ident $host]
	llbind $nsock pub - "!quote" [list quoteservdo $net]
	llbind $nsock evnt - privmsg [list qs.pmdo $net]
	puts stdout $::nd
	foreach {chan is} [nda get "quoteserv/[curctx net]/regchan"] {
		puts stdout "to join $chan on [curctx]"
		if {1!=$is} {continue}
		quoteservjoin [ndadec $chan] 0
#		% putjoin [tnda get "quoteserv/[curctx net]/ourid"] [::base64::decode [string map {[ /} $chan]] [nda get "regchan/$chan/ts"]
#		tnda set "channels/$chan/ts" [nda get "regchan/$chan/$::netname([curctx sock])/ts"]
	}
}

proc qs.pmdo {n i t m} {
	set whoarewe [tnda get "intclient/$n/$t"]
	if {$whoarewe != [tnda get "quoteserv/[curctx net]/ourid"]} {return}
	quoteservdo $n $i 0 $m
}

proc quoteservjoin {chan {setting 1}} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	puts stdout "to join $chan on [curctx]"
	% putjoin [tnda get "quoteserv/[curctx net]/ourid"] $chan
	% putmode [tnda get "quoteserv/[curctx net]/ourid"] $chan "+ao" \
		[format "%s %s" [% intclient2uid [tnda get "quoteserv/[curctx net]/ourid"]]\
		 [% intclient2uid [tnda get "quoteserv/[curctx net]/ourid"]]]
	if {$setting} {nda set "quoteserv/[curctx net]/regchan/$ndacname" 1}
}

proc quoteservpart {chan {who "the script"} {msg isunused}} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	% putpart [tnda get "quoteserv/[curctx net]/ourid"] $chan [gettext quoteserv.left $who]
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
quoteserv.disabled >>> Sorry, I'm disabled for %s.
}

proc quoteservdo {n from chan m} {
	setctx $n
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	if {![quoteservenabled $chan] && $chan != 0} {return}
	# Q isn't in channel, no need to check quotes
	set subcmd [lindex [split $m " "] 0]
	set para [lrange [split $m " "] 1 end]
	set opara [lrange [split $m " "] 1 end]
	if {$chan == 0} {
		set chan [string tolower [lindex $opara 0]]
		set targ $from
		set ndacname [string map {/ [} [::base64::encode [string tolower [lindex $opara 0]]]]
		set para [lrange $para 1 end]
		if {![quoteservenabled [lindex $opara 0]]} {
			set disabled 1
		} {	set disabled 0}
	} else {
		set targ $chan
		set disabled 0
	}
	switch -nocase -glob -- $subcmd {
		"se*" {
			if {$disabled} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.disabled $chan]
				return
			}
			set ptn [format "*%s*" [join $para " "]]
			set qts [quotesearch $chan $ptn]
			if {[llength $qts] != 0} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.results #[join $qts ", #"]]
			} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.noresults]
			}
		}
		"vi*1*ma*" {
			if {$disabled} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.disabled $chan]
				return
			}
			set ptn [format "*%s*" [join $para " "]]
			set qts [quotesearch $chan $ptn]
			if {[llength $qts]} {
				set qtn [lindex $qts 0]
				set qt [nda get "quoteserv/[curctx net]/quotes/$ndacname/q$qtn"]
				set qb [nda get "quoteserv/[curctx net]/quotes/$ndacname/u$qtn"]
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.qheader $qtn $qb]
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.quote $qt]
			} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.noresults]
			}
		}
		"ad*" {
			if {$disabled} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.disabled $chan]
				return
			}
			set qt [join $para " "]
			set qtn [expr {([llength [nda get "quoteserv/[curctx net]/quotes/$ndacname"]]/6)+1}]
			nda set "quoteserv/[curctx net]/quotes/$ndacname/q$qtn" $qt
			nda set "quoteserv/[curctx net]/quotes/$ndacname/u$qtn" [format "(%s) %s!%s@%s" [tnda get "login/[curctx net]/$from"] [% uid2nick $from] [% uid2ident $from] [% uid2host $from]]
			nda set "quoteserv/[curctx net]/quotes/$ndacname/a$qtn" [string tolower [tnda get "login/[curctx net]/$from"]]
			% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.added $qtn]
		}
		"gad*" {
			set qt [join $para " "]
			set qtn [expr {([llength [nda get "quoteserv/[curctx net]/quotes/$ndacname"]]/6)+3}]
			if {![operHasPrivilege [curctx net] $from [tnda get "quoteserv/[curctx net]/operflags"]]} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.enopriv [tnda get "quoteserv/[curctx net]/operflags"]]
			} {
				nda set "quoteserv/[curctx net]/gquotes/q$qtn" $qt
				nda set "quoteserv/[curctx net]/gquotes/u$qtn" [format "(%s) %s!%s@%s" [tnda get "login/[curctx net]/$from"] [% uid2nick $from] [% uid2ident $from] [% uid2host $from]]
				nda set "quoteserv/[curctx net]/gquotes/a$qtn" [tnda get "login/[curctx net]/$from"]
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.added $qtn]
			}
		}
		"de*" {
			if {$disabled} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.disabled $chan]
				return
			}
			set qtn [lindex $para 0]
			if {![string is integer $qtn]} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.usevalidint]
			}
			if {[ismodebutnot $chan $from v] || [operHasPrivilege [curctx net] $from [tnda get "quoteserv/[curctx net]/operflags"]] || [string tolower [uid2hand $from]] == [nda get "quoteserv/[curctx net]/quotes/$ndacname/a$qtn"]} {
				set qt [nda get "quoteserv/[curctx net]/quotes/$ndacname/q$qtn"]
				set qb [nda get "quoteserv/[curctx net]/quotes/$ndacname/u$qtn"]
				set qa [nda get "quoteserv/[curctx net]/quotes/$ndacname/a$qtn"]
				nda unset "quoteserv/[curctx net]/quotes/$ndacname/q$qtn"
				nda unset "quoteserv/[curctx net]/quotes/$ndacname/u$qtn"
				nda unset "quoteserv/[curctx net]/quotes/$ndacname/a$qtn"
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.removed $qtn $qb]
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.removedcontents $qt]
			} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.enopriv [tnda get "quoteserv/[curctx net]/operflags"]]
			}
		}
		"gde*" {
			set qtn [lindex $para 0]
			if {![string is integer $qtn]} {% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.usevalidint]}
			if {[operHasPrivilege [curctx net] $from [tnda get "quoteserv/[curctx net]/operflags"]]} {
				nda unset "quoteserv/[curctx net]/gquotes/q$qtn" ""
				nda unset "quoteserv/[curctx net]/gquotes/u$qtn" ""
				nda unset "quoteserv/[curctx net]/gquotes/a$qtn" ""
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ "\[\002Quotes\002\] Blanked quote number #$qtn in database."
			} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.enopriv [tnda get "quoteserv/[curctx net]/operflags"]]
			}
		}
		"jo*" {
			set tochan $chan
			if {[ismodebutnot $tochan $from v] || [operHasPrivilege [curctx net] $from [tnda get "quoteserv/[curctx net]/operflags"]]} {
				quoteservjoin $tochan
			} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.enopriv [tnda get "quoteserv/[curctx net]/operflags"]]
			}
		}
		"goa*" - "pa*" - "le*" {
			if {$disabled} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.disabled $chan]
				return
			}
			set tochan [lindex $para 0]
			if {[ismodebutnot $tochan $from v] || [operHasPrivilege [curctx net] $from [tnda get "quoteserv/[curctx net]/operflags"]]} {
				quoteservpart $tochan [format "(%s) %s!%s@%s" [tnda get "login/[curctx net]/$from"] [% uid2nick $from] [% uid2ident $from] [% uid2host $from]]
			} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.enopriv [tnda get "quoteserv/[curctx net]/operflags"]]
			}
		}
		"vi*" {
			if {$disabled} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.disabled $chan]
				return
			}
			set qtn [lindex $para 0]
			if {![string is integer $qtn]} {% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.usevalidint]}
			set qt [nda get "quoteserv/[curctx net]/quotes/$ndacname/q$qtn"]
			set qb [nda get "quoteserv/[curctx net]/quotes/$ndacname/u$qtn"]
			if {$qt != ""} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.qheader $qtn $qb]
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.quote $qt]
			} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.noresults]
			}
		}
		"gvi*" {
			set qtn [lindex $para 0]
			if {![string is integer $qtn]} {% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.usevalidint]}
			set qt [nda get "quoteserv/[curctx net]/gquotes/q$qtn"]
			set qb [nda get "quoteserv/[curctx net]/gquotes/u$qtn"]
			if {$qt != ""} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.qheader $qtn $qb]
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.quote $qt]
			} {
				% privmsg [tnda get "quoteserv/[curctx net]/ourid"] $targ [gettext quoteserv.noresults]
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
				% notice [tnda get "quoteserv/[curctx net]/ourid"] $from $helpline
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
