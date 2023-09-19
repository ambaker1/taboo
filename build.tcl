package require tin 1.0
tin import assert from tin
tin import tcltest
tin import flytrap
tin import new from vutil
set version 0.1
set config ""
dict set config VERSION $version
dict set config VUTIL_VERSION 1.1
dict set config NDLIST_VERSION 0.1
tin bake src build $config
tin bake doc/template/version.tin doc/template/version.tex $config

source build/taboo.tcl 
namespace import taboo::*

test new_table {
    # Create a new table, in two ways
} -body {
    ::taboo::table new tblObj
    new table tblObj2
    assert [$tblObj] eq [$tblObj2]
    $tblObj2 destroy
    $tblObj info
} -result {exists 1 shape {0 0} type table value {keyname key fieldname field keys {} fields {} data {}}}

test table_init_methods {
# Single entry or dictionary entry settings
} -body {
    new table tbl1 keys {1 2 3}
    new table tbl2 {keys {1 2 3}}
    assert [$tbl1] eq [$tbl2]
    unset tbl1 tbl2
} -result {}

test table_properties {
    # Verify that a table is created properly
} -body {
    # Create test table (overwrite)
    new table tblObj {
        1 {x 3.44 y 7.11 z 8.67}
        2 {x 4.61 y 1.81 z 7.63}
        3 {x 8.25 y 7.56 z 3.84}
        4 {x 5.20 y 6.78 z 1.11}
        5 {x 3.26 y 9.92 z 4.56}
    }
    assert [$tblObj] eq [$tblObj properties]
    $tblObj properties
} -result {keyname key fieldname field keys {1 2 3 4 5} fields {x y z} data {1 {x 3.44 y 7.11 z 8.67} 2 {x 4.61 y 1.81 z 7.63} 3 {x 8.25 y 7.56 z 3.84} 4 {x 5.20 y 6.78 z 1.11} 5 {x 3.26 y 9.92 z 4.56}}}

test copy_table_gc {
    # Test the copy functionality, and garbage collection
} -body {
    assert [llength [info class instances ::taboo::table]] == 1
    $tblObj --> tblCopy
    assert [llength [info class instances ::taboo::table]] == 2
    $tblObj --> tblCopy; # twice
    assert [llength [info class instances ::taboo::table]] == 2
    $tblCopy info
} -result [$tblObj info]

test trim_table {
    # Use the "define" method to trim a table
} -body {
    [$tblCopy define keys {1 2} fields x]
} -result {keyname key fieldname field keys {1 2} fields x data {1 {x 3.44} 2 {x 4.61}}}

test keyname {
    # Verify the default keyname
} -body {
    $tblObj keyname
} -result {key}

test fieldname {
    # Verify the default fieldname
} -body {
    $tblObj fieldname
} -result {field}

test key_field {
    # Get key/field with row/column ID
} -body {
assert [$tblObj key 0] eq 1
assert [$tblObj rid 1] == 0
assert [$tblObj key end] eq 5
assert [$tblObj rid 5] == 4
assert [$tblObj field 0] eq x
assert [$tblObj cid x] == 0
assert [$tblObj field end] eq z
assert [$tblObj cid z] == 2
} -result {}

test keys_fields {
    # Get keys/fields, using range notation and glob
} -body {
    assert [$tblObj keys] eq {1 2 3 4 5}
    assert [$tblObj keys 0:2] eq {1 2 3}
    assert [$tblObj fields] eq {x y z}
    assert [$tblObj fields 0:1] eq {x y}
    assert [$tblObj fields end] eq {z}
    assert [$tblObj fields : {[x-y]}] eq {x y}
} -result {}


test rename_keys {
    # Rename keys 
} -body {
    $tblObj --> tblCopy
    $tblCopy rename keys [lmap key [$tblCopy keys] {string cat K $key}]
    $tblCopy keys
} -result {K1 K2 K3 K4 K5}

test rename_keys2 {
    # Rename subset of keys
} -body {
    $tblObj --> tblCopy
    $tblCopy rename keys [$tblCopy keys 0:2] {K1 K2 K3}
    assert [$tblCopy keys] eq {K1 K2 K3 4 5}
    $tblCopy keys : K*
} -result {K1 K2 K3}

test rename_fields {
    # Rename fields
} -body {
    $tblObj --> tblCopy
    $tblCopy rename fields {a b c}; # Renames all fields
    $tblCopy rename fields {c a} {C A}; # Selected fields
    assert [$tblCopy fields] eq {A b C}
    $tblCopy fields : {[A-Z]}
} -result {A C}

test fedit_mkkey_remove {
    # Tests for fedit, mkkey and remove 
} -body {
    $tblObj --> tblCopy
    $tblCopy fedit record_ID {[string cat R @key]}
    $tblCopy mkkey record_ID
    $tblCopy remove fields key
    assert [$tblCopy keys] eq {R1 R2 R3 R4 R5}
    assert [$tblCopy fields] eq {x y z}
    assert [$tblCopy values] eq [$tblObj values]
    $tblCopy remove keys {*}[$tblCopy keys 1:end-1]
    assert [$tblCopy keys] eq {R1 R5}
} -result {}

test clear_clean_wipe {
    # tests for clear, clean, and wipe
} -body {
    # clear, clean, and wipe
    $tblCopy define keyname foo
    $tblCopy clear
    assert [$tblCopy shape] eq {0 3}
    $tblCopy clean
    assert [$tblCopy shape] eq {0 0}
    assert [$tblCopy keyname] eq foo
    $tblCopy wipe
    assert [$tblCopy keyname] eq key
}

test data_access {
    # Get dictionary form of the data
} -body {
    assert [$tblObj data] eq {1 {x 3.44 y 7.11 z 8.67} 2 {x 4.61 y 1.81 z 7.63} 3 {x 8.25 y 7.56 z 3.84} 4 {x 5.20 y 6.78 z 1.11} 5 {x 3.26 y 9.92 z 4.56}}
    assert [$tblObj data 3] eq {x 8.25 y 7.56 z 3.84}
} -result {}

test values {
    # Get matrix form of the data
} -body {
    $tblObj values
} -result {{3.44 7.11 8.67} {4.61 1.81 7.63} {8.25 7.56 3.84} {5.20 6.78 1.11} {3.26 9.92 4.56}}

test exists {
    # Verify that the "exists" method works
} -body {
    assert [$tblObj exists key 3]
    assert [$tblObj exists key 6] == 0
    assert [$tblObj exists field y]
    assert [$tblObj exists field foo] == 0
    assert [$tblObj exists value 3 y]
    $tblObj --> tblCopy
    $tblCopy set 3 y ""
    assert [$tblCopy exists value 3 y] == 0
} -result {}

test get {
    # Access values in table
} -body {
    $tblObj get 2 x
} -result 4.61

test set {
    # Check that you can set values
} -body {
    $tblObj --> tblCopy
    $tblCopy set 2 x foo
    $tblCopy get 2 x
} -result foo

test filler {
    # Get filler value when value is missing
} -body {
    $tblObj --> tblCopy
    $tblObj set 2 x ""; # delete
    assert ![$tblObj exists value 2 x]
    assert [$tblObj get 2 x] eq ""
    $tblObj get 2 x 0.0; # with filler
} -result 0.0

test rget {
    # Get row vector
} -body {
    $tblObj rget 2
} -result {4.61 1.81 7.63}

test rset_vector {
    # Set row with vector
} -body {
    $tblObj --> tblCopy
    $tblCopy rset 2 {foo bar foo}
    $tblCopy rget 2
} -result {foo bar foo}

test rset_delete {
    # Delete a row 
} -body {
    $tblCopy rset 2 ""
    assert [$tblCopy rget 2] eq {{} {} {}}
    $tblCopy exists value 2 x
} -result 0

test rset_scalar {
    # Set to a scalar
} -body {
    $tblCopy rset 2 foo
    $tblCopy rget 2
} -result {foo foo foo}

test cget {
    # Get a column vector
} -body {   
    $tblObj cget x
} -result {3.44 4.61 8.25 5.20 3.26}

test cset_vector {
    # Set column with vector
} -body {
    $tblObj --> tblCopy
    $tblCopy cset x {foo bar foo bar foo}
    $tblCopy cget x
} -result {foo bar foo bar foo}

test cset_delete {
    # Delete column
} -body {
$tblCopy cset x ""
assert [$tblCopy cget x] eq {{} {} {} {} {}}
assert [$tblCopy exists value 2 x] == 0
} -result {}

test cset_scalar {
    # Set column to scalar
} -body {
$tblCopy cset x foo
assert [$tblCopy cget x] eq {foo foo foo foo foo}
} -result {}

test mget_values {
    # Get all values
} -body {
    assert [$tblObj values] eq [$tblObj mget [$tblObj keys] [$tblObj fields]]
}

test mget {
    # Get subset of table
} -body {
    set submat [$tblObj mget {1 2 3} {x z}]
} -result {{3.44 8.67} {4.61 7.63} {8.25 3.84}}

test mset {
    # Modify portion of table
} -body {
    set submat2 {{foo1 bar1} {foo2 bar2} {foo3 bar3}}
    $tblObj --> tblCopy
    $tblCopy mset {1 2 3} {x z} $submat2
    $tblCopy mget {1 2 3} {x z}
} -result {{foo1 bar1} {foo2 bar2} {foo3 bar3}}

test shape {
    # Get shape of table (and height and width)
} -body {
    # shape
    assert [$tblObj shape] eq {5 3}
    assert [$tblObj shape 0] == 5
    assert [$tblObj shape 1] == 3
    # height
    assert [$tblObj height] == 5
    # width
    assert [$tblObj width] == 3
} -result {}


test set_newfields {
    # Create new fields with set
} -body {
    $tblObj --> tblCopy
    $tblCopy set 1 x 2.00 y 5.00 foo bar
    $tblCopy data 1
} -result {x 2.00 y 5.00 z 8.67 foo bar}

test add_with {
    # Add fields and edit through "with"
} -body {
    set a 20.0; # external variable in "with" and "fedit"
    $tblObj --> tblCopy
    $tblCopy add fields q
    $tblCopy with {
        set q [expr {$x*2 + $a}]; # modify field value
    }
    $tblCopy cget q 
} -result {26.88 29.22 36.5 30.4 26.52}


test add_sort {
    # Add keys and sort
} -body {
# Add keys, and sort keys
$tblCopy add keys 0 7 12 3 8 2 1
assert [$tblCopy keys] eq {1 2 3 4 5 0 7 12 8}
$tblCopy sort -integer 
assert [$tblCopy keys] eq {0 1 2 3 4 5 7 8 12}
} -result {}

test rmove_rswap {
    # Move and swap rows, back to original location
} -body {
    $tblObj --> tblCopy
    $tblCopy rmove 1 end-1
    assert [$tblCopy keys] eq {2 3 4 1 5}
    $tblCopy rswap 1 5
    assert [$tblCopy keys] eq {2 3 4 5 1}
    $tblCopy rmove [$tblCopy key end] 0
    assert [$tblCopy] eq [$tblObj]
} -result {}


test cmove_cswap {
# Move and swap columns
} -body {
$tblCopy cmove x end
assert [$tblCopy fields] eq {y z x}
$tblCopy cmove z end
assert [$tblCopy fields] eq {y x z}
$tblCopy cswap x y
assert [$tblCopy fields] eq {x y z}
assert [$tblCopy] eq [$tblObj]
} -result {}

test insert {
    # Insert keys/fields
} -body {
$tblCopy insert keys 2 foo bar
assert [$tblCopy keys] eq {1 2 foo bar 3 4 5}
$tblCopy insert fields end+1 foo bar
assert [$tblCopy fields] eq {x y z foo bar}
assert [catch {$tblCopy insert fields 0 foo}]; # cannot insert existing field
assert [catch {$tblCopy insert fields 0 bah bah}]; # Cannot have duplicates
} -result {}

test expr_fedit {
    # Validate field expressions
} -body {
# Expr and fedit
$tblObj --> tblCopy
assert [$tblCopy expr {@x*2 + $a}] eq {26.88 29.22 36.5 30.4 26.52}
$tblCopy fedit q {@x*2 + $a}
assert [$tblCopy cget q] eq {26.88 29.22 36.5 30.4 26.52}
# Access to key values in "expr"
assert [$tblCopy expr {@key}] eq [$tblCopy keys]
} -result {}

test query {
    # Query keys matching a field expression
} -body {
$tblObj query {@x > 3.0 && @y > 7.0}
} -result {1 3 5}

test filter {
    # Filter a table using query results
} -body {
$tblObj --> tblCopy
$tblCopy filter {@x > 3.0 && @y > 7.0}
assert [$tblCopy keys] eq {1 3 5}
} -result {}

test search_sort {
    # Searching and sorting
} -body {
$tblObj --> tblCopy
assert [$tblCopy search -real x 8.25] == 3; # returns first matching key
$tblCopy sort -real x; # sorts in-place
assert [$tblCopy keys] eq {5 1 2 4 3}
assert [$tblCopy cget x] eq {3.26 3.44 4.61 5.20 8.25}
assert [$tblCopy search -sorted -bisect -real x 5.0] == 2
$tblCopy search -inline -real x 8.25; # filters with search criteria
assert [$tblCopy keys] == 3; # returns first matching key
} -result {}

test merge {
    # Create a new table, and merge the data into a copy of test table
} -body {
    new table newTable data {1 {x 5.00 q 6.34}}
    $tblObj --> tblCopy
    $newTable set 1 x 5.00 q 6.34
    $tblCopy merge $newTable
    $newTable destroy; # clean up
    $tblCopy properties 
} -result {keyname key fieldname field keys {1 2 3 4 5} fields {x y z q} data {1 {x 5.00 y 7.11 z 8.67 q 6.34} 2 {x 4.61 y 1.81 z 7.63} 3 {x 8.25 y 7.56 z 3.84} 4 {x 5.20 y 6.78 z 1.11} 5 {x 3.26 y 9.92 z 4.56}}}

test transpose {
    # Transpose the table
} -body {
$tblObj --> tblCopy
$tblCopy transpose
assert [$tblCopy keyname] eq [$tblObj fieldname]
assert [$tblCopy fieldname] eq [$tblObj keyname]
assert [$tblCopy keys] eq [$tblObj fields]
assert [$tblCopy fields] eq [$tblObj keys]
assert [transpose [$tblCopy values]] eq [$tblObj values]
$tblCopy transpose
assert [$tblCopy] eq [$tblObj]
} -result {}

# Check number of failed tests
set nFailed $::tcltest::numTests(Failed)

# Clean up and report on tests
cleanupTests

# If tests failed, return error
if {$nFailed > 0} {
    error "$nFailed tests failed"
}
exit

# Tests passed, copy build files to main folder and install
file copy -force {*}[glob -directory build *] [pwd]

exec tclsh install.tcl

# Verify installation
tin forget taboo
tin clear
tin import taboo -exact $version
