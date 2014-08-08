sendUid $::sock "W" "weather" "services." "services." 57 "Weather Services"
foreach {chan is} [nda get "weather/regchan"] {
	if {1!=$is} {continue}
	putjoin $::sock 57 [::base64::decode [string map {[ /} $chan]] [nda get "regchan/$chan/ts"]
	tnda set "channels/$chan/ts" [nda get "regchan/$chan/ts"]
}
bind request "w" "-" weatherjoin
bind request "weather" "-" weatherjoin

proc weatherjoin {chan msg} {
	set ndacname [string map {/ [} [::base64::encode [string tolower $chan]]]
	putjoin $::sock 57 $chan [nda get "regchan/$ndacname/ts"]
	nda set "weather/regchan/$ndacname" 1
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
  bind pub "-" [string trimleft $wunderground::cmdchar]weather wunderground::tclservwe
  bind pub "-" [string trimleft $wunderground::cmdchar]wz wunderground::tclservwe
  bind pub "-" [string trimleft $wunderground::cmdchar]forecast wunderground::tclservfc
}

proc wunderground::tclservwe {cname msg} {
	set nick [tnda get "nick/[lindex $msg 0 0]"]
	set host "[tnda get "ident/[lindex $msg 0 0]"]@[tnda get "vhost/[lindex $msg 0 0]"]"
	set comd "weather"
	set hand ""
	set text [join [lindex $msg 1] " "]
	wunderground::main $comd $nick $host $hand $cname $text
}

proc wunderground::tclservfc {cname msg} {
	set nick [tnda get "nick/[lindex $msg 0 0]"]
	set host "[tnda get "ident/[lindex $msg 0 0]"]@[tnda get "vhost/[lindex $msg 0 0]"]"
	set comd "forecast"
	set hand ""
	set text [join [lindex $msg 1] " "]
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
      privmsg $::sock 57 $chan "${logo} ${textf}[string map {\\\" \"} [lindex $text $counter]]"
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
