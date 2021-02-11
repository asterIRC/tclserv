blocktnd debugserv

llbind - evnt - alive debugserv.connect

proc debugserv.connect {arg} {
	puts stdout [format "there are %s debugserv blocks" [set blocks [tnda get "openconf/[ndcenc debugserv]/blocks"]]]
	for {set i 1} {$i < ($blocks + 1)} {incr i} {
		if {[string tolower [lindex [tnda get [format "openconf/%s/hdr%s" [ndcenc debugserv] $i]] 0]] != [string tolower $arg]} {continue}
		after 1000 [list debugserv.oneintro [tnda get [format "openconf/%s/hdr%s" [ndcenc debugserv] $i]] [tnda get [format "openconf/%s/n%s" [ndcenc debugserv] $i]]]
	}
}

proc debugserv.find6sid {n s {hunting 0}} {
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

proc debugservenabled {chan} {
	if {[string tolower $chan] != [string tolower [tnda get "debugserv/[curctx net]/logchan"]]} {return 0}
	return 1
}

proc debugserv.armdns {headline block} {
	
}

proc debugserv.oneintro {headline block} {
	set net [lindex $headline 0]
	set nsock $::sock($net)
	dictassign $block logchan logchan nick nick ident ident host host modes modes realname realname rehashprivs rehashprivs idcommand nspass nickserv nickserv nsserv nsserv \
	                  dnsconf dnsconf tclprivs tclprivs
	tnda set "debugserv/$net/rehashprivs" $rehashprivs
	tnda set "debugserv/$net/tclprivs" $tclprivs
	tnda set "debugserv/$net/logchan" $logchan
	#tnda set "debugserv/$net/nspass" $nspass
	setctx $net
	if {[% intclient2uid [tnda get "debugserv/$net/ourid"]] == ""} {% sendUid $nick $ident $host $host [set ourid [% getfreeuid]] [expr {($realname == "") ? "* Debug Service *" : $realname}] $modes}
	set ouroid [tnda get "debugserv/$net/ourid"]
	if {[info exists ourid]} {tnda set "debugserv/$net/ourid" $ourid} {set ourid [tnda get "debugserv/$net/ourid"]}
	unllbindall $nsock pub - ".rehash"
	unllbindall $nsock pub - ".metadata"
	unllbindall $nsock msg $ourid "rehash"
	unllbindall $nsock msg $ourid "metadata"
	if {$ouroid != $ourid} {
		unllbindall $nsock msg $ouroid "rehash"
		unllbindall $nsock msg $ouroid "metadata"
	}
	setuctx $nick
	llbind $nsock pub - ".metadata" [list debugserv.pmetadata $net]
	llbind $nsock pub - ".rehash" [list debugserv.crehash $net]
	if {[string length $nspass] != 0 && [string length $nickserv] != 0} {
		# only works if nettype is ts6!
		if {[string first [debugserv.find6sid $net $nsserv] [% nick2uid $nickserv]] == 0} {
			% privmsg $ourid $nickserv $nspass
		} {
			% privmsg $ourid $logchan [gettext debugserv.impostornickserv $nickserv [$::nettype($net) nick2uid $n $nickserv] $nsserv [debugserv.find6sid $net $nsserv]]
		}
	}
	after 650 % putjoin $ourid $logchan
	after 700 [list % putmode $ourid $logchan "+ao" [format "%s %s" [% intclient2uid $ourid] [% intclient2uid $ourid]]]

	llbind $nsock msg [tnda get "debugserv/$net/ourid"] "metadata" [list debugserv.metadata $net]
	llbind $nsock msg [tnda get "debugserv/$net/ourid"] "rehash" [list debugserv.rehash $net]
#	llbind $nsock pub - "gettext" [list debugserv.gettext $net]
	llbind $nsock pub - "!usage" [list debugserv.pusage $net]
	debugserv.armdns $headline $dnsconf
	puts stdout "llbind $nsock msg [tnda get "debugserv/$net/ourid"] metadata [list debugserv.metdata $net]"
	puts stdout [format "Connected for %s: %s %s %s" $net $nick $ident $host]
}

proc debugserv.pusage {n c i m} {
	set uptime [exec uptime]
	% [expr {$c != $i ? "privmsg" : "notice"}] [tnda get "debugserv/$n/ourid"] $c $uptime
}

proc debugserv.rehash {n i m} {debugserv.crehash $n $i $i $m}

proc debugserv.crehash {n c i m} {
	if {![operHasPrivilege $n $i [tnda get "debugserv/$n/rehashprivs"]]} {
		% [expr {$c != $i ? "privmsg" : "notice"}] [tnda get "debugserv/$n/ourid"] $c [gettext debugserv.youvenoprivs2 $i [join [split [tnda get "debugserv/$n/rehashprivs"] ", "] ", or "]]
	} {
		after 500 [list uplevel #0 [list svc.rehash]]
		% [expr {$c != $i ? "privmsg" : "notice"}] [tnda get "debugserv/$n/ourid"] $c [gettext debugserv.rehashed [% uid2nick $i]]
	}
}

proc debugserv.pmetadata {n c i m} {
	# net chan id msg
	setctx $n
	if {($c != $i) && ![debugservenabled $c]} {return}
	set metadatalist [tnda get "metadata/$n/$i"]
	if {[llength $metadatalist] < 2} {
		% [expr {$c != $i ? "privmsg" : "notice"}] [tnda get "debugserv/$n/ourid"] $c [gettext debugserv.nometadata [% uid2nick $i]]
	}
	foreach {.datum value} $metadatalist {
		set datum [ndcdec ${.datum}]
		% [expr {$c != $i ? "privmsg" : "notice"}] [tnda get "debugserv/$n/ourid"] $c [set totmsg [gettext debugserv.metadata $datum [% uid2nick $i] $value]]
	}
	% [expr {$c != $i ? "privmsg" : "notice"}] [tnda get "debugserv/$n/ourid"] $c [gettext [expr {[tnda get "oper/$n/$i"] == 1 ? "debugserv.isoper" : "debugserv.isntoper"}] [% uid2nick $i] $i]
}

proc debugserv.metadata {n i m} {
	debugserv.pmetadata $n $i $i $m
}

