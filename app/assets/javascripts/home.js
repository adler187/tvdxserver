// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
//= require jquery
//= require jquery_ujs
//= require maps
//= require_self

(function(){
  function handleResize()
  {
    var height = self.innerHeight - $('#top').offset().top - $('#content').offset().top;
    $('#map').height(height + 'px');
    $('#logs').height(height + 'px');
  }

  $(document).ready(function() {
    handleResize();
    
    var myOptions =
    {
      zoom: 8,
      center: new google.maps.LatLng($('#latitude').attr('content'), $('#longitude').attr('content')),
      disableDefaultUI: true,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    
    map = new google.maps.Map($('#map')[0], myOptions);
    
    google.maps.event.addListener(map, 'click', map.clearActiveMarker.bind(map));
    
    $('#options_form').submit(function(event) {
      form = this;
      
      // serialize the data before we disable the form elements,
      // otherwise nothing will get serialized
      var data = $(form).serialize();
      
      var throbber = $('#throbber');
      throbber.removeClass('hidden');
      
      $(form).find(':input:not(:disabled)').prop('disabled', true)
                    
      $.ajax({
        dataType: 'script',
        type: 'POST',
        url: form.action,
        data: data,
        complete: function() {
          throbber.addClass('hidden');
          $(form).find(':input:disabled').prop('disabled', false)
        }
      });
      
      return false;
    });
    
    $('#options_form').children().each(function(){
      if(this.tagName == 'SELECT')
      {
        $(this).change(function() { $('#submit').click(); });
      }
    });
    
    $('#submit').click();
  });

  $(window).bind('resize', handleResize);
  
})();

