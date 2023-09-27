if {![package vsatisfies [package provide Tcl] 8.6]} {return}
package ifneeded taboo 0.2 [list source [file join $dir taboo.tcl]]
