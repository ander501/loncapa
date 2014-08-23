$(document).ready(function() {

    init_datatable();

    load_path();

    $('#newbutton').click(function() {
        parent.add_to_courselist();
    });

    $('#modifybutton').click(function() {
        modify_selected();
    });
} );

function init_datatable() {
    $('#portfoliolist tr').click( function() {
                if ( $(this).hasClass('row_selected') ) {
                        $(this).removeClass('row_selected');
                } else {
                        $(this).addClass('row_selected');
                }
    } );

   $('#portfoliolist').dataTable( {
      "sAjaxSource" : '/portfolio?command=listdirectory',
      "bStateSave": true,
      "oLanguage" : {
         "sUrl" : "/datatable_i14n"
      },
      "aoColumns" : [
         { "bVisible": false },
         null,
         null,
         null,
         null,
         null,
         {"iDataSort": 7 },
         { "bVisible": false },
         {"iDataSort": 9 },
         { "bVisible": false }
      ]
    } );
}

function reload_listing() {
   $('#portfoliolist').dataTable().fnDestroy();
   init_datatable();
}

function load_path() {
   var noCache = parent.no_cache_value();
   $.getJSON( '/portfolio?command=listpath', { "noCache": noCache }, function( data ) {
       var newpath = "<ul id='pathrow' name='pathrow' class='lcpathrow'>";
       $.each(data,function(index,subdir) {
            newpath+="<li class='lcpathitem'><a href='#' id='dir"+subdir+"'>"+subdir+"</a></li>";
       });
       newpath+="</ul>";
       $("#pathrow").replaceWith(newpath);
   });
}

function fnShowHide( iCol ) {
   var oTable = $('#portfoliolist').dataTable();
   var bVis = oTable.fnSettings().aoColumns[iCol].bVisible;
   oTable.fnSetColumnVis( iCol, bVis ? false : true );
   adjust_framesize();
}

function select_filtered() {
   var oTable = $('#portfoliolist').dataTable();
   var aTrs = oTable.$('tr', {"filter":"applied"});
   for ( var i=0 ; i<aTrs.length ; i++ ) {
      $(aTrs[i]).addClass('row_selected');
   }
}

function select_all() {
   var oTable = $('#portfoliolist').dataTable();
   var aTrs = oTable.fnGetNodes();
   for ( var i=0 ; i<aTrs.length ; i++ ) {
      $(aTrs[i]).addClass('row_selected');
   }
}

function deselect_all() {
   var oTable = $('#portfoliolist').dataTable();
   var aTrs = oTable.fnGetNodes();
   for ( var i=0 ; i<aTrs.length ; i++ ) {
      $(aTrs[i]).removeClass('row_selected');
   }
}

function fnGetSelected() {
   var aReturn = new Array();
   var oTable = $('#portfoliolist').dataTable();
   var aTrs = oTable.fnGetNodes();	
   for ( var i=0 ; i<aTrs.length ; i++ ) {
      if ( $(aTrs[i]).hasClass('row_selected') ) {
	 aReturn.push(oTable.fnGetData(aTrs[i],0));
      }
   }
   if (aReturn.length>0) {
      return '['+aReturn.join(',')+']';
   } else {
      return '';
   }
}

function modify_selected() {
   var selectedUsers=fnGetSelected();
   if (selectedUsers=='') { return; }
   document.courseusers.postdata.value=selectedUsers;
   document.courseusers.method="post";
   document.courseusers.action="/pages/lc_modify_courselist.html";
   parent.setbreadcrumbbar('add','modifycourselist','Modify Selected Entries','');
   parent.breadcrumbbar();
   document.courseusers.submit();
}

function uploadsuccess(name) {
   alert("success "+name);
}

function uploadfailure(name,code) {
   alert("failure "+name+" code "+code);
}

