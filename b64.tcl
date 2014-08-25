proc b64e {numb} {
        set b64 [split "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789\[\]" {}]

        set res ""
	while {$numb != 0} {
		append res [lindex $b64 [expr {$numb % 64}]]
		set numb [expr {$numb>>6}]
	}
	if {[string length $res] == 0} {
		set res "A"
	}
        return [string reverse $res]
}

proc b64d {numb} {
        set b64 "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789\[\]"
	set numb [string trimleft $numb "A"]
	set res 0
	for {set i 0} {$i<[string length $numb]} {incr i} {
		set new [string first [string index $numb $i] $b64]
		incr res [expr {$new<<(6*$i)}]
	}
        return $res
}

namespace eval unreal {
proc ::unreal::b64e {numb} {
        set b64 [split "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz{}" {}]

        set res ""
	while {$numb != 0} {
		append res [lindex $b64 [expr {$numb % 64}]]
		set numb [expr {$numb>>6}]
	}
	if {[string length $res] == 0} {
		set res "A"
	}
        return [string reverse $res]
}

proc ::unreal::b64d {numb} {
        set b64 "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz{}"
	set numb [string trimleft $numb "A"]
	set res 0
	for {set i 0} {$i<[string length $numb]} {incr i} {
		set new [string first [string index $numb $i] $b64]
		incr res [expr {$new<<(6*$i)}]
	}
        return $res
}
}

namespace eval ts6 {
proc ::ts6::b64e {numb} {
        set b64 [split "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" {}]

        set res ""
	while {$numb != 0} {
		append res [lindex $b64 [expr {$numb % 36}]]
		set numb [expr {$numb / 36}]
	}
	if {[string length $res] == 0} {
		set res "A"
	}
        return [string reverse $res]
}

proc ::ts6::b64d {numb} {
        set b64 "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	set numb [string trimleft $numb "A"]
	set res 0
	for {set i 0} {$i<[string length $numb]} {incr i} {
		set new [string first [string index $numb $i] $b64]
		incr res [expr {$new * (36 * $i)+1}]
	}
        return $res
}
}
