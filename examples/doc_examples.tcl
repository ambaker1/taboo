package require tin
tin import taboo

puts "Example table"
table new tableObj {
    key {1 2 3 4 5} 
    x {3.44 4.61 8.25 5.20 3.26}
    y {7.11 1.81 7.56 6.78 9.92}
    z {8.67 7.63 3.84 1.11 4.56}
}
puts [$tableObj]

puts "Copying a table"
$tableObj --> tableCopy
puts [$tableObj info]

puts "Accessing table keys and table dimensions"
puts [$tableObj keys]
puts [$tableObj keys 0:end-1]
puts [$tableObj height]

puts "Getting table data in dictionary and matrix form"
puts [$tableObj data]
puts [$tableObj data 3]
puts [$tableObj values]

puts "Find column index of a field"
puts [$tableObj exists field z]
puts [$tableObj find field z]

puts "Setting multiple values"
$tableObj --> tableCopy
$tableCopy set 1 x 2.00 y 5.00 foo bar
puts [$tableCopy data 1]

puts "Matrix entry and access"
::vutil::new table T
$T add keys 1 2 3 4
$T add fields A B
$T mset [$T keys] [$T fields] 0.0; # Initialize as zero
$T mset [$T keys 0:2] A {1.0 2.0 3.0}; # Set subset of table
puts [$T values]

puts "Iterating over a table, accessing and modifying field values"
$tableObj --> tableCopy
set a 20.0
$tableCopy add fields q
$tableCopy with {
    puts [list $key $x]; # access key and field value
    set q [expr {$x*2 + $a}]; # modify field value
}
puts [$tableCopy cget q]

puts "Using field expressions"
$tableObj --> tableCopy
set a 20.0
puts [$tableCopy cget x]
puts [$tableCopy expr {@x*2 + $a}]
$tableCopy fedit q {@x*2 + $a}
puts [$tableCopy cget q]

puts "Getting keys that match criteria"
puts [$tableObj query {@x > 3.0 && @y > 7.0}]

puts "Filtering table to only include keys that match criteria"
$tableObj --> tableCopy
$tableCopy filter {@x > 3.0 && @y > 7.0}
puts [$tableCopy keys]

puts "Searching and sorting"
$tableObj --> tableCopy
puts [$tableCopy search -real x 8.25]; # returns first matching key
$tableCopy sort -real x
puts [$tableCopy keys]
puts [$tableCopy cget x]; # table access reflects sorted keys
puts [$tableCopy search -sorted -bisect -real x 5.0]

puts "Merging data from other tables"
$tableObj --> tableCopy
table new newTable
$newTable set 1 x 5.00 q 6.34
$tableCopy merge $newTable
$tableCopy print

puts "Renaming fields"
$tableObj --> tableCopy
$tableCopy rename fields [string toupper [$tableCopy fields]]
puts [$tableObj fields]
puts [$tableCopy fields]

puts "Swapping table rows"
$tableObj --> tableCopy
$tableCopy swap keys 1 4
$tableCopy print

puts "Transposing a table"
$tableObj --> tableCopy
$tableCopy transpose
$tableCopy print