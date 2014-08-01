# The LearningOnline Network with CAPA - LON-CAPA
# Serves up the table of contents in JSON
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
package Apache::lc_ui_contents;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common);
use Apache::lc_entity_sessions();
use Apache::lc_entity_courses();
use Apache::lc_entity_contents();
use Apache::lc_entity_users();
use Apache::lc_ui_utils;
use Apache::lc_json_utils();
use Apache::lc_logs;

# ==== Main handler
#
sub toc {
   my $r = shift;
   my $display=&Apache::lc_entity_contents::toc_to_display(
                  &Apache::lc_entity_courses::load_contents(
                      &Apache::lc_entity_sessions::course_entity_domain()));
   if ($display) {
      $r->print(&Apache::lc_json_utils::perl_to_json($display));
   } else {
      $r->print('[]');
   }
}
#
# Accessing course content
# Remember where we are, set breadcrumbs, etc, etc ...
#
sub register {
   my ($r,$assetid)=@_;
   $r->print('{ "url" : "/res/msu/zaphod/hello.html",
                "prev" : "oE4NvBu8Hc7s2rGfrKF_25271_1406233153",
                "next" : "nQKqmGhgsoudh21NjMd_25271_1406233153" }');
}

sub handler {
   my $r = shift;
   $r->content_type('application/json; charset=utf-8');
   my %content=&Apache::lc_entity_sessions::posted_content();
   if ($content{'command'} eq 'register') {
# Accessing a specific piece of content
     &register($r,$content{'assetid'});
   } else {
# Just list table of contents
     &toc($r);
   }
   return OK;
}
1;
__END__

