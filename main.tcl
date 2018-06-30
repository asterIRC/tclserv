#!/usr/bin/env tclsh
# Basic tcl services program.

package require tie
package require base64
package require sha1
#set b64 [split "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789[]" {}]

source b64.tcl

proc pwhash {pass} {
	global b64
	set hash [::sha1::sha1 -hex $pass]
	return "SHA1/$hash"
}

proc rand {minn {maxx 0}} {
	if {$minn==$maxx} {return $maxx}
	if {$minn > $maxx} {set omx $maxx; set maxx $minn ; set minn $omx}
	set maxnum [expr {$maxx - $minn}]
	set fp [open /dev/urandom r]
	set bytes [read $fp 6]
	close $fp
	scan $bytes %c%c%c%c%c%c ca co ce cu ci ch
	set co [expr {$co + pow(2,8)}]
	set ce [expr {$ce + pow(2,16)}]
	set cu [expr {$cu + pow(2,24)}]
	set ci [expr {$ci + pow(2,32)}]
	set ch [expr {$ch + pow(2,40)}]
	return [expr {$minn+(int($ca+$co+$ce+$cu+$ci+$ch)%$maxnum)}]
}

proc mysrc {script} {
	set fp [open $script r]
	set ev [read $fp]
	close $fp
	uplevel "#0" $ev
}

proc readfile {script} {
	set fp [open $script r]
	set ev [read $fp]
	close $fp
	return $ev
}

proc readbfile {script} {
	set fp [open $script rb]
	set ev [read $fp]
	close $fp
	return $ev
}

proc loadmodule {script} {
	set fp [open [format "./modules/%s.tcl" $script] r]
	set ev [read $fp]
	close $fp
	uplevel "#0" $ev
}

proc save.db {name var no oper} {
	upvar $var db
	global lastsave
	if {$lastsave + 40 > [set now [clock seconds]]} {return} ;#save CPU time by not always saving DB; integrity problems may result
	# ensure DB save is atomic, so if tclserv is killed during or under 12.5 seconds after save
	catch [list file rename $name [format "%s.bk%s" $name $now]]
	set there [open $name [list WRONLY CREAT TRUNC BINARY]]
	chan configure $there -blocking 0 -buffering full -buffersize 8192
	# should not block for long
	puts -nonewline $there $db
	flush $there
	close $there
	after 12500 [list catch [list file delete -- [format "%s.bk%s" $name $now]]]
	return
}

mysrc nda.tcl
# every 40sec, save, but not if never written

set lastsave [clock seconds]

if {[file exists services.db]} {
	puts stdout "reading the nda dict"
	set nd [readbfile services.db]
	puts stdout $nd
}
set nd [readbfile services.db]

set globwd [pwd]
set gettext [list]

trace add variable nd [list write unset] [list save.db [format "%s/%s" [pwd] services.db]]


#::tie::tie nd file services.db

source openconf2.tcl

foreach {file} [lsort [glob ./core/*.tcl]] {
	mysrc $file
}
#mysrc services.conf


proc svc.rehash {} {
	global gettext
	tnda set rehashing 1
	if {[file exists $::globwd/language.txt]} {
		set languagefile [split [readfile [format "%s/%s" $::globwd language.txt]] "\n"]
		foreach {line} $languagefile {
			set ll [split $line " "]
			set ltext [join [lrange $ll 1 end] " "]
			dict set gettext [lindex $ll 0] $ltext
		}
	}
	tnda set "openconf" [list]
	mysrc $::globwd/services.conf
	tnda set rehashing 0
}

svc.rehash
#by now we've loaded everything
firellbind - evnt - "confloaded" loaded

#load from cfg file, not here

#foreach {file} [lsort [glob ./modules/*.tcl]] {
#	mysrc $file
#}

vwait forever
