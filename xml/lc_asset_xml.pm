# The LearningOnline Network with CAPA - LON-CAPA
# The central XML parser
#
# Copyright (C) 2014 Michigan State University Board of Trustees
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
package Apache::lc_asset_xml;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common :http);
use HTML::TokeParser();
use Apache::lc_asset_safeeval();
use Apache::lc_ui_localize;

# Import all tag definitions (without "()")
#
use Apache::lc_xml_standard;
use Apache::lc_xml_localize;
use Apache::lc_xml_forms;
use Apache::lc_xml_perl;
use Apache::lc_xml_trees;
use Apache::lc_xml_tables;
use Apache::lc_xml_conditionals;
use Apache::lc_xml_include;
use Apache::lc_xml_gadgets;
use Apache::lc_logs;

use Data::Dumper;

sub error {
   my ($stack,$type,$notes)=@_;
   $notes->{'type'}=$type;
   push(@{$stack->{'errors'}},$notes);
}

#
# Go up the stack until argument with name is found
#
sub cascade_attribute {
   my ($name,$stack)=@_;
   if ($stack->{'tags'}) {
      for (my $i=$#{$stack->{'tags'}}; $i>=0; $i--) {
         if (defined($stack->{'tags'}->[$i]->{'args'}->{$name})) {
            return $stack->{'tags'}->[$i]->{'args'}->{$name};
         }
      }
   }
   return undef;
}

#
# Return the attribute $name from enclosing $tag
#
sub tag_attribute {
   my ($tag,$name,$stack)=@_;
   if ($stack->{'tags'}) {
      for (my $i=$#{$stack->{'tags'}}; $i>=0; $i--) {
         if ($stack->{'tags'}->[$i]->{'name'} eq $tag) {
            return $stack->{'tags'}->[$i]->{'args'}->{$name};
         }
      }
   }
   return undef;
}


# Output a piece of text
#
sub process_text {
   my ($p,$safe,$stack,$status,$target,$token)=@_;
   return $token->[1];
}

# Process an HTML tag, call routines if defined
#
sub process_tag {
   my ($type,$tag,$p,$safe,$stack,$status,$target,$token)=@_;
# The output that this script is going to produce
   my $tag_output='';
# The routine that would run any commands for this
# These would be things that should always be run independent of target
# prior to actually rendering anything
   my $cmdtag=$type.'_'.$tag.'_cmd';
# The routine that would produce the output
   my $outtag=$type.'_'.$tag.'_'.$target;
   no strict 'refs';
   if (defined(&$cmdtag)) {
      &{$cmdtag}($safe,$stack);
   }
   if (defined(&$outtag)) {
      $tag_output.=&{$outtag}($p,$safe,$stack,$token);
   } elsif ($target eq 'html') {
# If nothing is defined and we render for html, just output what we got
      $tag_output.=&default_html($token);
   }
   use strict 'refs';
}

# Give out the tag again unchanged, except for the evaluated args
#
sub default_html {
   my ($token)=@_;
   if ($token->[0] eq 'S') {
# Start tag
      my @arguments=keys(%{$token->[2]});
      if ($#arguments<0) {
# No arguments here, just return
         return $token->[-1];
      } else {
# Rebuild this, since arguments may have been evaluated
         return '<'.$token->[1].' '.join(' ',map{$_.'="'.$token->[2]->{$_}.'"'}(@arguments)).'>';
      }
   } else {
# End tag
      return $token->[-1];
   }
}

# Central parser routine
#
sub parser {
   my ($p,$safe,$stack,$status,$target)=@_;
   my $output='';
   while (my $token = $p->get_token) {
      if ($token->[0] eq 'T') {
         $output.=&process_text($p,$safe,$stack,$status,$target,$token);
      } elsif ($token->[0] eq 'S') {
# A start tag - evaluate the attributes in here
         foreach my $key (keys(%{$token->[2]})) {
            $token->[2]->{$key}=&Apache::lc_asset_safeeval::texteval($safe,$token->[2]->{$key}); 
         }
# - remember for embedded tags and for the end tag
         push(@{$stack->{'tags'}},{ 'name' => $token->[1], 'args' => $token->[2] });
         $output.=&process_tag('start',$token->[1],$p,$safe,$stack,$status,$target,$token);
      } elsif ($token->[0] eq 'E') {
# An ending tag
         $output.=&process_tag('end',$token->[1],$p,$safe,$stack,$status,$target,$token);
# Unexpected ending tags
         if ($#{$stack->{'tags'}}>=0) {
            if ($stack->{'tags'}->[-1]->{'name'} ne $token->[1]) {
               &error($stack,'unexpected_ending',{'expected' => $stack->{'tags'}->[-1]->{'name'},
                                                  'found'    => $token->[1] });
            }
         } else {
            &error($stack,'unexpected_ending',{'expected' => '-',
                                               'found'    => $token->[-1] });
         }
# Pop the stack again
         pop(@{$stack->{'tags'}});
      } else {
         $output.=$token->[-1];
      }
   }
# The tag stack should be empty again
   for (my $i=0;$i<=$#{$stack->{'tags'}};$i++) {
      &error($stack,'missing_ending',{'expected' => $stack->{'tags'}->[$i]->{'name'} });
   }
   return $output;
}


# ==== Render for target
#
sub target_render {
   my ($fn,$target)=@_;
# Clear out and initialize everything
   my $p=HTML::TokeParser->new($fn);
   unless ($p) {
      &logerror("Could not inititialize parser for file [$fn]");
      return (undef,undef);
   }
   $p->empty_element_tags(1);
   my $safe=&Apache::lc_asset_safeeval::init_safe();
   my $stack={};
   my $status;
#FIXME: actually find status
   my $output=&parser($p,$safe,$stack,$status,$target);
   return ($output,$stack);
}


# ==== Main handler
#
sub handler {
   my $r = shift;
   my $fn=$r->filename();
   unless (-e $fn) {
      return HTTP_NOT_FOUND;
   }
   $r->content_type('text/html; charset=utf-8');
   $r->print((&target_render($fn,'html'))[0]);
   return OK;
}

#FIXME: debug!!!!
#
sub start_testtag_html {
   my ($p,$safe,$stack,$token)=@_;
   return '<pre>'.Dumper($stack).'</pre>'.
          '<br />value:'.&cascade_attribute('value',$stack).
          '<br />id of part:'.&tag_attribute('part','id',$stack);
}

1;
__END__
