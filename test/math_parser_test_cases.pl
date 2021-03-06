#!/usr/bin/perl

# The LearningOnline Network with CAPA - LON-CAPA
# check test cases
#
# Copyright (C) 2014 Michigan State University Board of Trustees
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use warnings;
use utf8;

use Try::Tiny;

use lib '/home/httpd/lib/perl';
use Apache::lc_connection_utils(); # to avoid a circular reference problem
use Apache::lc_ui_localize;

use aliased 'Apache::math::math_parser::CalcException';
use aliased 'Apache::math::math_parser::ParseException';
use aliased 'Apache::math::math_parser::Parser';
use aliased 'Apache::math::math_parser::ENode';
use aliased 'Apache::math::math_parser::CalcEnv';
use aliased 'Apache::math::math_parser::Quantity';

# please add your own !!!
my %unit_mode_cases = (
    "1e-1/2+e-1/2" => "e-0.45",
    "1/2s" => "0.5`(s^-1)",
    "(1/2)s" => "0.5`s",
    "1m/2s" => "0.5`(m*s^-1)",
    "(1+2)(m/s)" => "3`(m*s^-1)",
    "2 m^2 s" => "2`(m^2*s)",
    "2(m/s)kg" => "2`(m*s^-1*kg)",
    "sqrt(2) m" => "sqrt(2)`m",
    "2m/s*3m/s" => "6`(m^2*s^-2)",
    "2m/s*c" => "(2*299792458)`(m^2*s^-2)",
    "c*(60s*60*24*365.25)" => "1 ly",
    "1 J" => "1`(kg*m^2*s^-2)",
    "sqrt(34J/(2*45kg))" => "0.614636297`(m*s^-1)",
    "sqrt((2*45 eV)/(345 mg))" => "2.04440481E-7`(m*s^-1)",
    "2 pi hbar c" => "2 pi (1.956E9 J) * (1.616199E-35 m)",
    "2%c" => "2*c/100",
    "[1m;2m]+[3m;4m]" => "[4m;6m]",
    "[1m:2m]+[2m:4m]" => "[1m:4m]",
    "intersection([1m:2m];[2m:4m])" => "[2m:2m]",
    "intersection([1m:2m];[3m:4m])" => "(8m:8m)",
    "intersection([1m:3m]+[5m:7m];[2m:4m]+[6m:9m])" => "[6m:7m]+[2m:3m]",
    "{1m;2m;3m}+{2m;3m;4m}" => "{4m;3m;2m;1m}",
    "1m < 2m" => "1",
    "(15 kg+40kg)*(4.5 m/s)^2/2 < 600 J" => "1",
    "c*sqrt(1-50s/300s)>90%c" => "1",
    "(30+50)<(300+500)" => "1",
    "3s*[4;5;6]m/s" => "[12m;15m;18m]",
    "300 kW*50s" => "15 MJ",
    "1000 hPa*2 m^2" => "200 kN"
);

my %symbolic_mode_cases = (
    "1e-1/2+e-1/2" => "e-0.45",
    "x+y" => "42.23",
    "1/2x" => "x/2",
    "2sqrt(4)" => "4",
    "ln(x)+ln(y)" => "ln(x*y)",
    "abs(-1)" => "1",
    "log10(10)" => "1",
    "factorial(4)" => "4!",
    "asin(sin(pi/4))" => "pi/4",
    "acos(cos(pi/4))" => "pi/4",
    "atan(tan(pi/4))" => "pi/4",
    "sqrt(-1)" => "i",
    "i^2" => "-1",
    "exp(i*pi)+1" => "0",
    "1/inf" => "0",
    "1+inf" => "inf",
    "[1;2]*2" => "[2;4]",
    "[1;2].[3;4]" => "11",
    "[1;2]*[3;4]" => "[3;8]",
    "matrix([1;2];[3;4]) + matrix([5;6];[7;8])" => "matrix([6;8];[10;12])",
    "[[5;6];[7;8]] - [[1;2];[3;4]]" => "[[4;4];[4;4]]",
    "-[[1;2];[3;4]]" => "[[-1;-2];[-3;-4]]",
    "[[1;2;3];[4;5;6]] . [7;8;9]" => "[50;122]",
    "[[1;2;3];[4;5;6]] * [7;8]" => "[[7;14;21];[32;40;48]]",
    "[[1;2;3];[4;5;6]] . [[7;8];[9;10];[11;12]]" => "[[58;64];[139;154]]",
    "[[1;2];[3;4]]^2" => "[[1;4];[9;16]]",
    "sum(a^2; a; 1; 5)" => "55",
    "product(a^2; a; 1; 5)" => "14400",
    "binomial(5;3)" => "10",
    "13 + 1 + 20 + 8" => "x",
    "1/(1/2-1/3-1/7)" => "x",
    "[x:2x]+(2x:4x]" => "[x:4x]",
    "[x:2x]+(x:4x]+[7x:9x]+[8x:10x)" => "[x:4x]+[7x:10x)",
    "{1;2;3}+{2;3;4}" => "{4;3;2;1}",
    "intersection({1;2;3};{2;3;4})" => "{3;2}",
    "2 >= 2" => "1",
    "2*2 = 4" => "1",
);

my @compare_test_cases = (
    ['1', '1', Quantity->IDENTICAL],
    ['1m', '1m', Quantity->IDENTICAL],
    ['[1;2]', '[1;2]', Quantity->IDENTICAL],
    ['[1m;2m]', '[1m;2m]', Quantity->IDENTICAL],
    ['[[1;2;3];[4;5;6]]', '[[1;2;3];[4;5;6]]', Quantity->IDENTICAL],
    ['1', '[1;2]', Quantity->WRONG_TYPE],
    ['[1;2]', '[[1];[2]]', Quantity->WRONG_TYPE],
    ['[1;2]', '[1;2;3]', Quantity->WRONG_DIMENSIONS],
    ['[[1;2;3];[4;5;6]]', '[[1;2;3];[4;5;6];[7;8;9]]', Quantity->WRONG_DIMENSIONS],
    ['[[1;2;3];[4;5;6]]', '[[1;2];[4;5]]', Quantity->WRONG_DIMENSIONS],
    ['1m', '1', Quantity->MISSING_UNITS],
    ['1m', '2', Quantity->MISSING_UNITS],
    ['[1m;2m]', '[1;2]', Quantity->MISSING_UNITS],
    ['1', '1m', Quantity->ADDED_UNITS],
    ['1', '2m', Quantity->ADDED_UNITS],
    ['[1;2]', '[1m;2m]', Quantity->ADDED_UNITS],
    ['1m', '1s', Quantity->WRONG_UNITS],
    ['1m', '2s', Quantity->WRONG_UNITS],
    ['[1m;2m]', '[1s;3s]', Quantity->WRONG_UNITS],
    ['1m', '2m', Quantity->WRONG_VALUE],
    ['[1;2]', '[1;3]', Quantity->WRONG_VALUE],
    ['[1:2]', '[1:3]', Quantity->WRONG_VALUE],
    ['[1:2]', '[1:2)', Quantity->WRONG_ENDPOINT],
    ['{1m;2m;3m}', '{2s;3s;1s}', Quantity->WRONG_UNITS],
    ['{1;2;3}', '{1;2;4}', Quantity->WRONG_VALUE],
    ['{1;2;3;3;3;3}','{1;2;4}', Quantity->WRONG_VALUE],
    ['{1;2;3;3;3;3}','{1;2;3}', Quantity->IDENTICAL],
    ['{1;2;3} N+ {3;3;3} N','{1;2;3} N', Quantity->IDENTICAL],
    ['[1:4)+[2:16)+[2:3]','[1:16)', Quantity->IDENTICAL],
    ['[(3 m/s)^2/(2*9.81 m/s^2):1m)','[0.5*(3 m/s)^2/(9.81 m/s^2):1m)', Quantity->IDENTICAL]
);

sub test {
    my( $parser, $env, $expression, $expected, $tolerance ) = @_;
    if (!defined $tolerance) {
        $tolerance = 1e-5;
    }
    try {
        my $quantity = $parser->parse($expression)->calc($env);
        my $expected_quantity = $parser->parse($expected)->calc($env);
        if (!$quantity->equals($expected_quantity, $tolerance)) {
            die "Wrong result: ".$quantity." instead of ".$expected_quantity;
        }
    } catch {
        if (UNIVERSAL::isa($_,CalcException)) {
            die "Error calculating $expression: ".$_->getLocalizedMessage()."\n";
        } elsif (UNIVERSAL::isa($_,ParseException)) {
            die "Error parsing $expression: ".$_->getLocalizedMessage()."\n";
        } else {
            die "Internal error for $expression: $_\n";
        }
    }
}

sub compare_test {
    my( $parser, $env, $test_case, $tolerance, $mode ) = @_;
    my ($expected, $input, $expected_code) = @$test_case;
    if (!defined $tolerance) {
        $tolerance = 1e-5;
    }
    if (!defined $mode) {
       $mode='normal';
    }
    try {
        my $expected_quantity = $parser->parse($expected)->calc($env);
        my $input_quantity = $parser->parse($input)->calc($env);
        my $code;
        if ($mode eq 'ne') {
           $code = $expected_quantity->ne($input_quantity, $tolerance);
        } elsif ($mode eq 'contained') {
           $code = $expected_quantity->contains($input_quantity);
        } else {
           $code = $expected_quantity->compare($input_quantity, $tolerance);
        }
        if ($code != $expected_code) {
            die "Wrong result in compare test: ".$code." instead of ".$expected_code;
        }
    } catch {
        if (UNIVERSAL::isa($_,CalcException)) {
            die "Error calculating $input: ".$_->getLocalizedMessage()."\n";
        } elsif (UNIVERSAL::isa($_,ParseException)) {
            die "Error parsing $input: ".$_->getLocalizedMessage()."\n";
        } else {
            die "Internal error for $input: $_\n";
        }
    }
}

Apache::lc_ui_localize::set_language('en');
# unit mode
my $implicit_operators = 1;
my $unit_mode = 1;
my $p = Parser->new($implicit_operators, $unit_mode);
my $env = CalcEnv->new($unit_mode);
foreach my $s (keys %unit_mode_cases) {
    test($p, $env, $s, $unit_mode_cases{$s});
}

# now let's try to use custom units !
$env->setUnit("peck", "2 gallon");
$env->setUnit("bushel", "8 gallon");
$env->setUnit("gallon", "4.4 L");
test($p, $env, "4 peck + 2 bushel", "106`L", "1%");

# compare test
foreach my $test_case (@compare_test_cases) {
    compare_test($p, $env, $test_case);
}

# Some special compare cases
#
compare_test($p,$env,['17','42',1],0,'ne');
compare_test($p,$env,['[3:4)','3.6',1],0,'contained');
compare_test($p,$env,['{4 N; 5 N; 6 N}','{5 N; 4 N; 6 N}',Quantity->IDENTICAL],0);

compare_test($p,$env,['{1 N; 2 N; 3 N}','{2;3;1} N',Quantity->IDENTICAL],0);
compare_test($p,$env,['[3 N:4 N)','3.7 N',1],0,'contained');
compare_test($p,$env,['[3:4) N','3.8 N',1],0,'contained');

compare_test($p,$env,['[3:4) N + (5:17] N','3.9 N',1],0,'contained');
compare_test($p,$env,['[3:4) N + (5:17] N','4.5 N',0],0,'contained');


# symbolic mode
$unit_mode = 0;
$p = Parser->new($implicit_operators, $unit_mode);
$env = CalcEnv->new($unit_mode);
$env->setVariable("x", 42);
$env->setVariable("y", 2.3e-1);
foreach my $s (keys %symbolic_mode_cases) {
    test($p, $env, $s, $symbolic_mode_cases{$s});
}
print "All tests OK !\n";
