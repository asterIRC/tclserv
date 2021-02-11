#!/usr/bin/env tclsh
# Basic tcl services program.

package require tie
package require base64
package require sha1
#set b64 [split "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789[]" {}]

source b64.tcl

proc pwhash.SHA1 {pass {salt "a"}} {
	global b64
	set hash [::sha1::sha1 -hex $pass]
	return "SHA1//$hash"
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
	chan configure $fp -encoding utf-8
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
	set ismodule 0
	foreach {file} [lsort [glob ./modules/*.tcl]] {
		if {$file == [format "./modules/%s.tcl" $script]} {set ismodule 1}
	}
	if {!$ismodule} {
		putloglev o * "MODULE $script DOES NOT EXIST; CONTINUING (or attempting to) ANYWAY"
		return
	}
	set fp [open [format "./modules/%s.tcl" $script] r]
	set ev [read $fp]
	close $fp
	uplevel "#0" $ev
}

proc save.db {name var no oper {apres 1}} {
	upvar $var db
	global lastsave
	if {$apres != 1 && ($lastsave + 40 > [set now [clock seconds]])} {return} ;#save CPU time by not always saving DB. integrity problems may result
	# but do not save CPU time if we are apres=0
	# ensure DB save is atomic, so if tclserv is killed during or under 12.5 seconds after save
	catch [list file rename $name [format "%s.bk%s" $name $now]]
	set there [open $name [list WRONLY CREAT TRUNC]]
	chan configure $there -encoding utf-8 -blocking 0 -buffering full -buffersize 8192
	# should not block for long
	puts -nonewline $there $db
	flush $there
	close $there
#	if {$apres == 1} { ;# the french word for "after", apres (from après) is the variable we use to say we want to repeat. on by default.
		after 12500 [list catch [list file delete -- [format "%s.bk%s" $name $now]]]
#	}
	return
}

mysrc nda.tcl
# every 40sec, save, but not if never written

set lastsave [clock seconds]

if {[file exists services.db]} {
	#puts stdout "reading the nda dict"
	set nd [readbfile services.db]
	#puts stdout $nd
}

set globwd [pwd]
set gettext [list]

proc outputbotnick {var no oper} {
	upvar $var v
	# depends on 4000-convenience. luckily not used before that's loaded or we'd be issue.
	set v [curctx user]
}

proc showcontexts {var no oper} {
	upvar $var v
#	puts stdout "curctx is [curctx unum]@[curctx net]"
}

# eventually we need to change services.db to SERVICESDBNAME or something.
trace add variable nd [list write unset] [list save.db [set sdbname [format "%s/%s" [pwd] services.db]]]
trace add variable botnick [list read] [list outputbotnick]
trace add variable globuctx [list read write] [list showcontexts]

proc force_save_db {dbname {d ::nd}} {
	# the fifth variable is "après", which refers to whether the save is a one-off, or whether it's ongoing. it defaults to 1, which means ongoing. this is a one-off save.
	save.db $dbname $d 0 write 0
}

#::tie::tie nd file services.db

source openconf2.tcl
#mysrc services.conf


proc svc.rehash {} {
	global gettext
	tnda set rehashing 1
	foreach {file} [lsort [glob ./core/*.tcl]] {
		mysrc $file
	}
	force_save_db $::sdbname
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
	firellbind - evnt - "confloaded" loaded
}

svc.rehash
#by now we've loaded everything
#firellbind - evnt - "confloaded" loaded

#load from cfg file, not here

#foreach {file} [lsort [glob ./modules/*.tcl]] {
#	mysrc $file
#}

vwait forever
