
document.observe
(
	"dom:loaded",
	function()
	{
		handleResize();
		
		// get from rails somehow
		var latitude = 44.032686;
		var longitude = -92.648311;
		var zoom = 8;
		
		var centerlatlng = new google.maps.LatLng(latitude, longitude);
		var myOptions =
		{
			zoom: zoom,
			center: centerlatlng,
			disableDefaultUI: true,
			mapTypeId: google.maps.MapTypeId.ROADMAP
		};
		
		map = new google.maps.Map($("map"), myOptions);
		
		google.maps.event.addListener(map, 'click', map.clearActiveMarker.bind(map));
		
		$('options_form').sumit();
	}
);

function handleResize()
{
	var height = self.innerHeight - $('top').offsetHeight - 30;
	$('map').style.height = height + 'px';
	$('logs').style.height = height + 'px';
}

document.observe(window, 'resize', handleResize);
