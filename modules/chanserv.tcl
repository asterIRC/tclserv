# ChanServ for TclServ
# 2018 09 28
# Copyright ©2018CE AsterIRC
# All rights reserved. This file is under the GNU GPL; see
# LICENSE in the project root for information.

#           -----------------//----------------
#           ChanServ for TclServ.
# Version 0.9 - released some time in 2017, ChanServ 0.9 was for a time
# AsterIRC's only channels service. It was pretty horrendous. Nevertheless,
# it did its job valiantly. 
# This version's just gonna be a custom Tcl runner.

blocktnd chanserv

llbind - evnt - alive chanserv.connect
set numversion 1

proc chanserv.connect {arg} {
	puts stdout [format "there are %s chanserv blocks" [set blocks [tnda get "openconf/[ndcenc chanserv]/blocks"]]]
	for {set i 1} {$i < ($blocks + 1)} {incr i} {
		if {[string tolower [lindex [tnda get [format "openconf/%s/hdr%s" [ndcenc chanserv] $i]] 0]] != [string tolower $arg]} {continue}
		after 1000 [list chanserv.oneintro [tnda get [format "openconf/%s/hdr%s" [ndcenc chanserv] $i]] [tnda get [format "openconf/%s/n%s" [ndcenc chanserv] $i]]]
	}
}

proc cs.confighandler {servicename defdbname headline block} {
	set net [lindex $headline 0]
	set nsock $::sock($net)
	dictassign $block nick nick ident ident host host modes modes realname realname
	if {[llength [tnda get "service/$net/$servicename/config"]] != 0} {return -code error "<$servicename> O damn, I'm already loaded for $net!"}
	tnda set "service/$net/$servicename/config" $block
	if {[tnda get "service/$net/$servicename/config/dbname"] == ""} {tnda set "service/$net/$servicename/dbname" $defdbname}
	setctx $net
	if {[% intclient2uid [tnda get "service/$net/$servicename/ourid"]] == ""} {% sendUid $nick $ident $host $host [set ourid [% getfreeuid]] [expr {($realname == "") ? "* $servicename *" : $realname}] $modes; set connected "Connected"} {set connected "Already connected"}
	set ouroid [tnda get "service/$net/$servicename/ourid"]
	if {[info exists ourid]} {tnda set "service/$net/$servicename/ourid" $ourid} {set ourid [tnda get "service/$net/$servicename/ourid"]}
	puts stdout [format "%s for %s: %s %s %s" $connected $net $nick $ident $host]
	setuctx $nick
}

proc chanserv.oneintro {headline block} {
	cs.confighandler chanserv chanserv $headline $block
	dictassign $headline net network
	dictassign $block config eggconf nick nick ident username host my-hostname 

	bind time -|- "?0 * * * *" checkchannels
	bind time -|- "?5 * * * *" checkchannels
	bind time -|- "0 * * * *" checkchannels
	bind time -|- "5 * * * *" checkchannels
	setuctx $nick
	mysrc $eggconf
}

proc checkchannels {a b c d e} {
	set chans [channels]
	foreach {c} $chans {
		set inactive [channel get $c inactive]
		if {!$inactive} {@@ putjoin $c}
	}
	foreach {chan on} [tnda get "userchan/[curctx net]/[curctx uid]"] {
		if {$on} {
			set inactive [channel get $c inactive]
			if {$inactive} {@@ part $c "This channel is not active"}
		}
	}
}
