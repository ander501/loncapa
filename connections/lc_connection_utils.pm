# The LearningOnline Network with CAPA - LON-CAPA
#
# Utilities for cluster connections
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
package Apache::lc_connection_utils;

use strict;
use Socket;
use APR::Table;
use Apache2::Const qw(:common :http);

use Apache::lc_connection_handle();
use Apache::lc_init_cluster_table();


#
# Get the timezone for a domain
#
sub domain_timezone {
   my ($domain)=@_;
   my $connection_table=&Apache::lc_init_cluster_table::get_connection_table();
   return ($connection_table->{'cluster_table'}->{'domains'}->{$domain}->{'timezone'});
}

#
# Get the locale for a domain
#
sub domain_locale {
   my ($domain)=@_;
   my $connection_table=&Apache::lc_init_cluster_table::get_connection_table();
   return ($connection_table->{'cluster_table'}->{'domains'}->{$domain}->{'locale'});
}

#
# Is a host a library server for a domain?
#
sub is_library_server {
   my ($host,$domain)=@_;
   my $connection_table=&Apache::lc_init_cluster_table::get_connection_table();
   return ($connection_table->{'cluster_table'}->{'hosts'}->{$host}->{'domains'}->{$domain}->{'function'} eq 'library');
}

#
# Is this a library server for a domain?
#
sub we_are_library_server {
   my ($domain)=@_;
   my $connection_table=&Apache::lc_init_cluster_table::get_connection_table();
   return ($connection_table->{'cluster_table'}->{'hosts'}->{$connection_table->{'self'}}->{'domains'}->{$domain}->{'function'} eq 'library');
}

#
# Get the cluster host
#
sub cluster_manager_host {
   my $connection_table=&Apache::lc_init_cluster_table::get_connection_table();
   return $connection_table->{'manager'};
}

#
# Get a random library server in the domain
#
sub random_library_server {
   my ($domain)=@_;
   my $connection_table=&Apache::lc_init_cluster_table::get_connection_table();
   my @libraries=split(/\,/,$connection_table->{'libraries'}->{$domain});
# First entry is empty! Take a random one
   my $random_library=$libraries[1+int(rand($#libraries))];
   if (&online($random_library)) {
      return $random_library;
   }
# Wow, that one was offline. Take the first one that's online.
   foreach my $library (@libraries) {
      unless ($library) { next; }
      if (&online($library)) {
         return $library;
      }
   }
   return undef;
}

#
# Check if a server is online
#
sub online {
   my ($host)=@_;
# If it's us, we are online or we weren't here
   if ($host eq &host_name()) { return 1; }
# Okay, it's not us. Contact them
   my ($code,$response)=&Apache::lc_dispatcher::command_dispatch($host,'online');
   if (($code eq HTTP_OK) && ($response eq 'ok')) { return 1; }
# Nope
   return 0;
}

#
# This gets called when a remote server asks "online?"
#
sub local_online {
   return 'ok';
}

#
# What is our hostname?
#
sub host_name {
   my $connection_table=&Apache::lc_init_cluster_table::get_connection_table();
   return $connection_table->{'self'};
}

#
# What is our default domain?
#
sub default_domain {
   my $connection_table=&Apache::lc_init_cluster_table::get_connection_table();
   return $connection_table->{'cluster_table'}->{'hosts'}->{$connection_table->{'self'}}->{'default'};
}

#
# Get posted data out of a request
# Takes the request object
#
sub extract_content {
   my ($r)=@_;
   my $content='';
   if ($r->headers_in->{"Content-length"}>0) {
      $r->read($content,$r->headers_in->{"Content-length"});
   }
   return $content;
}

BEGIN {
   &Apache::lc_connection_handle::register('online',undef,undef,undef,\&local_online);
}

1;
__END__
