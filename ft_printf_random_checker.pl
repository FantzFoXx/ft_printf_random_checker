#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my @file_lines = 		( 	"#include <stdio.h>", 
							"#include \"ft_printf.h\"", 
							"",
							"int		main(void)",
							"{",
							"	return (0);",
							"}");

my @rand_size_flag =	("", "h", "hh", "l", "ll", "j", "z");
my @rand_flag = 		("", "0", " ", "+", "-", "#");
my $string = "kjhasdflkjhasdlfkj hasldkfj hasldk jhasdlfkjhasdl kjhasdflkjhasdflkjhasdflkja hsflkj ahsdflk jhasdlfkjh";


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

sub generate_base_file
{
	my ($file) = @_;

	for my $i (0..4) {
		  print $file "$file_lines[$i]\n";
	  }
}

sub end_file
{
	my ($file) = @_;

	for my $i (5..6) {
		  print $file "$file_lines[$i]\n";
	  }
}

sub push_generated_function
{
	my ($ft_file, $real_file) = @_;

	$count_lines++;
	print $real_file "	printf(\"Bonjour " . generate_random_format_string("s") . " ceci est un test\\n\", \"first test\");\n";
	print $ft_file "	ft_printf(\"Bonjour " . generate_random_format_string("s") . " ceci est un test\\n\", \"first test\");\n";
}

sub generate_random_format_string
{
	my ($type) = @_;
	my $rand = int(rand(4));
	my $format_string = "%";
	for (my $i = 0; $i <= $rand; $i++)
	{
		my $rand_flag_id = int(rand(6));
		$format_string .= $rand_flag[$rand_flag_id];
	}
	$rand = int(rand(2));
	if ($rand == 1) {
		$format_string .= "." . int(rand(10));
	}
	$format_string .= $rand_size_flag[int(rand(6))];
	$format_string .= "$type";
	if ($verbose) {
		print "generated format string : $format_string\n";
	}
	return $format_string;
}

my $filename = "random_tests.c";
my $ft_filename = "ft_random_tests.c";


GetOptions ("clean" => \$clean,
			"limit=i" => \$gen_limit,
			"libpath=s" => \$libftprintf_dir,
			"verbose"  => \$verbose)
or die("Error in command line arguments\n");

if ($libftprintf_dir eq "") {
	die("No valid project dir found\n");
}

print_banner();

open(my $ft_file_gen, ">", "$ft_filename")
	or die "Can't open < random_tests.c: $!";

open(my $real_file_gen, ">", "$filename")
	or die "Can't open < random_tests.c: $!";

generate_base_file($real_file_gen);
generate_base_file($ft_file_gen);

print "generating random format strings...\n";

for (0..100) {
	push_generated_function($ft_file_gen, $real_file_gen);
}

end_file($ft_file_gen);
end_file($real_file_gen);

print "finished.\n";
print "compiling data...\n";

system("make -C $libftprintf_dir") == 0
	or die "no valid makefile found";
system("clang ft_random_tests.c -I $libftprintf_dir/includes -L$libftprintf_dir -lftprintf -o ft_out") == 0
	or die "system command clang failed on ft_random_test.c";
system("clang random_tests.c -o ft_real") == 0
	or die "system command clang failed on random_test.c";

close($ft_file_gen);
close($real_file_gen);
