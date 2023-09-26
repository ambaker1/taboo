package require tin 1.0
tin depend vutil 1.1.1
tin depend ndlist 0.1
set dir [tin mkdir -force taboo 0.1]
file copy pkgIndex.tcl taboo.tcl README.md LICENSE $dir
