#! /usr/bin/env tclsh

# Yea, another password manager. "Password--" it's called, because it's entirely stateless.
# Just takes a master password, a protocol, and a site, and spits out a password.

# 
# This file is part of the password-- distribution (https://github.com/xxxx or http://xxx.github.io).
# Copyright (c) 2016 Ellenor Malik, legal name "Jack Dennis Johnson". All rights reserved.
# 
# This file is free software - you may distribute it under the M.I.T. license.
# If included with GPL'd software, this file is instead available under the terms of
# the GPL, of the version relevant to the whole.
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

package require Expect
package require base64
package require aes
package require sha256

proc pad {origlen {mult 16}} {
 set next [expr $origlen/$mult+1]
 set nextl [expr ${next}*${mult}]
 set padlen [expr ${nextl}-${origlen}]
 return $padlen
}

proc encrypt {site pass} {
 set inited [::aes::Init ecb [::sha2::sha256 -bin -- [join [list $site $pass] ":"]] "aaaaaaaaaaaaaaaa"]
 set padout [pad [string length $site]]
 append site [string repeat \0 $padout]
 set encd [::aes::Encrypt $inited [::sha2::sha256 -bin -- $pass]]
 ::aes::Final $inited
 return [encrypt-v1 $site $encd]
}

proc encrypt-v1 {site pass} {
 set inited [::aes::Init ecb [::sha2::sha256 -bin -- $pass] "aaaaaaaaaaaaaaaa"]
 set padout [pad [string length $site]]
 append site [string repeat \0 $padout]
 set encd [::aes::Encrypt $inited $site]
 ::aes::Final $inited
 return $encd
}

proc pwhash.SSHA256 {pass {site "a"}} {
 return [format "SSHA256/%s/%s" $site [string map {/ - + _ = {}} [::base64::encode -maxlen 0 -wrapchar "" [encrypt $site $pass]]]]
}

proc pwhash {args} {
 if {[llength $args] == 1} {lassign $args pass; set alg SSHA256; set salt a}
 if {[llength $args] == 2} {lassign $args pass salt; set alg SSHA256}
 if {[llength $args] == 3} {lassign $args alg pass salt}
 return [pwhash.$alg $pass $salt]
}
