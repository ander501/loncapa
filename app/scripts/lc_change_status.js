var entity;
var domain;
var url;
var savechanges;

function init_datatable(destroy,newrule) {

   var noCache = parent.no_cache_value();
   $('#rightslist').dataTable( {
      "sAjaxSource" : '/change_status?command=listrights&entity='+entity+'&domain='+domain+'&newrule='+newrule+'&noCache='+noCache,
      "bAutoWidth": false,
      "bDestroy"  : destroy,
      "bStateSave": true,
      "oLanguage" : {
         "sUrl" : "/datatable_i14n"
      },
      "fnInitComplete": function(oSettings, json) {
          if (newrule==1) { type_update(); }
      },
      "aoColumns" : [
         { "bVisible": false },
         { "bSortable": false },
         null,
         null,
         null,
         null
      ]
    } );
}

function reload_listing(newrule) {
   clearTimeout(searchrepeat);
   init_datatable(true,newrule);
}

function list_title() {
   $.ajax({
        url : '/change_status',
        type: "POST",
        data: 'command=listtitle&entity='+entity+'&domain='+domain+'&url='+url,
        success: function(data){
            $('#fileinfo').html(data);
        },
      }); 
}

function deleterule(entity,domain,rule) {
         $.ajax({
             url: '/change_status',
             type:'POST',
             data: { 'command' : 'delete',
                     'entity'  : entity,
                     'domain'  : domain,
                     'url'     : url,
                     'rule'    : unescape(rule) },
             success: function(response) {
                if (response=='error') {
                   $('.lcstandard').hide();
                   $('.lcerror').show();
                } else {
                   reload_listing(0);
                }
             },
             error: function(xhr, ajaxOptions, errorThrown) {
                $('.lcstandard').hide();
                $('.lcerror').show();
             }
         });
}

function discardrule() {
   savechanges=false;
   reload_listing(0);
}

function saverules() {
   savechanges=false;
   $.ajax({
             url: '/change_status',
             type:'POST',
             async: false,
             data: $('#rulelistform').serialize()+"&command=save&entity="+entity+"&domain="+domain+"&url="+escape(url),
             success: function(response) {
                if (response=='error') {
                   $('.lcstandard').hide();
                   $('.lcerror').show();
                } else {
                   reload_listing(0);
                }
             },
             error: function(xhr, ajaxOptions, errorThrown) {
                $('.lcstandard').hide();
                $('.lcerror').show();
             }
   });
}

function entitysearch() {
   if ($('#new_entitytype').val()=='user') {
      usersearch('new');
   } else {
      coursesearch('new');
   }
   section_update();
}

function addrule() {
   saverules();
   reload_listing(0);
}

function type_update() {
   savechanges=true;
   clearTimeout(searchrepeat);
   $('#new_type_edit').attr('disabled','disabled');
}

function section_update() {
   if (($('#new_entitytype').val()=='course') &&
       ($('#new_username').val()) &&
       ($('#new_domain'))) {
     $.getJSON( '/change_status', "command=listsections&courseid="+
                                escape($('#new_username').val())+"&coursedomain="+
                                escape($('#new_domain').val()), function( data ) {
       var newselect = "<select id='new_section' name='new_section'><option value=''></option>";
       $.each(data,function(index,value) {
           newselect+="<option value='"+escape(value)+"'>"+value+"</option>";
       });
       newselect+="</select>";
       $("#newsectionspan").html(newselect);
     });
   } else {
       $("#newsectionspan").html('');
   }
}

$(document).ready(function() {
     savechanges=false;
     entity=parent.getParameterByName(location.search,'entity');
     domain=parent.getParameterByName(location.search,'domain');
     url=parent.getParameterByName(location.search,'url');
     list_title();
     init_datatable(false,0); 
     $('#donebutton').click(function() {
        if (savechanges) { saverules(); }
        parent.document.getElementById('contentframe').contentWindow.reload_listing();
        parent.hide_modal();
     });
     $('#addbutton').click(function() {
        if (savechanges) { saverules(); }
        reload_listing(1);
     });
});
