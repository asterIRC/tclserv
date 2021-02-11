#source chanserv.conf

#more thanks to fireegl
# XXX THIS PORTION BLOCKS NONGPL RELEASE

proc SetUdefDefaults {{name {*}}} {
	global UdefDefaults
	foreach udef [array names UdefDefaults $name] {
		#dict for {key value} $::database(channels) {
		#	if {![dict exists $value $udef]} {
		#		dbase set eggcompat [curctx net] channels $key $value $udef $UdefDefaults($udef)
		#	}
		#}
		foreach channel [channels] {
			if {[catch { channel get $channel $udef }]} {
				# channel set $channel $udef $UdefDefaults($udef)
				dbase set eggcompat [curctx net] channels [string toupper $channel] $udef $UdefDefaults($udef)
			}
		}
	}
}

# Defines a new udef:
proc setudef {type name {default {}}} {
	# Store the default for this udef:
	global UdefDefaults
	set name [string tolower $name]
	switch -- $type {
		{flag} { set UdefDefaults($name) [string is true -strict $default] }
		{int} { if {$default != {}} { set UdefDefaults($name) $default } else { set UdefDefaults($name) 0 } }
		{str} - {list} { set UdefDefaults($name) $default }
		{default} { return -code error "[mc {Invalid udef type: %s} $type]" }
	}
	# Store the udef itself:
	global Udefs
	set Udefs($name) $type
	# "UDEF: $name (${type}) defined.  Default: $UdefDefaults($name)"
	# Apply the default to all channels that don't already have it set:
	SetUdefDefaults $name
}

#  getudefs <flag/int/str>
#    Returns: a list of user defined channel settings of the given type, 
#             or all of them if no type is given.
proc getudefs {{type {}}} {
	# Note/FixMe: Eggdrop probably errors if $type is invalid.
	# This is not a compatibility problem though
	global Udefs
	set list [list]
	# Note/FixMe: We could also create a new array, called UdefTypes, which looks like (for example):
	# UdefTypes(flag) "autoop enforcebans ..."
	# That way we don't need a foreach here, and could just return the list..
	foreach u [array names Udefs] {
		if {$type eq {} || $type eq $Udefs($u)} {
			lappend list $u
		}
	}
	return $list
}

#  renudef <flag/int> <oldname> <newname>
#    Description: renames a user defined channel flag or integer setting.
#    Returns: nothing
#    Module: channels
proc renudef {type oldname newname} {
	global Udefs
	if {[info exists Udefs($newname)]} {return -1}
	if {[info exists Udefs($oldname)] && [string equal -nocase $Udefs($oldname) $type]} {
		dict for {key value} $::database(channels) {
			if {[dict exists $value $oldname]} {
				dbase set eggcompat [curctx net] channels $key $newname [dbase get eggcompat [curctx net] channels $key $oldname]
				dbase unset eggcompat [curctx net] channels $key $oldname
			}
		}
		set Udefs($newname) $Udefs($oldname)
		unset Udefs($oldname)
		global UdefDefaults
		set UdefDefaults($newname) $UdefDefaults($oldname)
		unset Udefs($oldname)
		return 1
	}
	return 0
}

#  deludef <flag/int> <name>
#    Description: deletes a user defined channel flag or integer setting.
#    Returns: nothing
#    Module: channels
# Proc written by Papillon@EFNet.
# FixMe: This proc is untested and unmodified from what he sent me.  Looks broken. =P
proc deludef {type name} {
	global Udefs
	if {[info exists Udefs($oldname)] && [string equal -nocase $Udefs($oldname) $type]} {
		dict for {key value} $::database(channels) { if {[dict exists $value $oldname]} { dbase unset eggcompat [curctx net] channels $key $oldname } }
		unset Udefs($oldname)
		global UdefDefaults
		unset Udefs($oldname)
		return 1
	}
	return 0
}

# Returns 1 if it's a valid (existing) name for a udef, or 0 if it's not:
proc validudef {name} {
	global Udefs
	info exists Udefs($name)
}


proc protectopcheck {mc f t p} {
	if {"o"==$mc && ![channel get $t protectop]} {return}
	if {"h"==$mc && ![channel get $t protecthalfop]} {return}
	if {"v"==$mc && ![channel get $t protectvoice]} {return}
	switch -- $mc {
		"o" {
			if {[matchattr [tnda get "login/[curctx net]/$p"] omn|omn $t]} {
				[curctx proto] putmode [curctx sock] 77 $t +$mc "$p" [tnda get "channels/[curctx net]/[ndaenc $t]/ts"]
			}
		}
		"h" {
			if {[matchattr [tnda get "login/[curctx net]/$p"] l|l $t]} {
				[curctx proto] putmode [curctx sock] 77 $t +$mc "$p" [tnda get "channels/[curctx net]/[ndaenc $t]/ts"]
			}
		}
		"v" {
			if {[matchattr [tnda get "login/[curctx net]/$p"] v|v $t]} {
				[curctx proto] putmode [curctx sock] 77 $t +$mc "$p" [tnda get "channels/[curctx net]/[ndaenc $t]/ts"]
			}
		}
	}
}

proc finduserbyid {n} {
	tnda get "login/[curctx net]/$f"
}

# XXX obsolete; safe to remove?
proc autoopcheck {c f} {
	set globe 0
	if {[channel get $c operit]} {set globe 1}
	if {[channel get $c autoop]} {set auto nmo} {set auto ""}
	if {[channel get $c autohalfop]} {append auto l}
	if {[channel get $c autovoice]} {append auto v}
	tcs:opcheck $c $f $globe $auto
}

proc unixtime {} {
	return [clock format [clock seconds] -format %s]
}

# XXX obsolete; safe to remove?
proc tcs:opcheck {c f {globe 0} {auto nmolv}} {
#	puts stdout "$c $f"
	if {[matchattr [tnda get "login/[curctx net]/$f"] |k $c]} {
		# obviously optimised for charybdis... ???
		[curctx proto] putmode [curctx sock] 77 $c +b "*![tnda get "ident/[curctx net]/$f"]@[tnda get "vhost/[curctx net]/$f"]" [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		[curctx proto] kick [curctx sock] 77 $c $f "Autokicked (+k attribute)"
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] n|] && $globe} {
		[curctx proto] putmode [curctx sock] 77 $c +[tnda get "pfx/owner"] $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] |n $c] && ([string first "o" $auto] != -1)} {
		[curctx proto] putmode [curctx sock] 77 $c +[tnda get "pfx/owner"] $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}

	if {[matchattr [tnda get "login/[curctx net]/$f"] m|] && $globe} {
		[curctx proto] putmode [curctx sock] 77 $c +[tnda get "pfx/protect"] $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] |m $c] && ([string first "o" $auto] != -1)} {
		[curctx proto] putmode [curctx sock] 77 $c +[tnda get "pfx/protect"] $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}

	if {[matchattr [tnda get "login/[curctx net]/$f"] a|]} {
		[curctx proto] putmode [curctx sock] 77 $c +o $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] o|] && $globe} {
		[curctx proto] putmode [curctx sock] 77 $c +o $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] |o $c] && ([string first "o" $auto] != -1)} {
		[curctx proto] putmode [curctx sock] 77 $c +o $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] l|] && $globe} {
		[curctx proto] putmode [curctx sock] 77 $c +[tnda get "pfx/halfop"] $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] |l $c] && ([string first "h" $auto] != -1)} {
		[curctx proto] putmode [curctx sock] 77 $c +[tnda get "pfx/halfop"] $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] v|] && $globe} {
		[curctx proto] putmode [curctx sock] 77 $c +v $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
	if {[matchattr [tnda get "login/[curctx net]/$f"] |v $c] && ([string first "v" $auto] != -1)} {
		[curctx proto] putmode [curctx sock] 77 $c +v $f [tnda get "channels/[curctx net]/[ndaenc $c]/ts"]
		return
	}
}

# XXX nobody calls me anymore; obsolete. safe to remove?
proc bitchopcheck {mc ftp} {
	set f [lindex $ftp 0]
	set t [lindex $ftp 1]
	set p [lindex $ftp 2]
	puts stdout "$ftp"
	if {[tnda get "pfx/owner"]==$mc && ![channel get $t bitch]} {return} {if {[tnda get "pfx/owner"] != q} {set mc q}}
	if {[tnda get "pfx/protect"]==$mc && ![channel get $t bitch]} {return} {if {[tnda get "pfx/protect"] != a} {set mc a}}
	if {"o"==$mc && ![channel get $t bitch]} {return}
	if {"h"==$mc && ![channel get $t halfbitch]} {return}
	if {"v"==$mc && ![channel get $t voicebitch]} {return}
	switch -glob -- $mc {
		"q" {
			if {![matchattr [tnda get "login/[curctx net]/$p"] n|n $t]} {
				puts stdout "M $t -$mc $p [nda get "regchan/[ndaenc $t]/ts"]"
				[curctx proto] putmode [curctx sock] 77 $t "-$mc" "$p" [nda get "regchan/[ndaenc $t]/ts"]
			}
		}
		"a" {
			if {![matchattr [tnda get "login/[curctx net]/$p"] mn|mn $t]} {
				puts stdout "M $t -$mc $p [nda get "regchan/[ndaenc $t]/ts"]"
				[curctx proto] putmode [curctx sock] 77 $t "-$mc" "$p" [nda get "regchan/[ndaenc $t]/ts"]
			}
		}
		"o" {
			if {![matchattr [tnda get "login/[curctx net]/$p"] aomn|omn $t]} {
				puts stdout "M $t -$mc $p [nda get "regchan/[ndaenc $t]/ts"]"
				[curctx proto] putmode [curctx sock] 77 $t "-$mc" "$p" [nda get "regchan/[ndaenc $t]/ts"]
			}
		}
		"h" {
			if {![matchattr [tnda get "login/[curctx net]/$p"] l|l $t]} {
				puts stdout "M $t -$mc $p [nda get "regchan/[ndaenc $t]/ts"]"
				[curctx proto] putmode [curctx sock] 77 $t "-$mc" "$p" [nda get "regchan/[ndaenc $t]/ts"]
			}
		}
		"v" {
			if {![matchattr [tnda get "login/[curctx net]/$p"] v|v $t]} {
				puts stdout "M $t -$mc $p [nda get "regchan/[ndaenc $t]/ts"]"
				[curctx proto] putmode [curctx sock] 77 $t "-$mc" "$p" [nda get "regchan/[ndaenc $t]/ts"]
			}
		}
	}
}

#proc every {milliseconds script} {$script; after $milliseconds [every $milliseconds $script]}
#every 1000 [list firellmbind - time [clock format [clock seconds] -format "%M %H %d %m %Y"]]
proc utimer {seconds tcl-command} {after [expr $seconds * 1000] ${tcl-command}}
proc timer {minutes tcl-command} {after [expr $minutes * 60 * 1000] ${tcl-command}}
proc utimers {} {set t {}; foreach a [after info] {lappend t "0 [lindex [after info $a] 0] $a"}; return $t}
proc timers {} {set t {}; foreach a [after info] {lappend t "0 [lindex [after info $a] 0] $a"}; return $t}
proc killtimer id {return [after cancel $id]}
proc killutimer id {return [after cancel $id]}

proc isbotnick {n} {return [expr {$n == [curctx user] || $n == [curctx uid]}]}

proc setctx {ctx} {
	global globctx
	if {[catch [list set ::sock($ctx)] erre] > 0} {return} ; # silently crap out
	set globctx $ctx
}

proc setuctx {ctx} {
	global globuctx
	if {[% nick2uid $ctx] == "" && !($ctx == "")} {return} ; # silently crap out
	if {$ctx == ""} {
		set globuctx ""
	} {
		set globuctx [% uid2intclient [% nick2uid $ctx]]
	}
}

proc % {c args} {
	set ul [list [curctx proto] $c [curctx sock]]
	foreach {a} $args {lappend ul $a}
	uplevel 1 $ul
}

proc @@ {c args} {
	set ul [list [curctx proto] $c [curctx sock] [curctx unum]]
	foreach {a} $args {lappend ul $a}
	uplevel 1 $ul
}

proc getctx {{type net}} {curctx $type}

proc curctx {{type net}} {
	if {$::globctx == ""} {return "-"}
	switch -exact -- [format ".%s" [string tolower $type]] {
		.sock {
			return $::sock($::globctx)
		}
		.net {
			return $::globctx
		}
		.unum {
			return $::globuctx
		}
		.uid {
			return [% intclient2uid $::globuctx]
		}
		.user {
			return [% uid2nick [% intclient2uid $::globuctx]]
		}
		.proto {
			return $::nettype($::globctx)
		}
	}
}

set globctx ""
set globuctx ""

foreach {pname} [list putserv puthelp putquick putnow] {
	proc $pname {msg} {
		if {[curctx unum] != ""} {
			% putnow [curctx unum] $msg
		} {
			% putnow "" $msg
		}
	}
}

proc pushmode {mode args} {
	@@ putmode $mode [join $args " "]
}

proc matchattr {handle attr {chan "*"}} {
	set handle [string tolower $handle]
	if {-1!=[string first "&" $attr]} {set and 1} {set and 0}
	set gattr [lindex [split $attr "&|"] 0]
	set cattr [lindex [split $attr "&|"] 1]
	if {$handle == "" || $handle == "*"} {return [expr {(($gattr==$cattr||$cattr=="") && $gattr=="-")?1:0}]};# dump
	set isattrg 0
	foreach {c} [split [nda get "eggcompat/[curctx net]/attrs/global/$handle"] {}] {
		foreach {k} [split $gattr {}] {
			if {$c == $k} {set isattrg 1}
		}
	}
	set isattrc 0
	if {"*"!=$chan} {
		foreach {c} [split [nda get "eggcompat/[curctx net]/attrs/[ndaenc $chan]/$handle"] {}] {
			foreach {k} [split $cattr {}] {
				if {$c == $k} {set isattrc 1}
			}
		}
	}
	if {$and && ($isattrg == $isattrc) && ($isattrc == 1)} {return 1}
	if {!$and && ($isattrg || $isattrc)} {return 1}
	return 0
}

proc chattr {handle attr {chan "*"}} {
	set handle [string tolower $handle]
	if {$chan == "*"} {
		set del [list]
		set app ""
		set state app
		foreach {c} [split $attr {}] {
			if {"+"==$c} {set state app;continue}
			if {"-"==$c} {set state del;continue}
			if {$state=="del"} {
				lappend del $c ""
			}
			if {$state=="app"} {
				lappend del $c ""
				append app $c
			}
		}
		nda set "eggcompat/[curctx net]/attrs/global/$handle" [join [concat [string map $del [nda get "eggcompat/[curctx net]/attrs/global/$handle"]] $app] ""]
	} {
		set del [list]
		set app ""
		set state app
		foreach {c} [split $attr {}] {
			if {"+"==$c} {set state app;continue}
			if {"-"==$c} {set state del;continue}
			if {$state=="del"} {
				lappend del $c ""
			}
			if {$state=="app"} {
				lappend del $c ""
				append app $c
			}
		}
		puts stdout [ndaenc $chan]
		nda set "eggcompat/[curctx net]/attrs/[ndaenc $chan]/$handle" [join [concat [string map $del [nda get "eggcompat/[curctx net]/attrs/[ndaenc $chan]/$handle"]] $app] ""]
	}
}

proc channels {} {
	set ret [list]
	foreach {chan _} [nda get "eggcompat/[curctx net]/channels"] {
		lappend ret $chan
	}
	return $ret
}

proc mc {form args} {
	format $form {*}$args
}

#TODO: make this a namespace ensemble

# hey, thanks fireegl
proc channel {command {channel {}} args} {
	# Note: Follow RFC 2812 regarding "2.2 Character codes", http://tools.ietf.org/html/rfc2812
	# Note that RFC 2812 gets the case of ^ and ~ backwards. ^ = uppercase ~ = lowercase
	# We should probably not follow the RFC in this instance and instead use the correct case for those two characters.
	# []\^ (uppers) == {}|~ (lowers)
	set upperchannel [string toupper $channel]
	global database
	switch -- [set command [string tolower $command]] {
		{add} {
			set args [lassign [callchannel $command $channel {*}$args] command channel]
			# Add the channel to the database:
			dbase set eggcompat [curctx net] channels $upperchannel name $channel
			SetUdefDefaults
			# Call ourself again to set the options:
			if {[llength $args]} { channel set $channel {*}$args }
			return {}
		}
		{set} {
			if {![dict exists [dbase get eggcompat [curctx net] channels] $upperchannel]} { return -code error "[mc {Invalid Channel: %s} $channel]" }
			# In the case of "set", $args is already in the form we can use.
			set setnext 0
			foreach o $args {
				if {$setnext} {
					set setnext 0
					switch -- $type {
						{int} - {integer} {
							# Note, settings such as flood-chan are treated as int's.  Hence the need for using split here:
							lassign [callchannel $command $channel $type $name [split $o {:{ }}]] command channel type name o
							dbase set eggcompat [curctx net] channels $upperchannel $name $o
						}
						{str} - {string} {
							lassign [callchannel $command $channel $type $name $o] command channel type name o
							dbase set eggcompat [curctx net] channels $upperchannel $name $o
						}
						{list} - {lappend} {
							lassign [callchannel $command $channel $type $name $o] command channel type name o
							database channels lappend $upperchannel $name $o
						}
						{flag} {
							# This is so we can support flags being set like:
							# [channel set #channel bitch +]
							# or: [channel set #channel revenge 1]
							# The old way is still supported though. (see below)
							switch -- $o {
								{+} { set o 1 }
								{-} { set o 0 }
								{default} { set o [string is true -strict $o] }
							}
							lassign [callchannel $command $channel $type $name $o] command channel type name o
							dbase set eggcompat [curctx net] channels $upperchannel $name $o
						}
						{unknown} - {default} {
							return -code error "[mc {Invalid channel option: %s} $name]"
						}
					}
				} elseif {$o != {}} {
					switch -- [set type [UdefType [set name [string trimleft $o {+-}]]]] {
						{flag} {
							switch -- [string index $o 0] {
								{+} {
									lassign [callchannel $command $channel $type $name 1] command channel type name o
									dbase set eggcompat [curctx net] channels $upperchannel $name $o
								}
								{-} {
									lassign [callchannel $command $channel $type $name 0] command channel type name o
									dbase set eggcompat [curctx net] channels $upperchannel $name $o
								}
								{default} {
									# They must want to set it using a second arg...
									set setnext 1
								}
							}
						}
						{int} - {str} - {list} - {integer} - {string} { set setnext 1 }
						{unknown} - {default} { return -code error "[mc {Illegal channel option: %s} $name]" }
					}
				}
			}
		}
		{info} {
			# COMPATIBILITY WARNING: Because Eggdrop doesn't return the info in any documented or understandable order,
			#                        Tcldrop will return a list of each channel setting and it's value.  This way makes the info MUCH easier to use by Tcl scripters.
			if {[dict exists [dbase get eggcompat [curctx net] channels] $upperchannel]} {
				dict get [dbase get eggcompat [curctx net] channels] $upperchannel
			} else {
				return -code error "[mc {No such channel record: %s} $channel]"
			}
		}
		{get} {
			if {[dict exists [dbase get eggcompat [curctx net] channels] $upperchannel]} {
				if {[dict exists [dbase get eggcompat [curctx net] channels] $upperchannel {*}$args]} {
					dict get [dbase get eggcompat [curctx net] channels] $upperchannel {*}$args
				} else {
					return -code error "[mc {Unknown channel setting: %s} $args]"
				}
			} else {
				return -code error "[mc {No such channel record: %s} $channel]"
			}
		}
		{list} {
			set list [list]
			dict for {key value} [dbase get eggcompat [curctx net] channels] { lappend list [dict get $value name] }
			return $list
		}
		{count} { dict size [dbase get eggcompat [curctx net] channels] }
		{remove} - {rem} - {delete} - {del} {
			if {[dict exists [dbase get eggcompat [curctx net] channels] $upperchannel]} {
				set args [lassign [callchannel $command $channel {*}$args] $command $channel]
				dbase unset eggcompat [curctx net] channels $upperchannel
			} else {
				return -code error "[mc {No such channel record: %s} $channel]"
			}
		}
		{exists} - {exist} {
			if {[dict exists [dbase get eggcompat [curctx net] channels] $upperchannel]} {
				return 1
			} else {
				return 0
			}
		}
		{default} { return -code error "[mc {Unknown channel sub-command "%s".} $command]" }
	}
}

# er, no ellenor, that's not how you do that
#namespace eval channel {
#	proc ::channel::get {chan flag} {
#		if {[::set enda [nda get "eggcompat/[curctx net]/chansets/[ndaenc $chan]/[ndaenc [string map {+ ""} $flag]]"]]!=""} {return $enda} {return 0}
#	}
#	proc ::channel::set {chan flags} {
#		if {[llength $flags] != 1} {
#			foreach {flag} $flags {
#				::set bit [string index $flag 0]
#				if {$bit=="+"} {::set bitt 1} {::set bitt 0}
#				::set flag [string range $flag 1 end]
#				nda set "eggcompat/[curctx net]/chansets/[ndaenc $chan]/[ndaenc [string map {+ ""} $flag]]" $bitt
#			}
#		} {
#			::set bit [string index $flags 0]
#			if {$bit=="+"} {::set bitt 1} {::set bitt 0}
#			::set flag [string range $flags 1 end]
#			nda set "eggcompat/[curctx net]/chansets/[ndaenc $chan]/[ndaenc [string map {+ ""} $flags]]" $bitt
#		}
#	}
#	namespace export *
#	namespace ensemble create
#}

proc validuser {n} {
	if {""==[dbase get usernames [curctx net] $n]} {return 0} {return 1}
}

proc userlist {} {
	set r [list]
	foreach {u _} [dbase get usernames [curctx net]] {
		lappend r $u
	}
	return $r
}

proc deluser {username} {
	if {![validuser $username]} {return 0}
	dbase unset usernames [curctx net] $username
}

proc delhost {username hostmask} {
	if {![validuser $username]} {return 0}
	set hmsks [dbase get usernames [curctx net] $username hostmasks
	set tounset [list]
	foreach {bindn hm} $hmsks {
		if {[string tolower $hm] == $hostmask} {lappend tounset $bindn}
	}
	foreach {n} $tounset {
		dbase unset usernames [curctx net] $username hostmasks $n
	}
	return 1
}

proc addhost {username hostmask} {adduser $username $hostmask}

proc adduser {username {hostmask ""}} {
	#if {[validuser $username]} {return 0}
	if {$hostmask != ""} {set moretodo 1} {set moretodo 0}
	while {0!=$moretodo} {
                set bindnum [rand 1 10000000]
                if {[dbase get usernames [curctx net] $username hostmasks $bindnum]==""} {set moretodo 0}
        }
	if {$hostmask != ""} {dbase set usernames [curctx net] $username hostmasks $bindnum $hostmask}
	dbase set usernames [curctx net] $username reg 1
	return 1
}

#llbind [curctx sock] msg 77 "chanset" msgchanset
#llbind [curctx sock] msg 77 "chattr" msgchattr
#llbind [curctx sock] msg 77 "setxtra" msgxtra
#set botnick $cs(nick)
#chattr $cs(admin) +mnolv

proc msgchanset {from msg} {
	set ndacname [ndaenc [lindex $msg 0 0]]
	set chanset [lindex $msg 0 1]
	if {300>[nda get "regchan/$ndacname/levels/[string tolower [tnda get "login/$from"]]"] && ![matchattr [tnda get "login/[curctx net]/$from"] m|m [lindex $msg 0 0]]} {
		[curctx proto] notice [curctx sock] 77 $from "Only channel super-operators (300) and above and network masters may use eggdrop-compatible chansets."
		return
	}
	channel set [lindex $msg 0 0] $chanset
	[curctx proto] notice [curctx sock] 77 $from "Eggdrop compatible chanset $chanset set on [lindex $msg 0 0]."
}

proc msgchattr {from msg} {
	set ndacname [ndaenc [lindex $msg 0 2]]
	set handle [lindex $msg 0 0]
	set hand [lindex $msg 0 0]
	set attrs [lindex $msg 0 1]
	set chan [lindex $msg 0 2]
	set ch [lindex $msg 0 2]
	foreach {c} [split $attrs {}] {
		if {$c == "+"} {continue}
		if {$c == "-"} {continue}
		if {$c == "k"} {set c "mn|mnol"}
		if {$c == "v"} {set c "mn|lmno"}
		if {$c == "l"} {set c "mn|mno"}
		if {$c == "o"} {set c "mn|omn"}
		if {$c == "m"} {set c "mn|mn"}
		if {$c == "n"} {set c "n|n"}
		if {$c == "a"} {set c "mn|"}
		if {![matchattr [tnda get "login/[curctx net]/$from"] $c $chan]} {
			[curctx proto] notice [curctx sock] 77 $from "You may only give flags you already possess (Any of flags $c required to set $attrs)."
			return
		}
	}
	if {""==$chan} {chattr $hand $attrs} {chattr $hand $attrs $chan}
	[curctx proto] notice [curctx sock] 77 $from "Global flags for $hand are now [nda get "eggcompat/[curctx net]/attrs/global/[string tolower $handle]"]"
	if {""==[nda get "regchan/$ndacname/levels/[string tolower $hand]"]} {nda set "regchan/$ndacname/levels/[string tolower $hand]" 1}
	if {$ch != ""} {[curctx proto] notice [curctx sock] 77 $from "Flags on $chan for $hand are now [nda get "eggcompat/[curctx net]/attrs/$ndacname/[string tolower $handle]"]"}
}

proc nick2hand {nick} {
	foreach {uid nic} [tnda get "nick/[curctx net]"] {
		if {[string tolower $nick] == [string tolower $nic]} {return [tnda get "login/[curctx net]/$uid"]}
	}
}

proc uid2hand {uid} {
	return [tnda get "login/[curctx net]/$uid"]
}

proc getuser {nick datafield {dataval "body"}} {
	return [dbase get usernames [curctx net] $nick setuser [ndaenc $datafield] [ndaenc $dataval]]
}

proc setuser {nick datafield {dataval "body"} {val {}}} {
	puts stdout "$nick $datafield $dataval $val"
	if {[string tolower $datafield] == "pass"} {usetpass $nick $dataval}
	if {[string tolower $datafield] == "hosts"} {addhost $nick $dataval}
	if {$val == {} && [string tolower $datafield] != "xtra"} {
		return [dbase set usernames [curctx net] $nick setuser [ndaenc $datafield] $dataval]
	} {
		return [dbase set usernames [curctx net] $nick setuser [ndaenc $datafield] [ndaenc $dataval] $val]
	}
}

proc msgxtra {from msg} {
	if {[set log [tnda get "login/[curctx net]/$from"]]==""} {
		[curctx proto] notice [curctx sock] 77 $from "Until you've registered with the bot, you have no business setting XTRA values."
		return
	}
	set subfield [lindex $msg 0 0]
	set value [join [lrange [lindex $msg 0] 1 end] " "]
	setuser $log "XTRA" $subfield $value
	[curctx proto] notice [curctx sock] 77 $from "Set your user record XTRA $subfield to $value."
}

proc chandname2name {channame} {return $channame}
proc channame2dname {channame} {return $channame}

proc islinked {bot} {return 0}

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

foreach {pn} [list botisop botisvoice botishalfop] {
	proc $pn {args} {return 1}
}

proc isop {chan id} {
	return [ismode $chan $id o]
}

proc isvoice {chan id} {
	return [ismode $chan $id v]
}

proc ishalf {chan id} {
	return [ismode $chan $id h]
}

proc ishalfop {chan id} {
	return [ismode $chan $id h]
}

proc ismode {chan id mode} {
	if {[string first $mode [[curctx proto] getupfx [curctx sock] $chan $id]] != -1} {return 1} {return 0}
}

proc ismodebutnot {chan id mode} {
	if {[string length [[curctx proto] getupfx [curctx sock] $chan $id]] > 0 && [string first $mode [[curctx proto] getupfx [curctx sock] $chan $id]] == -1} {return 1} {return 0}
}

# rules are odd. you should store the bind return in a variable to unbind it.
# flags aren't part of the bind define.
set nonusertypes [list conn  create  encap  evnt  join  login  mark  mode  part  pub  notc  quit  topic pubm nick ctcp ctcr]
set lowertypes [list notc ctcp ctcr pub msg]
proc ibind {type flag text script} {
	set ctxsock [curctx sock]
	set ctxuser [curctx unum]
	if {[lsearch -exact $::nonusertypes [string tolower $type]] != -1} {set binduser "-"} {set binduser $ctxuser}
	if {[lsearch -exact $::lowertypes [string tolower $type]] != -1} {set text [string tolower $text]}
	return [llbind $ctxsock $type $binduser $text [list setupthenrun [list [curctx net] $ctxsock $type $ctxuser $flag $text] $script]]
}

proc bind {type flag text script} {
	set ctxsock [curctx sock]
	set ctxuser [curctx unum]
	if {[lsearch -exact $::nonusertypes [string tolower $type]] != -1} {set binduser "-"} {set binduser $ctxuser}
	if {[lsearch -exact $::lowertypes [string tolower $type]] != -1} {set text [string tolower $text]}
	#puts stdout [list llbind $ctxsock $type $binduser $text [list isetupthenrun [list [curctx net] $ctxsock $type $ctxuser $flag $text] $script]]
	return [llbind $ctxsock $type $binduser $text [list isetupthenrun [list [curctx net] $ctxsock $type $ctxuser $flag $text] $script]]
}

proc unbind {type flag text {scrip ""}} {
	set ctxsock [curctx sock]
	set ctxuser [curctx unum]
	if {[lsearch -exact $::nonusertypes [string tolower $type]] != -1} {set binduser "-"} {set binduser $ctxuser}
	if {[lsearch -exact $::lowertypes [string tolower $type]] != -1} {set text [string tolower $text]}
	set binds [tnda get "llbinds/[curctx net]/$type/$binduser/[ndcenc $text]"]
	set killids [list]
	foreach {id script} $binds {
		if {[lindex $script 0] == "isetupthenrun" || [lindex $script 0] == "setupthenrun"} {
			set opts [lindex $script 1]
			lassign $opts netctx sockctx otype userctx flags otext
			if {$userctx == $ctxuser && $otype == $type && $text == $otext && ($scrip == "" || $scrip == $script)} {lappend killids $id}
		}
	}
	foreach {id} $killids {
		unllbind $ctxsock $type $binduser $text $id
	}
}

proc setupthenrun {opts script args} {
	lassign $opts netctx sockctx type userctx flags text
	global globuctx
	setctx $netctx
	set globuctx $userctx
	foreach {a} $args {
		lappend script $a
	}
	eval $script
}

proc isetupthenrun {opts script args} {
	lassign $opts netctx sockctx type userctx flags text
	global globuctx
	if {-1!=[lsearch -exact [list] $type]} {set chan [lindex $args 1]} {set chan "*"}
	setctx $netctx
	set globuctx $userctx
	# "nick uhost hand"
	lappend script [% uid2nick [lindex $args 0]]
	lappend script [format "%s@%s" [% uid2ident [lindex $args 0]] [% uid2host [lindex $args 0]]]
	lappend script [uid2hand [lindex $args 0]]
	if {![set output [matchattr [uid2hand [lindex $args 0]] $flags $chan]]} {puts stdout "execution denied of $script - matchattr is $output";return}
	foreach {a} [lrange $args 1 end] {
		lappend script $a
	}
	puts stdout "$script"
	eval $script
}

foreach {def} {
protectop protecthalfop protectvoice operit autoop autohalfop autovoice bitch halfbitch voicebitch inactive
} {
setudef flag $def
}

proc onchan {nick chan} {
	set uid [% nick2uid $nick]
	set ndacname [ndaenc $chan]
	if {[tnda get "userchan/[curctx net]/$uid/$ndacname"] == "1"} {return 1} {return 0}
}

proc alg {{ha ""}} {
	if {$ha == ""} {
		if {[set ha [cdbase get misc [curctx net] hashing]] != ""} {return $ha}
		if {[set ha [cdbase get gmisc hashing]] != ""} {return $ha}
		return "SSHA256"
	} {return $ha}
}

proc passwdok {n p} {
	set isp [dbase get usernames [curctx net] $n pass]
	set chkp [pwhash [alg [lindex [split $isp "/"] 0]] $p [lindex [split $isp "/"] end-1]]
	if {$isp==""} {return 1}
	if {$chkp == $isp} {return 1}
	return 0
}

proc usetpass {n p s} {
	set chkp [pwhash [alg] $p $s]
	dbase get usernames [curctx net] $n pass $chkp
}
