# taboo.tcl
################################################################################
# Constant-time tabular data format, using TclOO and Tcl dictionaries.
# Adds "table" datatype using the "vutil::type" framework.

# Copyright (C) 2023 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Required packages
package require vutil 1.1.1; # For object variable framework
package require ndlist 0.1; # For indexing

# Create namespace
namespace eval ::taboo {
    namespace export table
}

# table --
#
# Create a table (calls ::taboo::tblobj)
#
# Syntax:
# table $refName <$value>
#
# Arguments:
# refName:      Variable name for garbage collection.
# value:        Value of table.

proc ::taboo::table {refName {value ""}} {
    tailcall ::taboo::tblobj new $refName $value
}

# ::taboo::tblobj --
#
# Object variable class for tables. Not exported.
#
# Syntax:
# ::vutil::new table $refName <$value>
#
# Arguments:
# refName       Variable name for garbage collection
# value         Value of table

::vutil::type create table ::taboo::tblobj {
# Additional variables used in all methods
variable keyname keys keymap fields fieldmap datamap

# new table $refName <$value>
# 
# Modify to call define instead of "SetValue"
# Table always exists, but may be empty (height 0 width 0)

constructor {refName {value ""}} {
    my wipe; # initialize internal variables
    # Call standard constructor method
    next $refName $value
}

# SetValue --
# 
# Modify to call wipe and define. Set (value) to blank (not used internally)

method SetValue {value} {
    # Verify that input is valid
    my ValidateValue $value
    # Wipe all existing table data
    set (value) ""; # field not used internally.
    my wipe
    # Null case (empty table)
    if {[dict size $value] == 0} {
        return [self]
    }
    # Get keyname, keys, and fields
    my add fields {*}[lassign [dict keys $value] keyname]
    my add keys {*}[dict get $value $keyname]
    # Assign values
    foreach field $fields {
        my cset $field [dict get $value $field]
    }
    return [self]
}

# SetObject --
# 
# Modify to call wipe and SetValue. Resets (value) to blank.

method SetObject {objName} {
    next $objName
    my wipe
    my SetValue $(value)
    set (value) ""; # reset (value) to blank. (not used internally)
    return [self]
}

# GetObject --
#
# Modify to set the value field to result of GetValue method

method GetObject {} {
    set info [next]; # Get info dictionary from superclass method
    dict set info value [my GetValue]
    return $info
}

# UpdateFields --
# 
# Modify to update the height and width fields

method UpdateFields {} {
    set (height) [my height]
    set (width) [my width]
    next
}

# GetValue --
#
# Gets string representation of tabular data format.
# This representation is not used internally. 

method GetValue {} {
    # Create column-oriented dictionary for table
    set value [dict create $keyname $keys]
    foreach field $fields {
        dict set value $field [my cget $field]
    }
    return $value
}

# ValidateValue --
#
# Validate input before overwriting table.

method ValidateValue {value} {
    # Ensure that value is a dictionary
    if {[catch {dict size $value} size]} {
        return -code error "table value must be dictionary"
    }
    # Null case (empty table)
    if {$size == 0} {
        return; # Blank
    }
    # Check uniqueness of key list
    set header [dict keys $value]
    set keylist [dict get $value [lindex $header 0]]
    if {![my IsUniqueList $keylist]} {
        return -code error "key list must be unique"
    }
    # Check height of field columns
    set height [llength $keylist]
    dict for {field column} $value {
        if {[llength $column] != $height} {
            return -code error "inconsistent column heights"
        }
    }
    return
}

# my IsUniqueList --
#
# Private method for checking uniqueness of key/field inputs.
#
# Syntax:
# my IsUniqueList $list
#
# Arguments:
# list:             List to check for uniqueness

method IsUniqueList {list} {
    set map ""
    foreach item $list {
        if {[dict exists $map $item]} {
            return 0
        }
        dict set map $item ""
    }
    return 1
}
    
# $tblObj wipe --
#
# Reset table entirely to defaults

method wipe {} {
    my clear
    set fields ""; # Ordered list of fields
    set fieldmap ""; # Dictionary of fields and indices
    set keyname key; # Name of keys (first column name)
    return [self]
}

# $tblObj clear --
#
# Clear out all data in table (keeps keyname and fields/fieldmap)

method clear {} {
    set datamap ""; # Double-nested dictionary of table data
    set keys ""; # Ordered list of keys
    set keymap ""; # dictionary of keys and indices
    return [self]
}

# Table property access/modification
################################################################################

# $tblObj keyname --
# 
# Access/modify keyname of table.
# Returns self if modifying.
#
# Syntax:
# $tblObj keyname <$value>
#
# Arguments:
# value:        Value to set keyname to. Blank to just return keyname.
#               Must not be a field name.

method keyname {{value ""}} {
    # Access
    if {$value eq ""} {
        return $keyname
    }
    # Modify
    if {[my exists field $value]} {
        return -code error "cannot set keyname, found in fields"
    }
    set keyname $value
    return [self]
}

# $tblObj keys --
# 
# Access table keys with optional ndlist index pattern
#
# Syntax:
# $tblObj keys <$i>
#
# Arguments:
# i:            Index pattern. Default ":" for all keys

method keys {{i :}} {
    if {$i eq ":"} {
        return $keys
    }
    ::ndlist::nget $keys $i
}

# $tblObj fields --
# 
# Access table fields with optional ndlist index pattern
#
# Syntax:
# $tblObj fields <$j>
# 
# Arguments:
# j:            Index pattern. Default ":" for all fields

method fields {{j :}} {
    # Null case
    if {$j eq ":"} {
        return $fields
    }
    ::ndlist::nget $fields $j
}

# $tblObj values --
#
# Get matrix of values (alias for mget with all keys and fields)
#
# Syntax:
# $tblObj values <$filler>
#
# Arguments:
# filler:           Filler for missing values. Default ""

method values {{filler ""}} {
    my mget $keys $fields $filler
}

# $tblObj data --
#
# Access the raw, unordered data of the table.
#
# Syntax:
# $tblObj data <$key>
#
# Arguments:
# key:          Key to get row data for. Default returns double-nested dict.

method data {args} {
    if {[llength $args] == 0} {
        return $datamap
    } elseif {[llength $args] == 1} {  
        set key [lindex $args 0]
        if {[my exists key $key]} {
            return [dict get $datamap $key]
        } else {
            return -code error "key \"$key\" not found in table"
        }
    } else {
        return -code error \
                "wrong # args: should be \"[self] data ?key?\""
    }
}

# $tblObj height --
#
# Number of keys in table

method height {} {
    llength $keys
}

# $tblObj width --
#
# Number of fields in table

method width {} {
    llength $fields
}

# $tblObj exists --
#
# Check if key/field or key/field pairing exists, using hashmaps
#
# Syntax:
# $tblObj exists key $key
# $tblObj exists field $field
# $tblObj exists value $key $field
# 
# Arguments:
# key:          Key to look up
# field:        Field to look up

method exists {type args} {
    switch $type {
        key { # $tblObj exists key $key
            if {[llength $args] != 1} {
                return -code error "wrong # args: should be\
                        \"[self] exists key name\""
            }
            return [dict exists $keymap [lindex $args 0]]
        }
        field { # $tblObj exists field $field
            if {[llength $args] != 1} {
                return -code error "wrong # args: should be\
                        \"[self] exists field name\""
            }
            return [dict exists $fieldmap [lindex $args 0]]
        }
        value { # $tblObj exists value $key $field
            if {[llength $args] != 2} {
                return -code error "wrong # args: should be\
                        \"[self] exists value key field\""
            }
            return [dict exists $datamap {*}$args]
        }
        default {
            return -code error "unknown option \"$type\": want\
                    \"key\", \"field\" or \"value\""
        }
    }; # end switch type
}

# $tblObj find --
#
# Find index of key/field.
#
# Syntax:
# $tblObj find key $key
# $tblObj find field $field
#
# Arguments:
# key/field:        Key/field to look up

method find {type value} {
    switch $type {
        key { # $tblObj find key $key
            set key $value
            if {[my exists key $key]} {
                return [dict get $keymap $key]
            } else {
                return -code error "key \"$key\" not found in table"
            }
        }
        field { # $tblObj find field $field
            set field $value
            if {[my exists field $field]} {
                return [dict get $fieldmap $field]
            } else {
                return -code error "field \"$field\" not found in table"
            }
        }
        default {
            return -code error "unknown option \"$type\": want\
                    \"key\" or \"field\""
        }
    }
}

# Table entry
################################################################################

# $tblObj set --
#
# Set single values in a table (single or dictionary form)
# Allows for multiple value inputs for record-style entry
#
# Syntax:
# $tblObj set $key $field $value ...
#
# Arguments:
# key:          Row key
# field:        Column field(s)
# value:        Value(s) to set

method set {key args} {
    # Check arity
    if {[llength $args] % 2} {
        # Default syntax
        return -code error "wrong # args: should be \"[self] set key field\
                value ?field value ...?\""
    }
    # Add keys and fields
    my add keys $key
    my add fields {*}[dict keys $args]
    # Add data
    dict for {field value} $args {
        # Handle blanks
        if {$value eq ""} {
            dict unset datamap $key $field
        } else {
            dict set datamap $key $field $value
        }; # end if blank
    }
    # Return self
    return [self]
}

# $tblObj rset --
#
# Set entire row
#
# Syntax:
# $tblObj rset $key $row
#
# Arguments:
# key:          Key associated with row
# row:          List of values (length must match table width, or be scalar)

method rset {key row} {
    # Get input and target dimensions and check for error
    set m0 [my width]
    set m1 [llength $row]
    if {$m1 == 0} {
        set type blank
    } elseif {$m1 == 1} {
        set value [lindex $row 0]
        if {$value eq ""} {
            set type blank
        } else {
            set type scalar
        }
    } elseif {$m1 == $m0} {
        set type values
    } else {
        return -code error "inconsistent number of fields/columns"
    }
    
    # Add key
    my add keys $key
    
    # Switch for input type (blank, scalar, or values)
    switch $type {
        blank {
            dict set datamap $key ""
        }
        scalar {
            foreach field $fields {
                dict set datamap $key $field $value
            }; # end foreach field
        }
        values {
            foreach value $row field $fields {
                # Handle blanks
                if {$value eq ""} {
                    dict unset datamap $key $field
                } else {
                    dict set datamap $key $field $value
                }; # end if blank
            }; # end foreach value/field
        }
    }; # end switch input type
    # Return object name
    return [self]
}

# $tblObj cset --
#
# Set entire column
#
# Syntax:
# $tblObj cset $field $column
# 
# Arguments:
# field:        Field associated with column
# column:       List of values (length must match height, or be scalar)

method cset {field column} {
    # Get source and input dimensions and get input type
    set n0 [my height]
    set n1 [llength $column]
    if {$n1 == 0} {
        set type blank
    } elseif {$n1 == 1} {
        set value [lindex $column 0]
        if {$value eq ""} {
            set type blank
        } else {
            set type scalar
        }
    } elseif {$n1 == $n0} {
        set type values
    } else {
        return -code error "inconsistent number of keys/rows"
    }
    
    # Add to field list
    my add fields $field
    
    # Switch for input type (blank, scalar, or column)
    switch $type {
        blank {
            foreach key $keys {
                dict unset datamap $key $field
            }; # end foreach value/field
        }
        scalar {
            foreach key $keys {
                dict set datamap $key $field $value
            }; # end foreach key
        }
        values {
            foreach value $column key $keys {
                # Handle blanks
                if {$value eq ""} {
                    dict unset datamap $key $field
                } else {
                    dict set datamap $key $field $value
                }; # end if blank
            }; # end foreach value/field
        }
    }; # end switch input type
    # Return object name
    return [self]
}

# $tblObj mset --
#
# Set range of table
#
# Syntax:
# $tblObj mset $keys $fields $matrix
#
# Arguments:
# keys:         Keys associated with rows
# field:        Fields associated with columns
# matrix:       Matrix of values (dimensions must match table or be scalar)

method mset {keyset fieldset matrix} {
    # Get source and input dimensions and get input type
    set n0 [llength $keyset]
    set m0 [llength $fieldset]
    set n1 [llength $matrix]
    set m1 [llength [lindex $matrix 0]]
    if {$n1 == 0 && $m1 == 0} {
        set type blank
    } elseif {$n1 == 1 && $m1 == 1} {
        set value [lindex $matrix 0 0]
        if {$value eq ""} {
            set type blank
        } else {
            set type scalar
        }
    } elseif {$n1 == $n0 && $m1 == $m0} {
        set type values
    } else {
        return -code error "input must be 0x0, 1x1 or ${n0}x${m0}"
    }
 
    # Add to key/field lists
    my add keys {*}$keyset
    my add fields {*}$fieldset
    
    # Switch for input type (blank, scalar, or matrix)
    switch $type {
        blank {
            foreach key $keyset {
                foreach field $fieldset {
                    dict unset datamap $key $field
                }; # end foreach value/field
            }; # end foreach row/key
        }
        scalar {
            foreach key $keyset {
                foreach field $fieldset {
                    dict set datamap $key $field $value
                }; # end foreach value/field
            }; # end foreach row/key
        }
        values {
            foreach row $matrix key $keyset {
                foreach value $row field $fieldset {
                    # Handle blanks
                    if {$value eq ""} {
                        dict unset datamap $key $field
                    } else {
                        dict set datamap $key $field $value
                    }; # end if blank
                }; # end foreach value/field
            }; # end foreach row/key
        }
    }; # end switch input type
    # Return object name
    return [self]
}

# Table access
################################################################################

# $tblObj get --
# 
# Get a value from a table
# If a key/field pairing does not exist, returns blank.
# Return error if a key or field does not exist
#
# Syntax:
# $tblObj get $key $field <$filler>
#
# Arguments:
# key:          key to query
# field:        field to query
# filler:       filler for missing values (default "")

method get {key field {filler ""}} {
    # Check if key-field pairing exists
    if {![my exists key $key]} {
        return -code error "key \"$key\" not found in table"
    }
    if {![my exists field $field]} {
        return -code error "field \"$field\" not found in table"
    }
    # Return value or blank if does not exist
    if {[my exists value $key $field]} {
        return [dict get $datamap $key $field]
    } else {
        return $filler
    } 
}

# $tblObj rget --
#
# Get a list of row values
#
# Syntax:
# $tblObj rget $key <$filler>
#
# Arguments:
# key:          key to query
# filler:       filler for missing values (default "")

method rget {key {filler ""}} {
    lmap field $fields {
        my get $key $field $filler
    }
}

# $tblObj cget --
#
# Get a list of column values
#
# Syntax:
# $tblObj cget $field <$filler>
#
# Arguments:
# field:        field to query
# filler:       filler for missing values (default "")

method cget {field {filler ""}} {
    # Loop through all keys, and return vector
    lmap key $keys {
        my get $key $field $filler
    }
}

# $tblObj mget --
#
# Get a matrix of table values 
#
# Syntax:
# $tblObj mget $keys $fields <$filler>
#
# Arguments:
# keys:         Keys to query
# fields:       Fields to query
# filler:       filler for missing values (default "")

method mget {keyset fieldset {filler ""}} {
    # Loop through keys and fields and return matrix
    lmap key $keyset {
        lmap field $fieldset {
            my get $key $field $filler
        }
    }
}

# $tblObj expr --
#
# Perform a field expression, return list of values
# 
# Arguments:
# fieldExpr:    Tcl expression, but with @ symbol for fields

method expr {fieldExpr {filler ""}} {
    # Get mapping of fields in fieldExpr
    set exp {@\w+|@{(\\\{|\\\}|[^\\}{]|\\\\)*}}
    set fieldMap ""
    foreach {match submatch} [regexp -inline -all $exp $fieldExpr] {
        lappend fieldMap [join [string range $match 1 end]] $match
    }
    
    # Check validity of fields in field expression
    dict for {field match} $fieldMap {
        if {![dict exists $fieldmap $field] && $field ne $keyname} {
            return -code error "field \"$field\" not found in table"
        }
    }
    
    # Now, we know that the fields are valid, and we will loop through 
    # the list of keys, and use "catch"
    # Get values according to field expression
    set values ""
    foreach key $keys {
        # Perform regular expression substitution
        set subExpr $fieldExpr
        set valid 1
        foreach {field match} $fieldMap {
            if {![my exists value $key $field]} {
                if {$field eq $keyname} {
                    set subExpr [regsub $match $subExpr "{$key}"]
                    continue
                }
                # No data for this key/field combo. Skip.
                set valid 0
                break
            }
            set subExpr [regsub $match $subExpr "{[my get $key $field]}"]
        }; # end foreach fieldmap pair
        if {$valid} {
            # Only add data if all required fields exist.
            lappend values [uplevel 1 [list expr $subExpr]]
        } else {
            lappend values $filler
        }; # end if valid
    }; # end foreach key
    
    # Return values created by field expression
    return $values
}

# $tblObj fedit --
#
# Assign or edit a column based on field expression
# 
# Arguments:
# field:        Field to edit or create
# fieldExpr:    Tcl expression, but with @ symbol for fields

method fedit {field fieldExpr} {
    my cset $field [uplevel 1 [list [self] expr $fieldExpr]]
    return [self]
}

# $tblObj query --
#
# Get keys that match a specific criteria from field expression
#
# Arguments:
# fieldExpr:        Field expression that results in a boolean value

method query {fieldExpr} {
    return [lmap bool [uplevel 1 [list [self] expr $fieldExpr]] key $keys {
        if {$bool} {
            set key
        } else {
            continue
        }
    }]
}

# $tblObj filter --
# 
# Reduce a table based on query results
#
# Arguments:
# fieldExpr:        Field expression that results in a boolean value

method filter {fieldExpr} {
    my define keys [uplevel 1 [list [self] query $fieldExpr]]
    return [self]
}

# $tblObj search --
#
# Find key or keys that match a specific criteria, using lsearch.
# If -inline is selected, filters the table instead.
# 
# Arguments:
# args:         Selected lsearch options. Use -- to signal end of options.         
# field:        Field to search in. If omitted, will search in keys.
# value:        Value to search for.

method search {args} {
    # Interpret arguments
    set options ""
    set inline false
    set remArgs ""
    set optionCheck 1
    foreach arg $args {
        if {$optionCheck} {
            # Check valid options
            if {$arg in {
                -exact
                -glob
                -regexp
                -sorted
                -all
                -not
                -ascii
                -dictionary
                -integer
                -nocase
                -real
                -decreasing
                -increasing
                -bisect
            }} then {
                lappend options $arg
                continue
            } elseif {$arg eq "-inline"} {
                set inline true
                continue
            } else {
                set optionCheck 0
                if {$arg eq {--}} {
                    continue
                }
            }; # end check option arg
        }; # end if checking for options
        lappend remArgs $arg
    }; # end foreach arg
    
    # Process value and field arguments
    switch [llength $remArgs] {
        1 { # Search keys
            set value [lindex $remArgs 0]
        }
        2 { # Search a column
            lassign $remArgs field value
        }
        default {
            return -code error "wrong # args: should be\
                    \"[self] search ?-option value ...? field pattern\""
        }
    }; # end switch arity of remaining

    # Handle key search case
    if {![info exists field]} {
        # Filter by keys 
        set keyset [lsearch {*}$options -inline $keys $value]
    } else {
        # Filter by field values
        if {![my exists field $field]} {
            return -code error "field \"$field\" not found in table"
        }
        
        # Check whether to include blanks or not
        set includeBlanks [expr {
            ![catch {lsearch {*}$options {{}} $value} result] && $result == 0
        }]
        
        # Get search list
        set searchList [lmap key $keys {
            if {[dict exists $datamap $key $field]} {
                list $key [dict get $datamap $key $field]
            } elseif {$includeBlanks} {
                list $key {}
            } else {
                continue
            }
        }]; # end lmap key
        # Get matches and corresponding keys
        set matchList [lsearch {*}$options -index 1 -inline $searchList $value]
        if {{-all} in $options} {
            set keyset [lsearch -all -inline -subindices -index 0 $matchList *]
        } else {
            set keyset [lrange $matchList 0 0]
        }
    }
    # Filter table and return table name if inline
    if {$inline} {
        my define keys $keyset
        return [self]
    }
    # Return keyset or individual key if not inline.
    if {{-all} in $options} {
        return $keyset
    } else {
        return [lindex $keyset 0]
    }
}

# $tblObj sort --
# 
# Sort a table, using lsort
#
# Arguments:
# options:      Selected lsort options. Use -- to signal end of options.
# args:         Fields to sort by

method sort {args} {
    # Interpret arguments
    set options ""
    set fieldset ""
    set optionCheck 1
    foreach arg $args {
        if {$optionCheck} {
            # Check valid options
            if {$arg in {
                -ascii
                -dictionary
                -integer
                -real
                -increasing
                -decreasing
                -nocase
            }} then {
                lappend options $arg
                continue
            } else {
                set optionCheck 0
                if {$arg eq "--"} {
                    continue
                }
            }
        }
        lappend fieldset $arg
    }

    # Switch for sort type (keys vs fields)
    if {[llength $fieldset] == 0} {
        # Sort by keys
        set keys [lsort {*}$options $keys]
    } else {
        # Sort by field values
        foreach field $fieldset {
            # Check validity of field
            if {![my exists field $field]} {
                return -code error "field \"$field\" not found in table"
            }
            
            # Get column and blanks
            set cdict ""; # Column dictionary for existing values
            set blanks ""; # Keys for blank values
            foreach key $keys {
                if {[my exists value $key $field]} {
                    dict set cdict $key [dict get $datamap $key $field]
                } else {
                    lappend blanks $key
                }
            }
            
            # Sort valid keys by values, and then add blanks
            set keys [concat [dict keys [lsort -stride 2 -index 1 \
                    {*}$options $cdict]] $blanks]
        }; # end foreach field
    }; # end if number of fields
    
    # Update key map
    set i 0
    foreach key $keys {
        dict set keymap $key $i
        incr i
    }
    # Return object name
    return [self]
}

# $tblObj with --
# 
# Loops through table (row-wise), using dict with on the table data.
# Missing data is represented by blanks. Setting a field to blank or 
# unsetting the variable will unset the data.

# Syntax:
# $tblObj with $body 
# Example:
#
# Arguments:
# body:         Body to evaluate

# new table T {key {x y}}
# $T cset y {1 2 3}
# $T with {set x [expr {$y + 2}]}

method with {body} {
    variable temp; # Temporary variable for dict with loop
    foreach key $keys {
        # Establish keyname variable (not upvar, cannot modify)
        uplevel 1 [list set $keyname $key]
        # Create temporary row dict with blanks
        set temp [dict get $datamap $key]
        foreach field $fields {
            if {![dict exists $temp $field]} {
                dict set temp $field ""
            }
        }
        # Evaluate body, using dict with
        uplevel 1 [list dict with [self namespace]::temp $body]
        # Filter out blanks
        dict set datamap $key [dict filter $temp value ?*]
    }
    # Return object name
    return [self]
}

# $tblObj merge --
# 
# Add table data from other tables, merging the data. 
# Keynames must be consistent to merge.
#
# $tblObj merge $object ...
# 
# Arguments:
# object ...    Tables to merge into main table

method merge {args} {
    # Check compatibility
    foreach tblObj $args {
        # Assert type
        ::vutil::type assert table $tblObj
        # Verify that tables are compatible
        if {$keyname ne [$tblObj keyname]} {
            return -code error "cannot merge tables - keyname conflict"
        }
    }
    # Merge input tables
    foreach tblObj $args {
        # Add keys and fields
        my add keys {*}[$tblObj keys]
        my add fields {*}[$tblObj fields]
        # Merge data
        dict for {key rowmap} [$tblObj data] {
            my set $key {*}$rowmap
        }
    }
    # Return object name
    return [self]
}

# Table manipulation
################################################################################

# $tblObj define --
# 
# Define keys/fields. Filters table and adds any new keys/fields.
# 
# Syntax:
# $tblObj define keys $keys
# $tblObj define fields $fields
# 
# Arguments:
# keys/fields:      List of keys/fields for table. Must be unique.

method define {type value} {
    switch $type {
        keys { # $tblObj define keys $keys
            # Check uniqueness
            if {![my IsUniqueList $value]} {
                return -code error "keys must be unique"
            }
            # Redefine keys
            set keys ""
            set keymap ""
            my add keys {*}$value
            # Filter data
            dict for {key rowmap} $datamap {
                if {![my exists key $key]} {
                    dict unset datamap $key
                }
            }
        }
        fields { # $tblObj define fields $fields
            # Check uniqueness
            if {![my IsUniqueList $value]} {
                return -code error "fields must be unique"
            }
            # Redefine fields
            set fields ""
            set fieldmap ""
            my add fields {*}$value
            # Filter data
            dict for {key rowmap} $datamap {
                dict for {field value} $rowmap {
                    if {![my exists field $field]} {
                        dict unset datamap $key $field
                    }
                }
            }
        }
        default {
            return -code error "unknown option \"$type\": \
                    want \"keys\" or \"fields\""
        }
    }; # end switch
    # Return self
    return [self]
}

# $tblObj add --
#
# Add keys/fields to the table, appending to end, in "dict set" fashion.
# Blank keys/fields are not allowed.
# Field must not conflict with keyname
# Duplicates may be entered with no penalty.
#
# Syntax:
# $tblObj add keys $key ...
# $tblObj add fields $field ...
# 
# Arguments:
# key ...       Keys to add
# field ...     Fields to add

method add {option args} {
    switch $option {
        keys { # $tblObj add keys $key ...
            foreach key $args {
                # Ensure that input is valid
                if {$key eq ""} {
                    return -code error "key cannot be blank"
                }
                # Check if key is new
                if {![dict exists $keymap $key]} {
                    dict set keymap $key [my height]
                    lappend keys $key
                }
                # Ensure that data entries exist
                if {![dict exists $datamap $key]} {
                    dict set datamap $key ""
                }
            }
        }
        fields { # $tblObj add fields $field ...
            foreach field $args {
                if {$field eq $keyname} {
                    return -code error "field cannot be keyname"
                }
                if {$field eq ""} {
                    return -code error "field cannot be blank"
                }
                # Check if field is new
                if {![dict exists $fieldmap $field]} {
                    dict set fieldmap $field [my width]
                    lappend fields $field
                }
            }
        }
        default {
            return -code error "unknown option \"$option\".\
                    want \"keys\" or \"fields\""
        }
    } 
    # Return object name
    return [self]
}

# $tblObj remove --
#
# Remove keys/fields if they exist. Handles duplicates just fine.
#
# Syntax:
# $tblObj remove keys $key ...
# $tblObj remove fields $field ...
#
# Arguments:
# key ...       Keys to insert
# field ...     Fields to insert

method remove {type args} {
    switch $type {
        keys {
            # Get keys to remove in order of index
            set imap ""
            foreach key $args {
                if {![my exists key $key]} {
                    continue
                }
                dict set imap $key [my find key $key]
            }
            # Switch for number of keys to remove
            if {[dict size $imap] == 0} {
                return
            } elseif {[dict size $imap] > 1} {
                set imap [lsort -integer -stride 2 -index 1 $imap]
            }

            # Remove from keys and data (k-trick for performance)
            set count 0; # Count of removed values
            dict for {key i} $imap {
                incr i -$count; # Adjust for removed elements
                set keys [lreplace $keys[set keys ""] $i $i]
                dict unset keymap $key
                dict unset datamap $key
                incr count
            }
            
            # Update keymap
            set i [lindex $imap 1]; # minimum removed i
            foreach key [lrange $keys $i end] {
                dict set keymap $key $i
                incr i
            }
        }
        fields {
            # Get fields to remove in order of index
            set jmap ""
            foreach field $args {
                if {![my exists field $field]} {
                    continue
                }
                dict set jmap $field [my find field $field]
            }
            
            # Switch for number of keys to remove
            if {[dict size $jmap] == 0} {
                return
            } elseif {[dict size $jmap] > 1} {
                set jmap [lsort -integer -stride 2 -index 1 $jmap]
            }   
            
            # Remove from fields and data (k-trick for performance)
            set count 0; # Count of removed values
            dict for {field j} $jmap {
                incr j -$count; # Adjust for removed elements
                set fields [lreplace $fields[set fields ""] $j $j]
                dict unset fieldmap $field
                dict for {key rowmap} $datamap {
                    dict unset datamap $key $field
                }
                incr count
            }
            
            # Update fieldmap
            set j [lindex $jmap 1]; # minimum removed j
            foreach field [lrange $fields $j end] {
                dict set fieldmap $field $j
                incr j
            }
        }
        default {
            return -code error "unknown option \"$option\".\
                    want \"keys\" or \"fields\""
        }
    }
    return
}

# $tblObj insert --
# 
# Insert keys/fields (must be unique, and no duplicates)
#
# Syntax:
# $tblObj insert keys $index $key ...
# $tblObj insert fields $index $field ...
#
# Arguments:
# index:        Row or column ID to insert at
# key ...       Keys to insert
# field ...     Fields to insert

method insert {type index args} {
    switch $type {
        keys {
            # Ensure input keys are unique and new
            if {![my IsUniqueList $args]} {
                return -code error "cannot have duplicate key inputs"
            }
            foreach key $args {
                if {[my exists key $key]} {
                    return -code error "key \"$key\" already exists"
                }
            }
            # Convert index input to integer
            set i [::ndlist::Index2Integer $index [my height]]
            # Insert keys (using k-trick for performance)
            set keys [linsert $keys[set keys ""] $i {*}$args]
            # Update indices in key map
            foreach key [lrange $keys $i end] {
                dict set keymap $key $i
                incr i
            }
            # Ensure that entries in data exist
            foreach key $args {
                if {![dict exists $datamap $key]} {
                    dict set datamap $key ""
                }
            }
        }
        fields {
            # Ensure input fields are unique and new
            if {![my IsUniqueList $args]} {
                return -code error "cannot have duplicate field inputs"
            }
            foreach field $args {
                if {[my exists field $field]} {
                    return -code error "field \"$field\" already exists"
                }
            }
            # Convert index input to integer
            set j [::ndlist::Index2Integer $index [my width]]
            # Insert fields (using k-trick for performance)
            set fields [linsert $fields[set fields ""] $j {*}$args]
            # Update indices in field map
            foreach field [lrange $fields $j end] {
                dict set fieldmap $field $j
                incr j
            }
        }
        default {
            return -code error "unknown option \"$option\".\
                    want \"keys\" or \"fields\""
        }
    }
    return
}
  
# $tblObj rename --
#
# Rename keys or fields in table
#
# Syntax:
# $tblObj rename keys <$old> $new
# $tblObj rename fields <$old> $new
#
# Arguments:
# old:          List of old keys/fields. Default existing keys/fields
# new:          List of new keys/fields

method rename {type args} {
    # Check type
    if {$type ni {keys fields}} {
        return -code error "unknown option \"$option\".\
                    want \"keys\" or \"fields\""
    }
    # Switch for arity
    if {[llength $args] == 1} {
        switch $type {
            keys {set old $keys}
            fields {set old $fields}
        }
        set new [lindex $args 0]
        if {![my IsUniqueList $new]} {
            return -code error "new $type must be unique"
        }
    } elseif {[llength $args] == 2} {
        lassign $args old new
        if {![my IsUniqueList $old] || ![my IsUniqueList $new]} {
            return -code error "old and new $type must be unique"
        }
    } else {
        return -code error "wrong # args: want \"[self] $type ?old? new\""
    }
    # Check lengths
    if {[llength $old] != [llength $new]} {
        return -code error "old and new $type must match in length"
    }
    switch $type {
        keys {
            # Get old rows (checks for error)
            set rows [lmap key $old {my rget $key}]
            
            # Update key list and map (requires two loops, incase of 
            # intersection between old and new lists)
            set iList ""
            foreach oldKey $old newKey $new {
                set i [my find key $oldKey]
                lappend iList $i
                lset keys $i $newKey
                dict unset keymap $oldKey
                dict unset datamap $oldKey
            }
            foreach newKey $new i $iList row $rows {
                dict set keymap $newKey $i; # update in-place
                my rset $newKey $row; # Re-add row
            }
        }
        fields {
            # Get old columns (checks for error)
            set columns [lmap field $old {my cget $field}]
            
            # Update field list and map (requires two loops, incase of 
            # intersection between old and new lists)
            set jList ""
            foreach oldField $old newField $new {
                set j [my find field $oldField]
                lappend jList $j
                lset fields $j $newField
                dict unset fieldmap $oldField
                dict for {key rowmap} $datamap {
                    dict unset datamap $key $oldField
                }
            }
            foreach newField $new j $jList column $columns {
                dict set fieldmap $newField $j; # update in-place
                my cset $newField $column; # Re-add column
            }
        }
    }
    # Return object name
    return [self]
}     

# $tblObj mkkey --
# 
# Make a field the key. Data loss may occur.
#
# Syntax:
# $tblObj mkkey $field
# 
# Arguments:
# field:            Field to swap with key.

method mkkey {field} {
    # Check validity of transfer
    if {[my exists field $keyname]} {
        return -code error "keyname conflict with fields"
    }
    if {![my exists field $field]} {
        return -code error "field \"$field\" not found in table"
    }
    # Make changes to a table copy
    my --> tblCopy
    $tblCopy remove fields $field; # Remove field (also removes data)
    $tblCopy keyname $field; # Redefine keyname
    $tblCopy rename keys [my cget $field]; # Rename keys
    $tblCopy cset $keyname $keys; # Add field for original keys
    # Redefine current table
    my <- $tblCopy
    # Return object name
    return [self]
}

# $tblObj move --
#
# Move row or column. Calls "MoveRow" and "MoveColumn"
#
# Syntax:
# $tblObj move key $key $index
# $tblObj move field $field $index
#
# Arguments:
# key       Key of row to move
# field     Field of column to move
# index     Row or column ID to move to.

method move {type args} {
    switch $type {
        key {
            my MoveRow {*}$args
        }
        field {
            my MoveColumn {*}$args
        }
        default {
            return -code error "unknown option \"$type\": \
                    should be \"key\" or \"field\"."
        }
    }
    # Return object name
    return [self]
}

# my MoveRow --
#
# Move row to a specific row index
#
# Syntax:
# my MoveRow $key $i
# 
# Arguments:
# key:      Key to move
# i:        Row index to move to.

method MoveRow {key i} {
    # Get initial and final row indices
    set i1 [my find key $key]
    set i2 [::ndlist::Index2Integer $i [my height]]
    # Switch for move type
    if {$i1 < $i2} {
        # Target index is beyond source
        set keys [concat [lrange $keys 0 $i1-1] \
                [lrange $keys $i1+1 $i2] [list $key] \
                [lrange $keys $i2+1 end]]
        set i $i1
    } elseif {$i1 > $i2} {
        # Target index is below source
        set keys [concat [lrange $keys 0 $i2-1] [list $key] \
                [lrange $keys $i2 $i1-1] [lrange $keys $i1+1 end]]
        set i $i2
    } else {
        # Trivial case
        return
    }
    # Update keymap
    foreach key [lrange $keys $i end] {
        dict set keymap $key $i
        incr i
    }
}

# my MoveColumn --
#
# Move column to a specific column index
#
# Syntax:
# my MoveColumn $field $j
# 
# Arguments:
# field:    Field to move
# j:        Column index to move to.

method MoveColumn {field j} {
    # Get source index, checking validity of field
    set j1 [my find field $field]
    set j2 [::ndlist::Index2Integer $j [my width]]
    # Switch for move type
    if {$j1 < $j2} {
        # Target index is beyond source
        set fields [concat [lrange $fields 0 $j1-1] \
                [lrange $fields $j1+1 $j2] [list $field] \
                [lrange $fields $j2+1 end]]
        set j $j1
    } elseif {$j1 > $j2} {
        # Target index is below source
        set fields [concat [lrange $fields 0 $j2-1] [list $field] \
                [lrange $fields $j2 $j1-1] [lrange $fields $j1+1 end]]
        set j $j2
    } else {
        # Trivial case
        return
    }
    # Update fieldmap
    foreach field [lrange $fields $j end] {
        dict set fieldmap $field $j
        incr j
    }
}

# $tblObj swap --
#
# Swap rows/columns. Calls "SwapRows" and "SwapColumns"
#
# Syntax:
# $tblObj swap keys $key1 $key2 
# $tblObj swap fields $field1 $field2 
#
# Arguments:
# key1 key2:        Keys to swap
# field1 field2:    Fields to swap

method swap {type args} {
    switch $type {
        keys {
            my SwapRows {*}$args
        }
        fields {
            my SwapColumns {*}$args
        }
        default {
            return -code error "unknown option \"$type\": \
                    should be \"keys\" or \"fields\"."
        }
    }
    # Return object name
    return [self]
}

# my SwapRows --
#
# Swap rows
#
# Syntax:
# my SwapRows $key1 $key2
#
# Arguments:
# key1:         Key to swap with key2
# key2:         Key to swap with key1

method SwapRows {key1 key2} {
    # Check existence of keys
    foreach key [list $key1 $key2] {
        if {![dict exists $keymap $key]} {
            return -code error "key \"$key\" not found in table"
        }
    }
    # Get row IDs
    set i1 [dict get $keymap $key1]
    set i2 [dict get $keymap $key2]
    # Update key list and map
    lset keys $i2 $key1
    lset keys $i1 $key2
    dict set keymap $key1 $i2
    dict set keymap $key2 $i1
    # Return object name
    return [self]
}

# my SwapColumns --
#
# Swap columns
#
# Syntax:
# my SwapColumns $field1 $field2
#
# Arguments:
# field1:       Field to swap with field2
# field2:       Field to swap with field1

method SwapColumns {field1 field2} {
    # Check existence of fields
    foreach field [list $field1 $field2] {
        if {![dict exists $fieldmap $field]} {
            return -code error "field \"$field\" not found in table"
        }
    }
    # Get column IDs
    set j1 [dict get $fieldmap $field1]
    set j2 [dict get $fieldmap $field2]
    # Update field list and map
    lset fields $j2 $field1
    lset fields $j1 $field2
    dict set fieldmap $field1 $j2
    dict set fieldmap $field2 $j1
    # Return object name
    return [self]
}

# $tblObj transpose --
# 
# Transpose a table

method transpose {} {
    # Verify that transpose is allowed
    if {[my exists key $keyname]} {
        return -code error "cannot transpose: keyname in keys"
    }
    # Initialize transpose data
    foreach field $fields {
        dict set transpose $field ""
    }
    # Swap keys/fields
    lassign [list $keys $fields] fields keys
    lassign [list $keymap $fieldmap] fieldmap keymap
    # Transpose data
    dict for {key rowmap} $datamap {
        dict for {field value} $rowmap {
            dict set transpose $field $key $value
        }
    }
    set datamap $transpose
    # Return object name
    return [self]
}

# $tblObj clean --
#
# Clear keys and fields that don't exist in data

method clean {} {
    # Remove blank keys
    my remove keys {*}[lmap key $keys {
        if {[dict size [dict get $datamap $key]]} {
            continue
        }
        set key
    }]
    # Remove blank fields
    my remove fields {*}[lmap field $fields {
        set isBlank 1
        dict for {key rowmap} $datamap {
            if {[dict exists $rowmap $field]} {
                set isBlank 0
                break
            }
        }
        if {!$isBlank} {
            continue
        }
        set field
    }]
    # Return object name
    return [self]
}
}; # end class definition


# Finally, provide the package
package provide taboo 0.2.1
