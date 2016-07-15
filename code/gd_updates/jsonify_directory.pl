#!/usr/bin/perl
#
# Single perl thing to jsonify all files in given directory
#
# And, for folks wondering "Why are you doing it this way instead of a shell script that does
# this
#   for file in $(ls $dir); do perl -pie "s/foo/bar/" $dir/$file; done
# Here's why... for 3528 files (number of CardTemplate files at the time of writing this script)
# it took 0m43.453s real time to do it the shell way. It took 0m2.561s real time doing it this way.
#
# So, the answer is PERFORMANCE!

# Get the directory passed as an argument on the command line
my $directory = $ARGV[0];

# Get rid of any trailing '/' character
$directory =~ s/\/$//;

# Unset output buffering
my $prev_fh = select STDOUT;
$| = 1;
select $prev_fh;

# Set input to grok utf-8
use open qw( :encoding(utf8) :std);

print "Directory: '$directory' - ";

# Read in the contents of the directory
opendir(my $dh, $directory) || die "Can't open directory $directory: $!\n";

# Get the list of files from that directory. Skip dot files and the section_split_file file
@files = grep { ! /^\./ && ! /^section_split_file/ && -f "$directory/$_" } readdir($dh);
# Prepend directory name to each element of the array
foreach my $f (@files) {
  $f = "$directory/$f";
#  print "\tfile: $f\n";
}

print "$#files total files - ";

# Now, some voodoo here.  There's a command-line switch that we could use to do the inline 
# replacement.  But we want to only invoke a single perl instance (instead of a perl instance
# per file).  So, we do the following... make a local code block. Set the special variable
# $^I to '.bak' to say we want to do inline edits and make a backup of the file into filename.bak, 
# then  set the @ARGV array to the list of filenames in @files.
# Once that's done, we iterate through those and do the inline edits creating backups as we go

{
  local ($^I, @ARGV) = ('', @files);
  while(<>) {
    # Do this to get rid of badly formatted line breaks in the JSON files
    chomp;
    utf8::decode($_);
    # Get rid of ^M characters
    s///g;
    # These are to get rid of instances of single quotes that should be double quotes
    s/: '/: \"/g; 
    s/' *}/\"}/g; 
    s/, *}/  }/g; 
    s/',$/\",/g;
    # replace unicode characters with appropriate versions
    # Open and closed double quote characters
    s/\x{201c}/\\"/g;
    s/\x{201d}/\\"/g;
    s/\x{2013}/-/g;
    s/\x{2019}/'/g;
    # And this gets rid of the split character between individual data instances
    s/^==$//g; 
    print;
  }
}

print "done\n";
