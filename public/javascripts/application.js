$(function() {
  
  $("form.fadeout").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();
    
    var ok = true //confirm("Are you sure? This cannot be undone ever!");
    
    if (ok) {
      // this.submit();
      
      var form = $(this);
      
      var request = $.ajax({
        url: form.attr("action"),
        method: form.attr("method")
      });
      
      request.done(function(data, textStatus, jqXHR) {
        if (jqXHR.status == 204) {
          form.parent("li").slideUp(500, function() { $(this).remove(); });
        } else if (jqXHR.status == 200) {
          document.location = data;
        }
      });
    }
    
  });
  
});

$(function() {
  
  $("form.confirm").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();
    
    var ok = confirm("Are you sure? This cannot be undone ever!");
    
    if (ok) {
      this.submit();
    }
    
  });
  
});
