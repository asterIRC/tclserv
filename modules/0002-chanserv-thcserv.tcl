bind pub "-" "!lag" publag
bind pub "-" "!weed" pubweed
bind pub "-" "!coffee" pubcoffee
bind notc 77 "ping" lagresp

proc publag {cname msg} {
	set from [lindex $msg 0 0]
	privmsg $::sock 77 $from "\001PING [clock clicks -milliseconds] $cname \001"
}

proc pubcoffee {cname msg} {
	switch [expr {int(rand()*4)}] {
         0 {privmsg $::sock 77 $cname "\001ACTION hands [lindex $msg 1 0] a cup of espresso\001"}
         1 {privmsg $::sock 77 $cname "\001ACTION hands [lindex $msg 1 0] a cup of Latte\001"}
         2 {privmsg $::sock 77 $cname "\001ACTION hands [lindex $msg 1 0] a cup of instant coffee\001"}
         3 {privmsg $::sock 77 $cname "\001ACTION hands [lindex $msg 1 0] a cup of cappucino\001"}
        }
}

proc pubweed {cname msg} {
        set payload [lindex $msg 1 0]
        switch [expr {int(rand()*4)}] {
                0 {
                        privmsg $::sock 77 $cname "\001ACTION packs a bowl of nugs and hands a bong to $payload\001"
                }
                1 {
                        privmsg $::sock 77 $cname "\001ACTION rolls a joint and hands to $payload\001"
                }
                2 {
                        privmsg $::sock 77 $cname "\001ACTION fills the hookah with dried nugs and hands to $payload\001"
                }
                3 {
                        privmsg $::sock 77 $cname "\001ACTION passes $payload the vape pen\001"
                }
        }
}

proc lagresp {from msg} {
	set ms [lindex $msg 0 0]
	set chan [lindex $msg 0 1]
	set ni [tnda get "nick/$from"]
	privmsg $::sock 77 $chan "$ni, your lag is [expr {[clock clicks -milliseconds] - $ms}] milliseconds according to your client and our measurements."
}
