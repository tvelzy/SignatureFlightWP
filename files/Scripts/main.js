
$(document).ready(function () {
	
	// Image Rotation	
	function photoCycle () {
		$('.aphoto3').delay(3500).fadeOut(1000, function() {
			$('.aphoto2').delay(3500).fadeOut(1000, function() {
				$('.aphoto3').delay(3500).fadeIn(1000);
				$('.aphoto2').delay(4501).fadeIn(1, photoCycle());
			});
		});
	}
	$('.aphoto3').fadeIn(1);
	$('.aphoto').delay(2000).fadeIn(1000);
	photoCycle();
	
	// Mobile Nav Animation
	$('.hamburger').click(function() {
		var newPos = ($("#mainCont").position().left == 0 ? '78%' : 0);
		$("#mainCont").animate({ left: newPos },200);
	});

	// Login Box Logic
	$('.loginButton').click(function() {
		$('.loginPopup').toggle();
	});

    // Locations page - clickable table rows
    $('.locTableRow').click(function() {
        var page = $(this).attr('rel');
        $(location).attr('href',page);
    });

	// Do Mobile Things
	var tailwinsHeadHeight = $('.tailwinsText h2').height();
	var tailwinsTextHeight = $('.tailwinsText p').height();
	var tailwinsTotalHeight = 30 + tailwinsHeadHeight + tailwinsTextHeight + "px";
	var windowWidth = $(window).width();
	if (windowWidth < 481) {
		$('.tailwinsDiv').css({ "margin-top": tailwinsTotalHeight });
	}
	
	// Dropdown and static sidebar sections
	$('.dropButn').click(function() {
		if ($(this).hasClass('plusSign')) {
			$(this).removeClass('plusSign').addClass('minusSign');
			$(this).closest('.mobNavSection').removeClass('col3Bk').addClass('col4Bk');
			$(this).parent().children('.dropdownDiv').slideDown();
		} else if ($(this).hasClass('minusSign')) {
			$(this).removeClass('minusSign').addClass('plusSign');
			$(this).closest('.mobNavSection').removeClass('col4Bk').addClass('col3Bk');
			$(this).parent().children('.dropdownDiv').slideUp();
		} else {
			window.location=$(this).find("a").attr("href"); 
			return false;
		}
	});

	$('.mobSubnavLink').click(function(){
		$(this).parent().children('.dropButn').trigger('click');
	});
	
	$('.mobNavSection a').click(function(){
		$(this).parent().children('.dropButn').trigger('click');
	});

	$('#mobileLoginButton').click(ShowMobileLogin);
	
	// Signature Select Chart Code
	$('.FBO').click(function() {
		$('.widgetSelector').removeClass('widgetSelected');
		$('.FBO').addClass('widgetSelected');
		$('.fbowidget').fadeIn(300); 
		$('.enginewidget').fadeOut(100);
		$('.mrowidget').fadeOut(100);
	});
	
	$('.ES').click(function() {
		$('.widgetSelector').removeClass('widgetSelected');
		$('.ES').addClass('widgetSelected');
		$('.enginewidget').fadeIn(300); 
		$('.fbowidget').fadeOut(100);
		$('.mrowidget').fadeOut(100);
	});
	
	$('.MRO').click(function() {
		$('.widgetSelector').removeClass('widgetSelected');
		$('.MRO').addClass('widgetSelected');
		$('.mrowidget').fadeIn(300); 
		$('.enginewidget').fadeOut(100);
		$('.fbowidget').fadeOut(100);
	});

	// Reservation page toggle
	$('.newResBut').click(function() {
		$('.editResPosition').removeClass('resSpriteTop');
		$('.editResPosition').addClass('resSpriteBot');
		$(this).removeClass('resSpriteBot');
		$(this).addClass('resSpriteTop');
		$('#resFormDiv').fadeIn(100);
		$('#editFormDiv').fadeOut(100);
		$('.resMobNavNew').removeClass('white');
		$('.resMobNavNew').addClass('col2');
		$('.resMobNavEdit').removeClass('col2');
		$('.resMobNavEdit').addClass('white');
	});
	
	$('.editResBut').click(function() {
		$('.newResPosition').removeClass('resSpriteTop');
		$('.newResPosition').addClass('resSpriteBot');
		$(this).removeClass('resSpriteBot');
		$(this).addClass('resSpriteTop');
		$('#editFormDiv').fadeIn(100);
		$('#resFormDiv').fadeOut(100);
		$('.resMobNavEdit').removeClass('white');
		$('.resMobNavEdit').addClass('col2');
		$('.resMobNavNew').removeClass('col2');
		$('.resMobNavNew').addClass('white');
	});

	// Form drop down styling setup
	if ($(".selectBox").length) {
	    $(".selectBox").selectbox();
	}

	var table = $('.locTable');

    $('#city_header, #state_header, #iata_header, #country_header')
        .wrapInner('<a href="#" />')
        .each(function () {

            var th = $(this),
                thIndex = th.index(),
                inverse = false;

            th.click(function () {

                table.find('td').filter(function () {

                    return $(this).index() === thIndex;

                }).sortElements(function (a, b) {

                    return $.text([a]) > $.text([b]) ?
                        inverse ? -1 : 1
                        : inverse ? 1 : -1;

                }, function () {

                    // parentNode is the element we want to move
                    return this.parentNode;

                });

                inverse = !inverse;

            });

        });
    
});