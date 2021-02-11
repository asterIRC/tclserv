# This whole didgeridoo is legacy code and I need to kill it with fire!

package require base64

proc ndaenc {n} {
	return [string map {/ [} [::base64::encode [string tolower $n]]]
}

proc ndadec {n} {
	return [::base64::decode [string map {[ /} $n]]
}

proc ndcenc {n} {
	return [string map {/ [} [::base64::encode $n]]
}

proc ndcdec {n} {
	return [::base64::decode [string map {[ /} $n]]
}

set nd [set tnd [list]]

namespace eval nda {
	proc ::nda::get {path} {
		#puts stdout "invoked with $path"
		global nd
		::set parr [split $path "/"]
		if {[lindex $parr 0] == ""} {
			return ""
		}
		::set pathe [lrange $parr 1 end]
		if {[info exists nd] && ![catch {dict get $nd {*}$parr} eee]} {return $eee} {return ""}
	}

	proc ::nda::set {path val} {
		#puts stdout "invoked with $path"
		global nd
		::set parr [split $path "/"]
		if {[lindex $parr 0] == ""} {
			return ""
		}
		return [dict set nd {*}$parr $val]
	}

	proc ::nda::unset {path} {
		#puts stdout "invoked with $path"
		global nd
		::set parr [split $path "/"]
		if {[lindex $parr 0] == ""} {
			return ""
		}
		if {[info exists nd] && ![catch {dict unset nd {*}$parr} eee]} {return $eee} {return ""}
	}

	proc ::nda::incr {path} {
		#puts stdout "invoked with $path"
		global nd
		::set parr [split $path "/"]
		if {[lindex $parr 0] == ""} {
			return ""
		}
		set orig [::nda::get $path]
		if {[string is integer $orig]} {
			::nda::set $path [expr $orig+$inc]
		} {
			::nda::set $path $inc
		}
	}

	namespace export *
	namespace ensemble create
}

# alt API:
namespace eval dbase {
	proc ::dbase::get {args} {
		global nd
		if {[info exists nd] && ![catch {dict get $nd {*}$args} eee]} {return $eee} {return ""}
	}

	proc ::dbase::set {args} {
		global nd
		if {[lindex $args 1] == ""} {
			return ""
		}
		return [dict set nd {*}$args]
	}

	proc ::dbase::lappend {args} {
		global nd
		if {[lindex $args 1] == ""} {
			return ""
		}
		::set orig [::dbase::get {*}[lrange $args 0 end-1]]
		::lappend orig [lindex $args end]
		return [dict set nd {*}[lrange $args 0 end-1] $orig]
	}

	proc ::dbase::unset {args} {
		global nd
		return [dict unset nd {*}$args]
	}

	namespace export *
	namespace ensemble create
}

namespace eval tnda {
	proc ::tnda::get {path} {
		#puts stdout "invoked with $path"
		global tnd
		::set parr [split $path "/"]
		if {[lindex $parr 0] == ""} {
			return ""
		}
		#::set pathe [lrange $parr 1 end]
		if {[info exists tnd] && ![catch {dict get $tnd {*}$parr} eee]} {return $eee} {return ""}
	}
	proc ::tnda::set {path val} {
		#puts stdout "invoked with $path"
		global tnd
		::set parr [split $path "/"]
		if {[lindex $parr 0] == ""} {
			return ""
		}
		#::set pathe [lrange $parr 1 end]
		return [dict set tnd {*}$parr $val]
	}

	proc ::tnda::unset {path} {
		#puts stdout "invoked with $path"
		global tnd
		::set parr [split $path "/"]
		if {[lindex $parr 0] == ""} {
			return ""
		}
		if {[info exists tnd] && ![catch {dict unset tnd {*}$parr} eee]} {return $eee} {return ""}
	}

	proc ::tnda::incr {path {inc 1}} {
		#puts stdout "invoked with $path"
		global tnd
		::set parr [split $path "/"]
		if {[lindex $parr 0] == ""} {
			return ""
		}
		::set orig [::tnda::get $path]
		if {[string is integer $orig]} {
			::tnda::set $path [expr $orig+$inc]
		} {
			::tnda::set $path $inc
		}
	}

	namespace export *
	namespace ensemble create
}

namespace eval cdbase {
	proc ::cdbase::get {args} {
		global tnd
		if {[info exists tnd] && ![catch {dict get $tnd {*}$args} eee]} {return $eee} {return ""}
	}

	proc ::cdbase::set {args} {
		global tnd
		if {[lindex $args 1] == ""} {
			return ""
		}
		return [dict set tnd {*}$args]
	}

	proc ::cdbase::lappend {args} {
		global tnd
		if {[lindex $args 1] == ""} {
			return ""
		}
		::set orig [::cdbase::get {*}[lrange $args 0 end-1]]
		::lappend orig [lindex $args end]
		return [dict set tnd {*}[lrange $args 0 end-1] $orig]
	}

	proc ::cdbase::unset {args} {
		global tnd
		return [dict unset tnd {*}$args]
	}

	namespace export *
	namespace ensemble create
}

proc tdb {args} {set l [list cdbase]; foreach {i} $args {lappend l $i}; $l}

proc gettext {stringname args} {
	gettext.i18n $stringname en $args
}

proc gettext.i18n {stringname language arg} {
	if {"" == [set out [format [dict get $::gettext [format "%s.%s" $language $stringname]] {*}$arg]]} {
		# default to the English locale if we don't know
		set out [format [dict get $::gettext [format "%s.%s" en $stringname]] {*}$arg]
	}
	return $out
}
