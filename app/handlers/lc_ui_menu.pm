# The LearningOnline Network with CAPA - LON-CAPA
# UI Menu
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
package Apache::lc_ui_menu;

use strict;
use Apache2::RequestRec();
use Apache2::Const qw(:common);

use Apache::lc_ui_localize;
use Apache::lc_entity_sessions();
use Apache::lc_authorize;

sub submenu {
   my ($title,$content)=@_;
   return '"'.&mt($title).'" : {'.$content.'}';
}

sub menu_item {
   my ($title,$text,$function)=@_;
   return '"menu_'.$title.'" : "'.&mt($text).'&'.$function.'"';
}

# ==== Main handler
#
sub handler {
# Get request object
   my $r = shift;
   $r->content_type('application/json; charset=utf-8');
   my $menu='{';
   my $course_menu='';
   my $grade_menu='';
   if (&Apache::lc_entity_sessions::session_id()) {
      $menu.=&menu_item('dashboard','Dashboard','dashboard()').',';
# Places submenu
      $menu.=&submenu("Places",
         &menu_item('courses','Courses','courses()').','.
         &menu_item('communities','Communities','communities()').','.
         &menu_item('portfolio','Portfolio','portfolio()')).',';
      if (&Apache::lc_entity_sessions::course_entity_domain()) {
# We are in a course or community
         $menu.=&menu_item('content','Content','content()').',';
         if (&Apache::lc_entity_courses::course_type(&Apache::lc_entity_sessions::course_entity_domain()) eq 'regular') {
            $grade_menu.=&menu_item('my_grades','My Grades','my_grades()').',';
            if (&allowed_any_section('modify_grade',undef,&Apache::lc_entity_sessions::course_entity_domain())) {
               $grade_menu.=&menu_item('grading','Grading','grading()').',';
            }
         }
# Course settings into course menu
         if (&allowed_course('modify_settings',undef,&Apache::lc_entity_sessions::course_entity_domain())) {
            $course_menu.= &menu_item('coursepreferences','Preferences','coursepreferences()').',';
         }
# Enrollment settings into Admin menu
         if (&allowed_any_section('view_role','student',&Apache::lc_entity_sessions::course_entity_domain())) {
            $course_menu.=&submenu('Enrollment',
                &menu_item('courselist','List','courselist()').
                (&allowed_any_section('modify_role','student',&Apache::lc_entity_sessions::course_entity_domain())?','.
                   &menu_item('add_user_to_courselist','Manually Enroll','add_user_to_courselist()').','.
                   &menu_item('upload_users_to_courselist','Upload List','upload_users_to_courselist()'):'')).',';
         }
      }
# Grade menu
     if ($grade_menu) {
        $grade_menu=~s/\s*\,\s*$//gs;
        $menu.=&submenu("Grades",$grade_menu).',';
     }
# Can we administrate course things? Fourth to last item with collected admin stuff
     if ($course_menu) {
        $course_menu=~s/\s*\,\s*$//gs;
        my $course_menu_title='Community';
        if (&Apache::lc_entity_courses::course_type(&Apache::lc_entity_sessions::course_entity_domain()) eq 'regular') {
           $course_menu_title='Course';
        }
        $menu.=&submenu($course_menu_title,$course_menu).',';
     }
# User submenu, third to last item when logged in
      $menu.=&submenu("User",
         &menu_item('preferences','Preferences','preferences()').','.
         &menu_item('messages','Messages','messages()').','.
         &menu_item('calendar','Calendar','calendar()').','.
         &submenu('Bookmarks',
             &menu_item('listbookmarks','Show','listbookmarks()').
             (&Apache::lc_entity_sessions::asset_entity_domain()?','.&menu_item('setbookmark','Set','setbookmark()'):''))
                     ).',';
   }
# Always second to last item
   $menu.=&menu_item('help','Help','help()').',';
# Always the last item
   if (&Apache::lc_entity_sessions::session_id()) {
      $menu.=&menu_item('logout','Logout','logout()');
   } else {
      $menu.=&menu_item('login','Login','login()');
   }
   $menu.='}';
# Send it out!
   $r->print($menu);
   return OK;
}
1;
__END__
