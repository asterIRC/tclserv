proc confighandler {servicename defdbname headline block} {
	set net [lindex $headline 0]
	set nsock $::sock($net)
	dictassign $block nick nick ident ident host host realname realname
	if {[llength [tnda get "service/$net/$servicename/config"]] != 0} {return -code error "<$servicename> O damn, I'm already loaded for $net!"
	tnda set "service/$net/$servicename/config" $block
	if {[tnda get "service/$net/$servicename/config/dbname"] == ""} {tnda set "service/$net/$servicename/dbname" $defdbname}
	setctx $net
	if {[% intclient2uid [tnda get "service/$net/$servicename/ourid"]] == ""} {% sendUid $nick $ident $host $host [set ourid [% getfreeuid]] [expr {($realname == "") ? "* $servicename *" : $realname}] $modes; set connected "Connected"} {set connected "Already connected"}
	set ouroid [tnda get "service/$net/$servicename/ourid"]
	if {[info exists ourid]} {tnda set "service/$net/$servicename/ourid" $ourid} {set ourid [tnda get "service/$net/$servicename/ourid"]}
	puts stdout [format "%s for %s: %s %s %s" $connected $net $nick $ident $host]
}

