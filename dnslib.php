<?php

# Following function is jaffacake's own work.
# GPLv3 blablabla

define("DNSBL",0x1);
define("NORMLOOKUP",0x2);
define("V6LOOKUP",0x4);
define("REVLOOKUP",0x8);

function dig($name, $qtype, $dnsbl = ".", $isdnsbl = false) {
	$type = 0;
	if ($isdnsbl >= 1) {
		$isipv6 = (strpos($name, ":") !== FALSE);
		if ($dnsbl == ".") return false;
		if ($isipv6) {
			$type = $type | V6LOOKUP;
		}
		$type = $type | DNSBL;
		$type = $type | REVLOOKUP;
	}
	if (!$isdnsbl) $type = NORMLOOKUP;
	if ($qtype == "PTR") {
		$isipv6 = (strpos($name, ":") !== FALSE);
		if ($isipv6) {
			$type = $type | REVLOOKUP;
		}
		$type = $type | REVLOOKUP;
	}
	if ($type & 0x8) {
		if ($type & V6LOOKUP) $rdns = implode(".",str_split(strrev(implode("",explode(":",$name)))));
		else $rdns = implode(".",array_reverse(explode(".",$name)));
		$dname = $rdns;
		if (($type & 0x4) and ($type & 0x1)) $dname .= ".ip6.arpa";
		else if ($type & 0x2) $dname .= ".in-addr.arpa";
		else {
			$dname .= ".".$dnsbl;
		}
	} else $dname = $name;
	$dnsname = "dig +short +time=1 ".escapeshellarg($dname)." ".escapeshellarg(strtoupper($qtype))." | tail -n 1";
	$out = shell_exec($dnsname);
	if ($type & 0x1) {
		$num = explode(".",$out);
		$numreply = 0;
		$numreply = $numreply + $num[3];
		$numreply = $numreply + ($num[2] << 8);
		$numreply = $numreply + ($num[1] << 16);
		// We'll return the pton result :P
		return $numreply;
	}
	return $out;
}

print($argv[5]. " " .dig($argv[1], $argv[2], $argv[3], $argv[4]). "\n");
