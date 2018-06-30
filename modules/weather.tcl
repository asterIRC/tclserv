blocktnd weatherserv
blocktnd wshelp

#source weatherserv.help

llbind - evnt - alive weatherserv.connect

proc weatherserv.connect {arg} {
	puts stdout [format "there are %s weatherserv blocks" [set blocks [tnda get "openconf/[ndcenc weatherserv]/blocks"]]]
	for {set i 1} {$i < ($blocks + 1)} {incr i} {
		if {[string tolower [lindex [tnda get [format "openconf/%s/hdr%s" [ndcenc weatherserv] $i]] 0]] != [string tolower $arg]} {continue}
		after 1000 [list weatherserv.oneintro [tnda get [format "openconf/%s/hdr%s" [ndcenc weatherserv] $i]] [tnda get [format "openconf/%s/n%s" [ndcenc weatherserv] $i]]]
	}
}

proc weatherserv.find6sid {n s {hunting 0}} {
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

proc weatherserv.oneintro {headline block} {
	set net [lindex $headline 0]
	set nsock $::sock($net)
	setctx $net
	dictassign $block logchan logchan nick nick ident ident host host modes modes realname realname operflags rehashprivs idcommand nspass \
		nickserv nickserv nsserv nsserv
	tnda set "weather/[curctx net]/operflags" $rehashprivs
	tnda set "weather/[curctx net]/logchan" $logchan
	#tnda set "weather/[curctx net]/nspass" $nspass
	setctx $net
	% sendUid $nick $ident $host $host [set ourid [% getfreeuid]] [expr {($realname == "") ? "* Debug Service *" : $realname}] $modes
	tnda set "weather/[curctx net]/ourid" $ourid
#	llbind $nsock pub - ".metadata" [list weatherserv.pmetadata $net]
#	llbind $nsock pub - ".rehash" [list weatherserv.crehash $net]
	if {[string length $nspass] != 0 && [string length $nickserv] != 0} {
		# only works if nettype is ts6!
		if {[string first [weatherserv.find6sid $net $nsserv] [% nick2uid $nickserv]] == 0} {
			% privmsg $ourid $nickserv $nspass
		} {
			% privmsg $ourid $logchan [gettext weatherserv.impostornickserv $nickserv [$::nettype($net) nick2uid $n $nickserv] $nsserv [weatherserv.find6sid $net $nsserv]]
		}
	}
	after 650 [list % putjoin $ourid $logchan]
	after 950 [list % putmode $ourid $logchan "+ao" [format "%s %s" [% intclient2uid $ourid] [% intclient2uid $ourid]]]
#	llbind $nsock msg [tnda get "weather/[curctx net]/ourid"] "metadata" [list weatherserv.metadata $net]
#	llbind $nsock msg [tnda get "weather/[curctx net]/ourid"] "rehash" [list weatherserv.rehash $net]
#	llbind $nsock pub - "gettext" [list weatherserv.gettext $net]
#	puts stdout "llbind $nsock msg [tnda get "weather/[curctx net]/ourid"] metadata [list weatherserv.metdata $net]"
	puts stdout [format "Connected for %s: %s %s %s" $net $nick $ident $host]
	llbind $nsock pub - "!quote" [list weatherservdo $net]
	llbind $nsock evnt - privmsg [list ws.pmdo $net]
	puts stdout $::nd
	foreach {chan is} [nda get "weather/[curctx net]/regchan"] {
		puts stdout "to join $chan on [curctx]"
		if {1!=$is} {continue}
		weatherjoin [ndadec $chan] 0
#		% putjoin [tnda get "weather/[curctx net]/ourid"] [::base64::decode [string map {[ /} $chan]] [nda get "regchan/$chan/ts"]
#		tnda set "channels/$chan/ts" [nda get "regchan/$chan/$::netname([curctx sock])/ts"]
	}
}

#$::maintype sendUid [curctx sock] "W" "weather" "services." "services." 57 "Weather Services"
llbind [curctx sock] request "w" "-" weatherjoin
llbind [curctx sock] request "weather" "-" weatherjoin

proc weatherjoin {chan {setting 1}} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	puts stdout "to join $chan on [curctx]"
	% putjoin [tnda get "weather/[curctx net]/ourid"] $chan
	% putmode [tnda get "weather/[curctx net]/ourid"] $chan "+ao" \
		[format "%s %s" [% intclient2uid [tnda get "weather/[curctx net]/ourid"]]\
		 [% intclient2uid [tnda get "weather/[curctx net]/ourid"]]]
	if {$setting} {nda set "weather/[curctx net]/regchan/$ndacname" 1}
}

proc weatherpart {chan {who "the script"} {msg isunused}} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	% putpart [tnda get "weather/[curctx net]/ourid"] $chan [gettext weather.left $who]
	nda set "weather/[curctx net]/regchan/$ndacname" 0
	nda unset "weather/[curctx net]/regchan/$ndacname"
}

proc weatherenabled {chan} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	if {[nda get "weather/[curctx net]/regchan/$ndacname"] == 1} {return 1} {return 0}
}

##############################################################################################
##  ##  wunderground.tcl for eggdrop by Ford_Lawnmower irc.geekshed.net #Script-Help    ##  ##
##############################################################################################
## To use this script you must set channel flag +weather (ie .chanset #chan +weather)       ##
##############################################################################################
##############################################################################################
##  ##                             Start Setup.                                         ##  ##
##############################################################################################
namespace eval wunderground {
## Edit logo to change the logo displayed at the start of the line                      ##  ##
  variable logo "\017\00304\002W\00304u\00307n\00308d\00311e\00312r\00304g\00307r\00308o\00311u\00312n\00304d\017"
## Edit textf to change the color/state of the text shown                               ##  ##
  variable textf "\017"
## Edit tagf to change the color/state of the Tags:                                     ##  ##
  variable tagf "\017\002"
## Edit weatherline, line1, line2, line3, line4 to change what is displayed             ##  ##
## weatherline is for the !weather trigger and line1-4 are for !forecast                ##  ##
## Valid items are: location weatherstation conditions tempf tempc tempfc feelsf        ##  ##
## feelsc feelsfc windgust windspeed winddirection sunset sunrise moon                  ##  ##
## day1 day2 day3 day4 day5 day6 day7 day8 day9 day10                                   ##  ##
## Do not remove any variables here! Just change them to "" to suppress display         ##  ##
  variable line1 "location weatherstation conditions tempfc feelsfc windspeed winddirection windgust sunset sunrise moon"
  variable line3 ""
  variable line2 "day1 day2 day3 day4 day5 day6 day7 day8 day9 day10"
  variable line4 ""
  variable weatherline "location weatherstation conditions tempfc feelsfc windspeed winddirection windgust sunset sunrise moon day1 day2 day3"
## Edit cmdchar to change the !trigger used to for this script                          ##  ##
  variable cmdchar "!"
##############################################################################################
##  ##                           End Setup.                                              ## ##
##############################################################################################
  llbind [curctx sock] pub "-" [string trimleft $wunderground::cmdchar]weather wunderground::tclservwe
  llbind [curctx sock] pub "-" [string trimleft $wunderground::cmdchar]wz wunderground::tclservwe
  llbind [curctx sock] pub "-" [string trimleft $wunderground::cmdchar]forecast wunderground::tclservfc
}

proc wunderground::tclservwe {n cname i msg} {
	if {[weatherenabled $cname] == 0} {return}
	set nick [tnda get "nick/$::netname([curctx sock])/$i"]
	set host "[tnda get "ident/$i"]@[tnda get "vhost/$::netname([curctx sock])/$i"]"
	set comd "weather"
	set hand ""
	set text $msg
	wunderground::main $comd $nick $host $hand $cname $text
}

proc wunderground::tclservfc {n cname i msg} {
	if {[weatherenabled $cname] == 0} {return}
	set nick [tnda get "nick/$::netname([curctx sock])/$i"]
	set host "[tnda get "ident/$i"]@[tnda get "vhost/$::netname([curctx sock])/$i"]"
	set comd "forecast"
	set hand ""
	set text $msg
	wunderground::main $comd $nick $host $hand $cname $text
}

proc wunderground::main {command nick host hand chan text} {
    set search [strip $text]
    set div ""; set moon ""; set sunset ""; set sunrise ""; set windspeed ""; set div ""
    set winddirection ""; set location ""; set weatherstation ""; set temperature ""; set tempfc ""
    set conditions ""; set feelslike ""; set feelsf ""; set feelsc ""; set city ""; set day ""
    set details ""; set forc ""; set count 1; set tempf ""; set state_name ""; set tempc ""
    set day1 ""; set day2 ""; set day3 ""; set day4 ""; set day5 ""; set state_name ""
    set day6 ""; set day7 ""; set day8 ""; set day9 ""; set day10 ""; set windgust ""; set feelsfc ""
    set wundergroundurl "/cgi-bin/findweather/hdfForecast?query=[urlencode $search]"
    set wundergroundsite "www.wunderground.com"
    if {"wz" == $command} {set command weather}
    if {[catch {set wundergroundsock [socket -async $wundergroundsite 80]} sockerr]} {
      return 0
    } else {
      puts $wundergroundsock "GET $wundergroundurl HTTP/1.0"
      puts $wundergroundsock "Host: $wundergroundsite"
      puts $wundergroundsock "User-Agent: Opera 9.6"
      puts $wundergroundsock ""
      flush $wundergroundsock
      while {![eof $wundergroundsock]} {
        set wundergroundvar " [gets $wundergroundsock] "
        regexp -nocase {"(current)_observation":} $wundergroundvar match div
        regexp -nocase {"(forecast)":} $wundergroundvar match div
        regexp -nocase {"(astronomy)":} $wundergroundvar match div
        if {[regexp -nocase {"city":"([^"]*)} $wundergroundvar match city]} {
          if {$city == "null"} {
            set city ""
          }
        } elseif {[regexp -nocase {"state_name":"([^"]*)} $wundergroundvar match state_name]} {
          if {$state_name == "null"} {
            set state_name ""
          }
          set location "${wunderground::tagf}Location: ${wunderground::textf}${city}, $state_name"
        } elseif {[regexp -nocase {"name":"([^"]*)} $wundergroundvar match weatherstation]} {
          set weatherstation "${wunderground::tagf}Station: ${wunderground::textf}${weatherstation}"
        } elseif {$forc == "" && [regexp -nocase {class="wx-unit">&nbsp;&deg;(.*?)<\/span>} $wundergroundvar match forc]} {
        } elseif {[regexp -nocase {"condition":"([^"]*)} $wundergroundvar match conditions]} {
          set conditions "${wunderground::tagf}Conditions: ${wunderground::textf}${conditions}"
        } elseif {$div == "current" && [regexp -nocase {"temperature":\s([^\,]*)} $wundergroundvar match temperature]} {
          set tempf "${wunderground::tagf}Temperature: ${wunderground::textf}[forc ${temperature} $forc F] deg F"
          set tempc "${wunderground::tagf}Temperature: ${wunderground::textf}[forc ${temperature} $forc C] deg C"
          set tempfc "${wunderground::tagf}Temperature: ${wunderground::textf}[forc ${temperature} $forc F] deg F/[forc ${temperature} $forc C] deg C"
        } elseif {$div == "current" && [regexp -nocase {"feelslike":\s([^\,]*)} $wundergroundvar match feelslike]} {
          set feelsf "${wunderground::tagf}Feels Like: ${wunderground::textf}[forc ${feelslike} $forc F] deg F"
          set feelsc "${wunderground::tagf}Feels Like: ${wunderground::textf}[forc ${feelslike} $forc C] deg C"
          set feelsfc "${wunderground::tagf}Feels Like: ${wunderground::textf}[forc ${feelslike} $forc F] deg F/[forc ${feelslike} $forc C] deg C" 
        } elseif {$div == "current" && [regexp -nocase {"wind_speed":\s?([^\,]*)} $wundergroundvar match windspeed]} {
          set windspeed "${wunderground::tagf}Wind speed: ${wunderground::textf}${windspeed}"
        } elseif {$div == "current" && [regexp -nocase {"wind_gust_speed":\s?([^\,]*)} $wundergroundvar match windgust]} {
          set windgust "${wunderground::tagf}Wind gust: ${wunderground::textf}${windgust}"
        } elseif {[regexp -nocase {"wind_dir":"([^"]*)} $wundergroundvar match winddirection]} {
          set winddirection "${wunderground::tagf}Wind Direction: ${wunderground::textf}${winddirection}"
        } elseif {[regexp -nocase {id="cc-sun-rise">(.*?)</span>\s?<span class="ampm">(.*?)</span>} $wundergroundvar match sunrise ampm]} {
          set sunrise "${wunderground::tagf}Sunrise: ${wunderground::textf}${sunrise}${ampm}"
        } elseif {[regexp -nocase {id="cc-sun-set">(.*?)</span> <span class="ampm">(.*?)</span>} $wundergroundvar match sunset ampm]} {
          set sunset "${wunderground::tagf}Sunset: ${wunderground::textf}${sunset}${ampm}"
        } elseif {[regexp -nocase {id="cc-moon-phase".*">(.+?)<\/span>} $wundergroundvar match moon]} {
          set moon "${wunderground::tagf}Moon: ${wunderground::textf}${moon}"
        } elseif {$div == "forecast" && $command == "weather"} {
          msg $chan $wunderground::logo ${wunderground::textf} [subst [regsub -all -nocase {(\S+)} $wunderground::weatherline {$\1}]]
          close $wundergroundsock
          return 0
        } elseif {[regexp -nocase {<div\sclass="fctDayDate">(.+)\,} $wundergroundvar match day]} {
          set day "${wunderground::tagf}${day}"
        } elseif {[string match "forecast" $div]} {
          if {[regexp -nocase {"weekday_short":\s?"([^"]*)} $wundergroundvar match day]} {
            set day "${wunderground::tagf}${day}:->"
          } elseif {[regexp -nocase {"high":\s([^\,]*)} $wundergroundvar match high]} {
            set high "${wunderground::tagf}High:${wunderground::textf}[forc $high $forc F] deg F/[forc $high $forc C] deg C"
          } elseif {[regexp -nocase {"low":\s([^\,]*)} $wundergroundvar match low]} {
            set low "${wunderground::tagf}low:${wunderground::textf}[forc $low $forc F] deg F/[forc $low $forc C] deg C"
          } elseif {[regexp -nocase {"condition":\s?"([^"]*)} $wundergroundvar match condition]} {
            set condition "${wunderground::tagf}Cond:${wunderground::textf}${condition}"
          } elseif {[regexp -nocase {"day":\s?\{} $wundergroundvar]} {
            set day${count} "$day $high $low $condition"
            incr count
          }
        } elseif {$div == "astronomy"} {
          if {$wunderground::line1 != ""} {
            msg $chan $wunderground::logo $wunderground::textf [subst [regsub -all -nocase {(\S+)} $wunderground::line1 {$\1}]]
          }
          if {$wunderground::line2 != ""} {
            msg $chan $wunderground::logo $wunderground::textf [subst [regsub -all -nocase {(\S+)} $wunderground::line2 {$\1}]]
          }
          if {$wunderground::line3 != ""} {
            msg $chan $wunderground::logo $wunderground::textf [subst [regsub -all -nocase {(\S+)} $wunderground::line3 {$\1}]]
          }
          if {$wunderground::line4 != ""} {
            msg $chan $wunderground::logo $wunderground::textf [subst [regsub -all -nocase {(\S+)} $wunderground::line4 {$\1}]]
          }
          close $wundergroundsock
          return 0
        }      
      }
    }
}
proc wunderground::forc {value fc forc} {
  if {[string equal -nocase $fc $forc]} {
    return $value
  } elseif {[string equal -nocase "f" $fc]} {
    if {[expr {(($value - 32) * 5)} == 0]} { return 0 }
    return [format "%.1f" [expr {(($value - 32) * 5) / 9}]]
  } elseif {[string equal -nocase "c" $fc]} {
    if {$value == 0} { return 32 }
    return [format "%.1f" [expr {(($value * 9) / 5) + 32}]]
  }
}
proc wunderground::striphtml {string} {
  return [string map {&quot; \" &lt; < &rt; >} [regsub -all {(<[^<^>]*>)} $string ""]]
}
proc wunderground::urlencode {string} {
  regsub -all {^\{|\}$} $string "" string
  return [subst [regsub -nocase -all {([^a-z0-9\+])} $string {%[format %x [scan "\\&" %c]]}]]
}
proc wunderground::strip {text} {
  regsub -all {\002|\031|\015|\037|\017|\003(\d{1,2})?(,\d{1,2})?} $text "" text
    return $text
}
proc wunderground::msg {chan logo textf text} {
  set text [textsplit $text 50]
  set counter 0
  while {$counter <= [llength $text]} {
    if {[lindex $text $counter] != ""} {
      % privmsg [tnda get "weatherserv/[curctx net]/ourid"] $chan "${logo} ${textf}[string map {\\\" \"} [lindex $text $counter]]"
    }
    incr counter
  }
}
proc wunderground::textsplit {text limit} {
  set text [split $text " "]
  set tokens [llength $text]
  set start 0
  set return ""
  while {[llength [lrange $text $start $tokens]] > $limit} {
    incr tokens -1
    if {[llength [lrange $text $start $tokens]] <= $limit} {
      lappend return [join [lrange $text $start $tokens]]
      set start [expr $tokens + 1]
      set tokens [llength $text]
    }
  }
  lappend return [join [lrange $text $start $tokens]]
  return $return
}
puts stdout "\002*Loaded* \00304\002W\00304u\00307n\00308d\00311e\00312r\00304g\00307r\00308o\00311u\00312n\00304d\017 \002by \
Ford_Lawnmower irc.GeekShed.net #Script-Help"
