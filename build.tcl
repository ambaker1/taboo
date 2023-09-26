package require tin 1.0
tin import assert from tin
tin import tcltest
tin import flytrap
tin import new from vutil
set version 0.1
set config ""
dict set config VERSION $version
dict set config VUTIL_VERSION 1.1.1
dict set config NDLIST_VERSION 0.1
tin bake src build $config
tin bake doc/template/version.tin doc/template/version.tex $config

source build/taboo.tcl 
namespace import taboo::*

# add           # Add keys/fields to table
# cget          # Get column of data
# clean         # Clean table of keys/fields with no data
# clear         # Clear table data, keeping field names
# cset          # Set an entire column
# data          # Get dictionary-style data of table
# define        # Define table properties
# exists        # Check if keys/fields/values exist
# expr          # Perform column operation on table
# fedit         # Create field with expr.
# fields        # Get list of fields given column index and glob patterns 
# filter        # Filter table given expr
# find          # Get row/column ID given key/field
# get           # Get single values from table
# height        # Get height of table (number of keys)
# insert        # Insert keys/fields into table
# keyname       # Get keyname
# keys          # Get list of keys given row index and glob patterns 
# merge         # Merge table data into current table
# mget          # Get matrix of data from table
# mkkey         # Make a field the key
# move          # Move rows/columns in table
# mset          # Set a matrix of data in table
# query         # Query keys that meet table expr.
# remove        # Remove keys/fields from table
# rename        # Rename keys/fields in table
# rget          # Get row of data in table
# rset          # Set rows of data in table
# search        # Search for keys meeting lsearch criteria in table
# set           # Set single values in table
# sort          # Sort table using lsort
# swap          # Swap rows/columns in table
# transpose     # Transpose table
# values        # Get table values
# width         # Get width of table (number of fields)
# wipe          # Wipe table (resets to fresh table)
# with          # Loop through tabular data

test new_table1 {
    # Blank table (exists, but empty)
} -body {
    ::taboo::table new tblObj
    $tblObj info
} -result {exists 1 height 0 type table value {key {}} width 0}

test new_table2 {
    # Create a table with data
} -body {
    # Create test table (overwrite)
    new table tblObj {
        key {1 2 3 4 5} 
        x {3.44 4.61 8.25 5.20 3.26}
        y {7.11 1.81 7.56 6.78 9.92}
        z {8.67 7.63 3.84 1.11 4.56}
    }
    $tblObj
} -result {key {1 2 3 4 5} x {3.44 4.61 8.25 5.20 3.26} y {7.11 1.81 7.56 6.78 9.92} z {8.67 7.63 3.84 1.11 4.56}}

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
    # Use the "define" method to trim a table, and verify that it returns object
} -body {
    [[$tblCopy define keys {1 2}] define fields {x}]
} -result {key {1 2} x {3.44 4.61}}

test keyname {
    # Verify the default keyname
} -body {
    $tblObj keyname
} -result {key}

test keys_fields {
    # Get keys/fields, using range notation and glob
} -body {
    assert [$tblObj keys] eq {1 2 3 4 5}
    assert [$tblObj keys 0:2] eq {1 2 3}
    assert [$tblObj fields] eq {x y z}
    assert [$tblObj fields 0:1] eq {x y}
    assert [$tblObj fields end] eq {z}
} -result {}

test find {
    # Get key/field with row/column ID
} -body {
    assert [$tblObj keys 0*] eq 1
    assert [$tblObj find key 1] == 0
    assert [$tblObj keys end*] eq 5
    assert [$tblObj find key 5] == 4
    assert [$tblObj fields 0*] eq x
    assert [$tblObj find field x] == 0
    assert [$tblObj fields end*] eq z
    assert [$tblObj find field z] == 2
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
    $tblCopy search -all K*
} -result {K1 K2 K3}

test rename_fields {
    # Rename fields
} -body {
    $tblObj --> tblCopy
    $tblCopy rename fields {a b c}; # Renames all fields
    $tblCopy rename fields {c a} {C A}; # Selected fields
    $tblCopy fields
} -result {A b C}

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
    $tblCopy keyname foo
    $tblCopy clear
    assert [$tblCopy height] == 0
    assert [$tblCopy width] == 3
    $tblCopy clean
    assert [$tblCopy height] == 0
    assert [$tblCopy width] == 0
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
    $tblCopy set 2 x ""; # delete
    assert ![$tblCopy exists value 2 x]
    assert [$tblCopy get 2 x] eq ""
    $tblCopy get 2 x 0.0; # with filler
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

test height_width {
    # Get height and width
} -body {
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

test move_swap {
    # Move and swap rows, back to original location
} -body {
    $tblObj --> tblCopy
    $tblCopy move key 1 end-1
    assert [$tblCopy keys] eq {2 3 4 1 5}
    $tblCopy swap keys 1 5
    assert [$tblCopy keys] eq {2 3 4 5 1}
    $tblCopy move key [$tblCopy keys end*] 0
    assert [$tblCopy] eq [$tblObj]
    
    $tblCopy move field x end
    assert [$tblCopy fields] eq {y z x}
    $tblCopy move field z end
    assert [$tblCopy fields] eq {y x z}
    $tblCopy swap fields x y
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
    new table newTable
    $tblObj --> tblCopy
    $newTable set 1 x 5.00 q 6.34
    $tblCopy merge $newTable
    $newTable destroy; # clean up
    $tblCopy
} -result {key {1 2 3 4 5} x {5.00 4.61 8.25 5.20 3.26} y {7.11 1.81 7.56 6.78 9.92} z {8.67 7.63 3.84 1.11 4.56} q {6.34 {} {} {} {}}}

test transpose {
    # Transpose the table
} -body {
    $tblObj --> tblCopy
    $tblCopy transpose
    assert [$tblCopy keys] eq [$tblObj fields]
    assert [$tblCopy fields] eq [$tblObj keys]
    assert [::ndlist::ntranspose 2D [$tblCopy values]] eq [$tblObj values]
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

# Tests passed, copy build files to main folder and install
file copy -force {*}[glob -directory build *] [pwd]

exec tclsh install.tcl

# Verify installation
tin forget taboo
tin clear
tin import taboo -exact $version
