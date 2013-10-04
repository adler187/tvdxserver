$(function () {
  $('[data-toggle-group]').each(function() {
    var element = $(this);
    var group = element.data('toggle-group');
    
    var toggle = function() {
      $('.' + group).each(function() {
        var value = !element.prop('checked');
        $(this).prop('disabled', value);
      });
    };
    
    toggle();
    
    element.click(function() {
      toggle();
    });
  });
});