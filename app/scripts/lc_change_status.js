var entity;
var domain;
var title;

$(document).ready(function() {
     entity=parent.getParameterByName(location.search,'entity');
     domain=parent.getParameterByName(location.search,'domain');
     url=parent.getParameterByName(location.search,'url');
     $('#storebutton').click(function() {
         $.ajax({
             url: '/portfolio',
             type:'POST',
             data: { 'command' : 'changestatus',
                     'entity'  : entity,
                     'domain'  : domain,
                     'url'     : url,
                     'title'   : $('#newtitle').val() },
             success: function(response) {
                if (response=='error') {
                   $('.lcstandard').hide();
                   $('.lcerror').show();
                } else {
                   parent.document.getElementById('contentframe').contentWindow.reload_listing();
                   parent.hide_modal();
                }
             },
             error: function(xhr, ajaxOptions, errorThrown) {
                $('.lcstandard').hide();
                $('.lcerror').show();
             }
         });         
     });
     $('#cancelbutton').click(function() {
        parent.hide_modal();
     });
});