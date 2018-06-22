#!/usr/local/bin/env tclsh8.6

# OpenConf 2

proc blockwcb {blockname cb} {
	proc $blockname {args} "$cb \$args"
}

proc blocktnd {blockname} {
	set programme [list \
		[list set blockname $blockname] \
		[list tnda incr [format "openconf/%s/blocks" [ndcenc $blockname]] ] \
	]
	set blockpro {
		puts stdout $args
		tnda set [format "openconf/%s/n%s" [ndcenc $blockname] [tnda get [format "openconf/%s/blocks" [ndcenc $blockname] ] ]] [lindex $args end]
		if {[llength [lrange $args 0 end-1]] > 0} {tnda set [format "openconf/%s/hdr%s" [ndcenc $blockname] [tnda get [format "openconf/%s/blocks" [ndcenc $blockname] ] ]] [lrange $args 0 end-1]}
	}
	lappend programme $blockpro
	proc $blockname {args} [join $programme "\n"]
}

proc blocktndretfunc {blockname} {
	set programme [list \
		[list set blockname $blockname] \
		[list tnda incr [format "openconf/%s/blocks" [ndcenc $blockname]] ] \
	]
	set blockpro {
		puts stdout $args
		tnda set [format "openconf/%s/n%s" [ndcenc $blockname] [tnda get [format "openconf/%s/blocks" [ndcenc $blockname] ] ]] [lindex $args end]
		if {[llength [lrange $args 0 end-1]] > 0} {tnda set [format "openconf/%s/hdr%s" [ndcenc $blockname] [tnda get [format "openconf/%s/blocks" [ndcenc $blockname] ] ]] [lrange $args 0 end-1]}
	}
	lappend programme $blockpro
	return [join $programme "\n"]
} ;#for making aliases of block procs

proc postblock {blockname headlines block} {
	set blockname $blockname
	tnda incr [format "openconf/%s/blocks" [ndcenc $blockname]]
	tnda set [format "openconf/%s/n%s" [ndcenc $blockname] [tnda get [format "openconf/%s/blocks" [ndcenc $blockname] ] ]] $block
	if {[llength $headlines] > 0} {tnda set [format "openconf/%s/hdr%s" [ndcenc $blockname] [tnda get [format "openconf/%s/blocks" [ndcenc $blockname] ] ]] $headlines}
}

