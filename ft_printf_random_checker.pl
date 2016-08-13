#!/usr/bin/perl

#use strict;
use warnings;
use Getopt::Long;
use	Cwd qw(abs_path);

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

sub push_generated_function
{
	my ($ft_file, $real_file) = @_;

	$count_lines++;
	my $type = $rand_types[int(rand(6))];
	my $format_string = generate_random_format_string($type);
	if ($type eq "s")
	{
		print $real_file "	printf(\"Bonjour " . $format_string . " ceci est un test\\n\", \"first test\");fflush(stdout);\n";
		print $ft_file "	ft_printf(\"Bonjour " .  $format_string . " ceci est un test\\n\", \"first test\");\n";
		#print $real_file "	printf(\"format string : \'%s\' with value : %s\", \"$format_string\", \"first test\");";
		push(@format_strings_list, "format string : \'$format_string\' with value : \'first test\'");
		#print $ft_file "	printf(\"format string : \'%s\' with value : %s\", \"$format_string\", \"first test\");";
	}
	else
	{
		my $rand_value = int(rand(10000000000));
		print $real_file "	i = " . $rand_value . ";\n	printf(\"Bonjour " . $format_string . " ceci est un test\\n\", i);fflush(stdout);\n";
		print $ft_file "	i = " . $rand_value . ";\n	ft_printf(\"Bonjour " . $format_string . " ceci est un test\\n\", i);\n";
		#print $real_file "	printf(\"format string : \'%s\' with value : %lld\", \"$format_string\", i);";
		push(@format_strings_list, "format string : \'$format_string\' with value : $rand_value");
		#print $ft_file "	printf(\"format string : \'%s\' with value : %lld\", \"$format_string\", i);";
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
		my @values;

		while (<WRITER>) {
			push(@values, readline(WRITER));
		}
		close WRITER;
		#print @values;
		return (@values);
	}
	else
	{
		exec($binary)
			or die ("printf failed");
		exit;
	}
}

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

print "Done.\n";
print "$count_lines generated lines\n";
print "compiling .c files...\n";

system("/usr/bin/make -C $libftprintf_dir >/dev/null") == 0
	or die "make encountered a problem";
system("/usr/bin/clang ft_random_tests.c -I $libftprintf_dir/includes -I $libftprintf_dir/libft/includes -L$libftprintf_dir -lftprintf -o ft_out 2>&-") == 0
	or die "system command clang failed on ft_random_test.c";
system("/usr/bin/clang random_tests.c -I $libftprintf_dir/includes -I $libftprintf_dir/libft/includes -o ft_real 2>&-") == 0
	or die "system command clang failed on random_test.c";

print "Done.\n";
print "Executing programs...\n";

my @ft_values = pull_data_form_binary("./ft_out");
my @real_values = pull_data_form_binary("./ft_real");

print "Done.\n";
print "Computing data...\n";

#system("./ft_out > ft_out_out ; ./ft_real > ft_real_out ; diff ft_out_out ft_real_out > diff_file ; cat diff_file");
foreach my $i (0..$gen_limit) {
	if ($ft_values[$i] ne $real_values[$i]) {
		print STDOUT	"diff : \n";
		print STDOUT	"ft_printf	: \'" . $ft_values[$i] . "\'\n";
		print STDOUT	"printf		: \'" . $real_values[$i] . "\'\n";
		print STDOUT	"on " . $format_strings_list[$i] . "\n";
		print STDOUT	"---------\n";
	}
}

print "Done.\n";

chdir("..");
#rmdir("./tmp");
close($ft_file_gen);
close($real_file_gen);
