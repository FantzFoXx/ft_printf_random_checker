#!/usr/bin/perl

#use strict;
use warnings;
use Getopt::Long;
use	Cwd qw(abs_path);
use Term::ANSIColor qw(:constants);
use Data::Dumper;


my @file_lines = 		( 	"#include <stdio.h>", 
							"#include \"ft_printf.h\"", 
							"",
							"int		main(void)",
							"{",
							"	intmax_t i = 0;",
							"	return (0);",
							"}");

my @rand_size_flag =	("", "h", "hh", "l", "ll", "j", "z");
my @rand_flag = 		("", "0", " ", "+", "-", "#");
my @rand_types =		("s", "d", "x", "X", "o", "u", "i");
my $string = "kjhasdflkjhasdlfkj hasldkfj hasldk jhasdlfkjhasdl kjhasdflkjhasdflkjhasdflkja hsflkj ahsdflk jhasdlfkjh";
my @format_strings_list;

my %decimal_casts = (
	o => {
		hh => "(unsigned char)", 
		h  => "(unsigned short)", 
		l  => "(unsigned long)", 
		ll => "(unsigned long long)", 
		j  => "(uintmax_t)", 
		z  => "(size_t)"
	}, 
	d => {
		hh => "(signed char)",	
		h  => "(short)",			
		l  => "(long)",			
		ll => "(long long)",		
		j  => "(intmax_t)",		
		z  => "(size_t)"			
	}
);





# global option command line variables 
my $clean = 0;
my $verbose = 0;
my $gen_limit = 100;
my $libftprintf_dir = "";

my $count_lines = 0;

sub print_banner
{
	print "--------------------------------------------------------------------------------\n";
	print "|                                                                               |\n";
	print "|                           ft_printf_random_checker                            |\n";
	print "|                                   V.1.0.0                                     |\n";
	print "|                                 by udelorme                                   |\n";
	print "|                                                                               |\n";
	print "--------------------------------------------------------------------------------\n";
}

sub done {
	print GREEN, "Done.\n", RESET;
}

sub generate_base_file
{
	my ($file) = @_;

	for my $i (0..5) {
		  print $file "$file_lines[$i]\n";
	  }
}

sub end_file
{
	my ($file) = @_;

	for my $i (6..7) {
		  print $file "$file_lines[$i]\n";
	  }
}

sub generate_random_format_string
{
	my ($type) = @_;
	my $rand = int(rand(4));
	my $format_string = "%";
	my $sflag = "";
	for (my $i = 0; $i <= $rand; $i++)
	{
		my $rand_flag_id = int(rand(6));
		$format_string .= $rand_flag[$rand_flag_id];
	}
	$rand = int(rand(2));
	if ($rand == 1) {
		$format_string .= "." . int(rand(10));
	}
	if ($type ne "s") {
		$sflag = $rand_size_flag[int(rand(6))];
		$format_string .= $sflag;
	}
	$format_string .= "$type";
	if ($verbose) {
		print "generated format string : $format_string\n";
	}
	return ($format_string, $sflag);
}

sub push_generated_function
{
	my ($ft_file, $real_file) = @_;

	#print Dumper \%decimal_casts;
	$count_lines++;
	my $type = $rand_types[int(rand(6))];
	my ($format_string, $sflag) = generate_random_format_string($type);
	if ($type eq "s")
	{
		print $real_file "	printf(\"Bonjour " . $format_string . " ceci est un test\\n\", \"first test\");fflush(stdout);\n";
		print $ft_file "	ft_printf(\"Bonjour " .  $format_string . " ceci est un test\\n\", \"first test\");\n";
		push(@format_strings_list, "format string : \'$format_string\' with value : \'first test\'");
	}
	else
	{
		my $rand_value = int(rand(1000000000000000000));
		my $cast = "";
		if ($sflag ne "") {
			if ($type eq "d" || $type eq "i") {
				$cast = $decimal_casts{d}{$sflag};
			}
			else {
				$cast = $decimal_casts{o}{$sflag};
			}
			if ($verbose) {
				print "cast : \'$cast\' for type : \'$type\' with flag : \'$sflag\'\n";
			}
		}
		elsif ($type ne "s") {
			$cast = "(int)";
		}
		#print $real_file "	i = " . $rand_value . ";\n	printf(\"Bonjour " . $format_string . " ceci est un test\\n\", ". $cast ." i);fflush(stdout);\n";
		#print $ft_file "	i = " . $rand_value . ";\n	ft_printf(\"Bonjour " . $format_string . " ceci est un test\\n\", ". $cast ." i);\n";
		print $real_file "	printf(\"Bonjour " . $format_string . " ceci est un test\\n\", ". $cast ." $rand_value);fflush(stdout);\n";
		print $ft_file "	ft_printf(\"Bonjour " . $format_string . " ceci est un test\\n\", ". $cast ." $rand_value);\n";
		push(@format_strings_list, "format string : \'$format_string\' with value : $cast $rand_value");
	}
}

sub pipe_from_fork ($) {
	my $parent = shift;

	pipe $parent, my $child or die;
	my $pid = fork();
	die "fork() failed: $!" unless defined $pid;
	if ($pid) {
		close $child;
	}
	else {
		close $parent;
		open(STDOUT, ">&=" . fileno($child)) or die;
	}
	$pid;
}

sub pull_data_form_binary
{
	my $binary = shift;
	if (pipe_from_fork('WRITER')) {
		my @values = [];
		while ( my $line = <WRITER> ) {
			chomp($line);
			push(@values, $line);
		}
		close WRITER;
		return (@values);
	}
	else
	{
		exec($binary)
			or die ("printf failed");
		exit;
	}
}

# ###################### MAIN #######################

my $filename = "random_tests.c";
my $ft_filename = "ft_random_tests.c";


GetOptions ("clean" => \$clean,
			"limit=i" => \$gen_limit,
			"libpath=s" => \$libftprintf_dir,
			"verbose"  => \$verbose)
or die("Error in command line arguments\n");


if ($clean)
{
	system("rm ft_random_tests.c random_tests.c ft_real ft_out 2>&-");
	exit;
}

if ($libftprintf_dir eq "") {
	die("No valid project dir found\n");
}

$libftprintf_dir = abs_path($libftprintf_dir);

print_banner();

# creating tmp dir

mkdir("./tmp");
chdir("./tmp");

open(my $ft_file_gen, ">", "$ft_filename")
	or die "Can't open < random_tests.c: $!";

open(my $real_file_gen, ">", "$filename")
	or die "Can't open < random_tests.c: $!";

generate_base_file($real_file_gen);
generate_base_file($ft_file_gen);

print "generating random format strings...\n";

for (1..$gen_limit) {
	push_generated_function($ft_file_gen, $real_file_gen);
}

end_file($ft_file_gen);
end_file($real_file_gen);

done();
print "$count_lines generated lines\n";
print "compiling .c files...\n";

system("/usr/bin/make -C $libftprintf_dir >/dev/null") == 0
	or die "make encountered a problem";
system("/usr/bin/clang ft_random_tests.c -I $libftprintf_dir/includes -I $libftprintf_dir/libft/includes -L$libftprintf_dir -lftprintf -o ft_out 2>&-") == 0
	or die "system command clang failed on ft_random_test.c";
system("/usr/bin/clang random_tests.c -I $libftprintf_dir/includes -I $libftprintf_dir/libft/includes -o ft_real 2>&-") == 0
	or die "system command clang failed on random_test.c";

done();
print "Executing programs...\n";

my @ft_values = pull_data_form_binary("./ft_out");
my @real_values = pull_data_form_binary("./ft_real");

print scalar(@ft_values) . " from ft_out\n";
print scalar(@real_values) . " from ft_real\n";

done();
print "Computing data...\n";

my $failed = 0;

open(my $trace_file, ">", "diff_trace")
	or die "Can't open < random_tests.c: $!";

foreach my $i (1..$gen_limit - 1) {
	if (defined $real_values[$i] && $ft_values[$i] ne $real_values[$i]) {
		print STDOUT	BLUE, "diff : \n", RESET;
		print STDOUT	RED, "ft_printf	: \'" . $ft_values[$i] . "\'\n", RESET;
		print STDOUT	GREEN, "printf		: \'" . $real_values[$i] . "\'\n", RESET;
		print STDOUT	YELLOW, "on " . $format_strings_list[$i - 1] . "\n", RESET;
		print STDOUT	BLUE, "---------\n", RESET;

		print $trace_file "diff : \n";
		print $trace_file "ft_printf	: \'" . $ft_values[$i] . "\'\n";
		print $trace_file "printf		: \'" . $real_values[$i] . "\'\n";
		print $trace_file "on " . $format_strings_list[$i - 1] . "\n";
		print $trace_file "---------\n";

		$failed++;
	}
}

done();

print RED, "$failed failed tests.\n", RESET;

chdir("..");
#rmdir("./tmp");
close($trace_file);
close($ft_file_gen);
close($real_file_gen);

######################################################################
