function ShowMobileLogin() {
    $("#mainCont").animate({ left: '78%' }, 200);
    $('#mobileLoginDD').removeClass('plusSign').addClass('minusSign');
    $('#mobileLoginDD').closest('.mobNavSection').removeClass('col3Bk').addClass('col4Bk');
    $('#mobileLoginDD').parent().children('.dropdownDiv').slideDown();
}

function isNumberKey(evt) {
    var e = evt || window.event; 
    var charCode = e.which || e.keyCode;
    if (charCode > 31 && (charCode < 47 || charCode > 57))
        return false;
    if (e.shiftKey) return false;
    return true;
}

function TimeUtcClick() {    
    
    if ($('#img_TimeButton').attr("src") == "/img/btnUTC.gif") {
        $('#img_TimeButton').attr("src", "/img/btnLocal.gif");
        $('#span_TimeLocal').show();
        $('#span_TimeUtc').hide();
    }
    else {
        $('#img_TimeButton').attr("src", "/img/btnUTC.gif");
        $('#span_TimeLocal').hide();
        $('#span_TimeUtc').show();
    }
}