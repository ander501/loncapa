# The LearningOnline Network with CAPA - LON-CAPA
# QVector
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

##
# A vector of quantities
##
package Apache::math::math_parser::QVector;

use strict;
use warnings;
use utf8;

use aliased 'Apache::math::math_parser::CalcException';
use aliased 'Apache::math::math_parser::Quantity';
use aliased 'Apache::math::math_parser::QVector';

use overload
    '""' => \&toString,
    '+' => \&qadd,
    '-' => \&qsub,
    '*' => \&qmult,
    '/' => \&qdiv,
    '^' => \&qpow;

##
# Constructor
# @param {Quantity[]} quantities
##
sub new {
    my $class = shift;
    my $self = {
        _quantities => shift,
    };
    bless $self, $class;
    return $self;
}

# Attribute helpers

##
# The components of the vector.
# @returns {Quantity[]}
##
sub quantities {
    my $self = shift;
    return $self->{_quantities};
}


##
# Returns a readable view of the object
# @returns {string}
##
sub toString {
    my ( $self ) = @_;
    my $s = "[";
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        $s .= $self->quantities->[$i]->toString();
        if ($i != scalar(@{$self->quantities}) - 1) {
            $s .= "; ";
        }
    }
    $s .= "]";
    return $s;
}

##
# Equality test
# @param {QVector} v
# @optional {string|float} tolerance
# @returns {boolean}
##
sub equals {
    my ( $self, $v, $tolerance ) = @_;
    if (!$v->isa(QVector)) {
        return 0;
    }
    if (scalar(@{$self->quantities}) != scalar(@{$v->quantities})) {
        return 0;
    }
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        if (!$self->quantities->[$i]->equals($v->quantities->[$i], $tolerance)) {
            return 0;
        }
    }
    return 1;
}

##
# Compare this vector with another one, and returns a code.
# Returns Quantity->WRONG_TYPE if the parameter is not a QVector.
# @param {Quantity|QVector|QMatrix|QSet|QInterval} v
# @optional {string|float} tolerance
# @returns {int} Quantity->WRONG_TYPE|WRONG_DIMENSIONS|MISSING_UNITS|ADDED_UNITS|WRONG_UNITS|WRONG_VALUE|IDENTICAL
##
sub compare {
    my ( $self, $v, $tolerance ) = @_;
    if (!$v->isa(QVector)) {
        return Quantity->WRONG_TYPE;
    }
    if (scalar(@{$self->quantities}) != scalar(@{$v->quantities})) {
        return Quantity->WRONG_DIMENSIONS;
    }
    my @codes = ();
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        push(@codes, $self->quantities->[$i]->compare($v->quantities->[$i], $tolerance));
    }
    my @test_order = (Quantity->WRONG_TYPE, Quantity->WRONG_DIMENSIONS, Quantity->MISSING_UNITS, Quantity->ADDED_UNITS,
        Quantity->WRONG_UNITS, Quantity->WRONG_VALUE);
    foreach my $test (@test_order) {
        foreach my $code (@codes) {
            if ($code == $test) {
                return $test;
            }
        }
    }
    return Quantity->IDENTICAL;
}

##
# Interprets this vector as an unordered list of quantities, compares it with another one, and returns a code.
# Returns Quantity->WRONG_TYPE if the parameter is not a QVector.
# @param {Quantity|QVector|QMatrix|QSet|QInterval} v
# @optional {string|float} tolerance
# @returns {int} Quantity->WRONG_TYPE|WRONG_DIMENSIONS|MISSING_UNITS|ADDED_UNITS|WRONG_UNITS|WRONG_VALUE|IDENTICAL
##
sub compare_unordered {
    my ( $self, $v, $tolerance ) = @_;
    if (!$v->isa(QVector)) {
        return Quantity->WRONG_TYPE;
    }
    if (scalar(@{$self->quantities}) != scalar(@{$v->quantities})) {
        return Quantity->WRONG_DIMENSIONS;
    }
    my @quantities_1 = sort {$a <=> $b} @{$self->quantities};
    my $v1 = QVector->new(\@quantities_1);
    my @quantities_2 = sort {$a <=> $b} @{$v->quantities};
    my $v2 = QVector->new(\@quantities_2);
    return($v1->compare($v2, $tolerance));
}

##
# Addition
# @param {QVector} v
# @returns {QVector}
##
sub qadd {
    my ( $self, $v ) = @_;
    if (!$v->isa(QVector)) {
        die CalcException->new("Vector addition: second member is not a vector.");
    }
    if (scalar(@{$self->quantities}) != scalar(@{$v->quantities})) {
        die CalcException->new("Vector addition: the vectors have different sizes.");
    }
    my @t = (); # array of Quantity
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        $t[$i] = $self->quantities->[$i] + $v->quantities->[$i];
    }
    return QVector->new(\@t);
}

##
# Substraction
# @param {QVector} v
# @returns {QVector}
##
sub qsub {
    my ( $self, $v ) = @_;
    if (!$v->isa(QVector)) {
        die CalcException->new("Vector substraction: second member is not a vector.");
    }
    if (scalar(@{$self->quantities}) != scalar(@{$v->quantities})) {
        die CalcException->new("Vector substraction: the vectors have different sizes.");
    }
    my @t = (); # array of Quantity
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        $t[$i] = $self->quantities->[$i] - $v->quantities->[$i];
    }
    return QVector->new(\@t);
}

##
# Negation
# @returns {QVector}
##
sub qneg {
    my ( $self ) = @_;
    my @t = (); # array of Quantity
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        $t[$i] = $self->quantities->[$i]->qneg();
    }
    return QVector->new(\@t);
}

##
# Multiplication by a scalar, or element-by-element multiplication by a vector
# @param {Quantity|QVector} qv
# @returns {QVector}
##
sub qmult {
    my ( $self, $qv ) = @_;
    if (!$qv->isa(Quantity) && !$qv->isa(QVector)) {
        die CalcException->new("Vector multiplication: second member is not a quantity or a vector.");
    }
    my @t = (); # array of Quantity
    if ($qv->isa(Quantity)) {
        for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
            $t[$i] = $self->quantities->[$i] * $qv;
        }
    } else {
        if (scalar(@{$self->quantities}) != scalar(@{$qv->quantities})) {
            die CalcException->new("Vector element-by-element multiplication: the vectors have different sizes.");
        }
        for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
            $t[$i] = $self->quantities->[$i]->qmult($qv->quantities->[$i]);
        }
    }
    return QVector->new(\@t);
}

##
# Division
# @param {Quantity|QVector} qv
# @returns {QVector}
##
sub qdiv {
    my ( $self, $qv ) = @_;
    if (!$qv->isa(Quantity) && !$qv->isa(QVector)) {
        die CalcException->new("Vector division: second member is not a quantity or a vector.");
    }
    my @t = (); # array of Quantity
    if ($qv->isa(Quantity)) {
        for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
            $t[$i] = $self->quantities->[$i] / $qv;
        }
    } else {
        if (scalar(@{$self->quantities}) != scalar(@{$qv->quantities})) {
            die CalcException->new("Vector element-by-element division: the vectors have different sizes.");
        }
        for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
            $t[$i] = $self->quantities->[$i]->qdiv($qv->quantities->[$i]);
        }
    }
    return QVector->new(\@t);
}

##
# Power by a scalar
# @param {Quantity} q
# @returns {QVector}
##
sub qpow {
    my ( $self, $q ) = @_;
    if (!$q->isa(Quantity)) {
        die CalcException->new("Vector power: second member is not a quantity.");
    }
    $q->noUnits("Power");
    my @t = (); # array of Quantity
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        $t[$i] = $self->quantities->[$i] ^ $q;
    }
    return QVector->new(\@t);
}

##
# Dot product
# @param {QVector} v
# @returns {Quantity}
##
sub qdot {
    my ( $self, $v ) = @_;
    if (!$v->isa(QVector)) {
        die CalcException->new("Vector dot product: second member is not a vector.");
    }
    if (scalar(@{$self->quantities}) != scalar(@{$v->quantities})) {
        die CalcException->new("Vector dot product: the vectors have different sizes.");
    }
    my $q = Quantity->new(0);
    for (my $i=0; $i < scalar(@{$self->quantities}); $i++) {
        $q = $q + $self->quantities->[$i]->qmult($v->quantities->[$i]);
    }
    return $q;
}

##
# Equals
# @param {Quantity|QVector|QMatrix|QSet|QInterval} v
# @optional {string|float} tolerance
# @returns {Quantity}
##
sub qeq {
    my ( $self, $v, $tolerance ) = @_;
    my $q = $self->equals($v, $tolerance);
    return Quantity->new($q);
}

1;
__END__
