CKEDITOR.on('instanceReady', function(){
   if (window.parent.document) {
      var frameheight=document.body.offsetHeight + 50;
      $("#contentframe",window.parent.document).css({ height : frameheight + 'px' });
   }
})