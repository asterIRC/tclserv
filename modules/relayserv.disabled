# This is the fun part.

$::maintype sendUid $::sock($::cs(netname)) "R" "relay" "services." "services." 117 "Relay Services"
bind $::sock($::cs(netname)) msg 117 "reqlink" reqlinkmsg

proc allocuuid {relay} {
	# Allocate a UID and increment.
	if {""==[tnda get "uids/relays/$relay"]} {tnda set "uids/relays/$relay" 1} {tnda set "uids/relays/$relay" [expr {[tnda get "uids/relays/$::netname($::sock($::cs(netname)))/$relay"]+1}]}
	return [tnda get "uids/relays/$relay"]
}

proc reqlinkmsg {from msg} {
	return
	# do nothing for now
}
