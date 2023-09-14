package require tin 1.0
tin import assert from tin
tin import tcltest
tin import flytrap
set version 0.1
set config ""
dict set config VERSION $version
dict set config VUTIL_VERSION 1.1
dict set config NDLIST_VERSION 0.1
tin bake src build $config
tin bake doc/template/version.tin doc/template/version.tex $config

source build/taboo.tcl 
namespace import taboo::*

exit

# Check number of failed tests
set nFailed $::tcltest::numTests(Failed)

# Clean up and report on tests
cleanupTests

# If tests failed, return error
if {$nFailed > 0} {
    error "$nFailed tests failed"
}
# Tests passed, copy build files to main folder and install
file copy -force {*}[glob -directory build *] [pwd]

exec tclsh install.tcl

# Verify installation
tin forget taboo
tin clear
tin import taboo -exact $version
