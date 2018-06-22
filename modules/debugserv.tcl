blocktnd debugserv

bind - evnt - confloaded debugserv.connect

proc debugserv.connect {arg} {
	puts stdout [format "there are %s debugserv blocks" [set blocks [tnda get "openconf/[ndcenc debugserv]/blocks"]]]
	for {set i 1} {$i < ($blocks + 1)} {incr i} {
		after 1000 [list debugserv.oneintro [tnda get [format "openconf/%s/hdr%s" [ndcenc debugserv] $i]] [tnda get [format "openconf/%s/n%s" [ndcenc debugserv] $i]]]
	}
}

proc debugserv.oneintro {headline block} {
	set net [lindex $headline 0]
	set nsock $::sock($net)
	dictassign $block logchan logchan nick nick ident ident host host modes modes realname realname rehashprivs rehashprivs
	tnda set "debugserv/$net/rehashprivs" $rehashprivs
	setctx $net
	$::nettype($net) sendUid $nsock $nick $ident $host $host [set ourid [$::nettype($net) getfreeuid $net]] [expr {($realname == "") ? "* Debug Service *" : $realname}] $modes
	tnda set "debugserv/$net/ourid" $ourid
	bind $nsock pub - ".metadata" [list debugserv.pmetadata $net]
#	bind $nsock pub - ".rehash" [list debugserv.crehash $net]
	$::nettype($net) putjoin $nsock $ourid $logchan
	after 500 [list $::nettype($net) putmode $nsock $ourid $logchan "+ao" [format "%s %s" [$::nettype($net) intclient2uid $net $ourid] [$::nettype($net) intclient2uid $net $ourid]]]
	bind $nsock msg [tnda get "debugserv/$net/ourid"] "metadata" [list debugserv.metadata $net]
#	bind $nsock msg [tnda get "debugserv/$net/ourid"] "rehash" [list debugserv.rehash $net]
#	bind $nsock pub - "gettext" [list debugserv.gettext $net]
	puts stdout "bind $nsock msg [tnda get "debugserv/$net/ourid"] metadata [list debugserv.metdata $net]"
	puts stdout [format "Connected for %s: %s %s %s" $net $nick $ident $host]
}

proc debugserv.rehash {n i m} {debugserv.crehash $n $i $i $m}

proc operHasPrivilege {n i p} {
	# this bit requires irca.
	set metadatum [tnda get "metadata/$n/$i/[ndcenc PRIVS]"]
	set md [split $metadatum " "]
	set pl [split $p " ,"]
	foreach {pv} $pl {
		if {[lsearch $md $pv] != -1} {return 1}
	}
	return 0
}

proc operHasAllPrivileges {n i p} {
	# this bit requires irca.
	set metadatum [tnda get "metadata/$n/$i/[ndcenc PRIVS]"]
	set md [split $metadatum " "]
	set pl [split $p " ,"]
	foreach {pv} $pl {
		if {[lsearch $md $pv] == -1} {return 0}
	}
	return 1
}

proc debugserv.crehash {n c i m} {
	if {![operHasPrivilege $n $i [tnda get "debugserv/$n/rehashprivs"]]} {
		$::nettype($n) [expr {$c != $i ? "privmsg" : "notice"}] [curctx sock] [tnda get "debugserv/$n/ourid"] $c [gettext debugserv.youvenoprivs2 $i [join [split [tnda get "debugserv/$n/rehashprivs"] ", "] ", or "]]
	} {
		after 500 [list uplevel #0 [list svc.rehash]]
		$::nettype($n) [expr {$c != $i ? "privmsg" : "notice"}] [curctx sock] [tnda get "debugserv/$n/ourid"] $c [gettext debugserv.rehashed [$::nettype($n) uid2nick $n $i]]
	}
}

proc debugserv.pmetadata {n c i m} {
	# net chan id msg
#	puts stdout "debugserv.pmetadata called $n $c $i $m"
	catch [set command {
	setctx $n
	set metadatalist [tnda get "metadata/$n/$i"]
	if {[llength $metadatalist] < 2} {
		$::nettype($n) [expr {$c != $i ? "privmsg" : "notice"}] [curctx sock] [tnda get "debugserv/$n/ourid"] $c [gettext debugserv.nometadata [$::nettype($n) uid2nick $n $i]]
	}
#	puts stdout $metadatalist
	foreach {.datum value} $metadatalist {
		set datum [ndcdec ${.datum}]
		$::nettype($n) [expr {$c != $i ? "privmsg" : "notice"}] [curctx sock] [tnda get "debugserv/$n/ourid"] $c [set totmsg [gettext debugserv.metadata $datum [$::nettype($n) uid2nick $n $i] $value]]
	} }] zere
	puts stdout [tnda get "oper/$n"]
	$::nettype($n) [expr {$c != $i ? "privmsg" : "notice"}] [curctx sock] [tnda get "debugserv/$n/ourid"] $c [gettext [expr {[tnda get "oper/$n/$i"] == 1 ? "debugserv.isoper" : "debugserv.isntoper"}] [$::nettype($n) uid2nick $n $i] $i]
#	puts stdout [curctx sock]
#	puts stdout $command
#	puts stdout $zere
}

proc debugserv.metadata {n i m} {
	debugserv.pmetadata $n $i $i $m
}
