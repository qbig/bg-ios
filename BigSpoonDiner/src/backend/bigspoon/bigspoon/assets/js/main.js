$(document).ready(function() {

    var host = "http://"+location.host;
    var sound = new Howl({
        urls: [media_url + 'sounds/notification.mp3']
    })
    var reload_sound = new Howl({
        urls: [media_url + 'sounds/notification.mp3'],
        onend: function() {
            location.reload(true);
        }
    })

    function getNotification(number){
        if(!number){
            return "<p class='notification'><span><i class='icon-bell'> New</i></span></p>";
        }
        return "<p class='notification'><span><i class='icon-bell'> " + number + "</i></span></p>";
    }

    function showNotification(number) {
        $("nav ul li:first-child a p").remove();
        $("nav ul li:first-child a").append(getNotification(number));
        sound.play();
        setInterval(function() {
            sound.play();
        }, 60000);
    }

    function showNotificationReload(number) {
        $("nav ul li:first-child a p").remove();
        $("nav ul li:first-child a").append(getNotification(number));
        reload_sound.play();
        setTimeout(function(){
            location.reload(true);
        }, 1500);
    }

    if (location.pathname == "/staff/main/") {
        localStorage.removeItem("notify");
    }

    if (localStorage.getItem("notify") == "true") {
        showNotification();
    }

    // time picker
    $('input.ui-timepicker-input').timepicker({
        'timeFormat': 'H:i:s',
        'step': 30,
        'maxTime': '11:59pm',
    });

    // close all menu
    function closeAllMenu() {
        $('.ui-accordion-header').removeClass('ui-accordion-header-active ui-state-active ui-corner-top').addClass('ui-corner-all').attr({
            'aria-selected': 'false',
            'tabindex': '-1'
        });
        $('.ui-accordion-header').find("i").removeClass('icon-collapse-top').addClass('icon-collapse');
        $('.ui-accordion-content').removeClass('ui-accordion-content-active').attr({
            'aria-expanded': 'false',
            'aria-hidden': 'true'
        }).hide();
    }

    // Menu update page live search/filter
    $('#filter').keyup(function() {
        var f = $(this).val();
        var regex = new RegExp(f, 'gi');

        closeAllMenu();
        $('#accordion h3').hide()
            .each(function() {
                if($(this).text().match(regex)) {
                    $(this).show();
                }
            });
    });

    // filter by dish category
    $('#pick-category').on("change", function() {
        var category = $(this).val();
        var regex = new RegExp(category, 'gi');

        closeAllMenu();
        $('#accordion h3').hide()
            .each(function() {
                if($(this).find("input").val().match(regex)) {
                    $(this).show();
                }
            });
    });

    $('#pick-table select').on("change", function() {
        var table = $(this).val();
        if (table == "All Tables") {
            $('.table').show();
        }
        else {
            $('.table').hide()
            .each(function() {
                if($(this).find('h3').text() == table) {
                    $(this).show();
                }
            });
        }
    });

    // Menu update page collapsibles
    $('#accordion').accordion({
        collapsible:true,
        active:false,

        beforeActivate: function(event, ui) {
             // The accordion believes a panel is being opened
            if (ui.newHeader[0]) {
                var currHeader  = ui.newHeader;
                var currContent = currHeader.next('.ui-accordion-content');
             // The accordion believes a panel is being closed
            } else {
                var currHeader  = ui.oldHeader;
                var currContent = currHeader.next('.ui-accordion-content');
            }
             // Since we've changed the default behavior, this detects the actual status
            var isPanelSelected = currHeader.attr('aria-selected') == 'true';

             // Toggle the panel's header
            currHeader.toggleClass('ui-corner-all',isPanelSelected).toggleClass('accordion-header-active ui-state-active ui-corner-top',!isPanelSelected).attr('aria-selected',((!isPanelSelected).toString()));

            // Toggle the panel's icon
            currHeader.children('.ui-icon').toggleClass('ui-icon-triangle-1-e',isPanelSelected).toggleClass('ui-icon-triangle-1-s',!isPanelSelected);

             // Toggle the panel's content
            currContent.toggleClass('accordion-content-active',!isPanelSelected)
            if (isPanelSelected) { currContent.slideUp(); }  else { currContent.slideDown(); }

            return false; // Cancel the default action
        }
    });

    // Dismiss tutorial messages
    $(".help").click(function(){
        $(this).hide();
    });

    // Toggle accordion icons
    $("#accordion h3").click(function(){
        var icon = $(this).find("i");
        if(icon.hasClass('icon-collapse')){
            icon.removeClass('icon-collapse').addClass('icon-collapse-top');
        } else {
            icon.removeClass('icon-collapse-top').addClass('icon-collapse');
        }
    });

    // for socket io
    var STAFF_MEAL_PAGES = {
        "new": ['/staff/main/'],
        "ack": ['/staff/main/', '/staff/history/', '/staff/tables/'],
        "askbill": ['/staff/main/', '/staff/history/', '/staff/tables/'],
        "closebill": ['/staff/main/', '/staff/report/', '/staff/tables/', '/staff/history/'],
    };
    var STAFF_MENU_PAGES = ['/staff/menu/'];

    if (host.indexOf("8000") !== -1) {
        socket = io.connect();
    }
    else {
        socket = io.connect(host+":8000");
    }

    socket.on("message", function(obj){
        if (obj.message.type == "message") {
            var data = eval(obj.message.data);
            var path = location.pathname;
            if (data[0] == "refresh") {
                if (data[1] == "request" || data[1] == "meal") {
                    if ($.inArray(path, STAFF_MEAL_PAGES[data[2]]) != -1) {
                        if (data[2] == "new" || data[2] == "askbill") {
                            showNotificationReload();
                        }
                        else {
                            location.reload(true);
                        }
                    }
                    if (data[2] == "new" || data[2] == "askbill") {
                        showNotification();
                    }
                }
                else if (data[1] == "menu") {
                    if ($.inArray(path, STAFF_MENU_PAGES) != -1) {
                        location.reload(true);
                    }
                }
                else {
                    // other instructions
                }
            }
        }
    });

    if (outlet_ids != null) {
        for (var i = 0, len = outlet_ids.length; i < len; i++) {
            socket.send("subscribe:" + outlet_ids[i]);
        }
    }

    // for masonry
    $("#main .wrapper").masonry({
        resizeable: true,
        itemSelector: '.item',
        columnWidth: 15,
    });

    // for request and order ack
    var STAFF_API_URLS = {
        "req": host+"/api/v1/ackreq",
        "bill": host+"/api/v1/closebill",
        "order": host+"/api/v1/ackorder",
        "note": host+"/api/v1/note",
        "dish": host+"/api/v1/dish",
        "spending": host+"/api/v1/spending"
    }

    var csrftoken = $.cookie('csrftoken');

    window.saveNote = function(elem){
            var button = $(elem);
            var user = button.attr('user');
            var outlet = button.attr('outlet');
            var content = button.parent().find('.notes').val();

            var req_data = {
                "csrfmiddlewaretoken":csrftoken,
                "outlet": outlet,
                "user": user,
                "content":content,
            }


            $.post(
                STAFF_API_URLS["note"],
                req_data
            ).done(function(data) {
                console.log("POST success!");
                button.parent().append("<p class='success'><i class='icon-ok-sign'></i> Note saved!</p>")


            }).fail(function(data) {
                console.log("POST failed");
                console.log(data);
            });
    }

    window.successMessage = function(name){
        var successMessage = "<p class='success'><i class='icon-ok-sign'></i> Dish details updated! </p>"
        return successMessage;
    }

    function errorMessage(name){
        var errorMessage = "<p class='error'><i class='icon-frown'></i> Form error. Changes are not saved. </p>"
        return errorMessage;
    }

    // Makes AJAX call to update dish API endpoint
    window.updateDish = function(elem){
        var button = $(elem);
        var form = button.parent();

        var id = button.attr('dish-id');
        var name = form.find('.name input').val();
        var price = form.find('.price input').val();
        var pos = form.find('.pos input').val();
        var desc = form.find('.description textarea').val();
        var quantity = form.find('.quantity select option:selected').val();
        var start_time = form.find('.start_time input').val();
        var end_time = form.find('.end_time input').val();

        console.log("Update dish " + id);

        var req_data = {
            "csrfmiddlewaretoken":csrftoken,
            "name":name,
            "price":price,
            "pos":pos,
            "desc":desc,
            "quantity":quantity,
            "desc":desc,
            "start_time":start_time,
            "end_time":end_time,
            // "categories":categories
        }

        $.post(
            STAFF_API_URLS["dish"] + "/" + id,
            req_data
        ).done(function(data) {
            var notice_id = '#notice-' + id;
            $(notice_id).empty();
            $(notice_id).append(successMessage(name)).effect("highlight", {}, 3000);;
            console.log("POST success!");
        }).fail(function(data) {
            var notice_id = '#notice-' + id;
            $(notice_id).empty();
            $(notice_id).append(errorMessage(name)).effect("highlight", {}, 3000);;
            console.log("POST failed");
            console.log(data);
        });

    }

    // for User profile pop up
    $(".user-profile-link").magnificPopup({
        type: 'ajax',
        alignTop: true,
        closeBtnInside: true,
        overflowY: 'scroll',
    });

    $(".view-profile").magnificPopup({
        type: 'ajax',
        alignTop: true,
        closeBtnInside: true,
        overflowY: 'scroll',
    });

    $('.ack-button').each(function() {
        var button = $(this);
        var type = button.attr('rel');
        var item = button.parent();
        var req_data = {
            "csrfmiddlewaretoken":csrftoken
        }
        req_data[button.attr("model")] = button.attr("id");
        button.click(function() {
            $.post(
                STAFF_API_URLS[type],
                req_data
            ).done(function(data) {
                location.reload(true);
            }).fail(function(data) {
                console.log("POST failed");
                console.log(data);
            });
        });
    });


    // for countdown
    $('.countdown').each(function() {
        var card = $(this);
        var start_time = card.attr("start");
        setInterval(function () {

            var seconds_left = (new Date() - new Date(Number(start_time))) / 1000;

            // console.log(seconds_left);
            minutes = parseInt(seconds_left / 60);
            seconds = parseInt(seconds_left % 60);

            // format countdown string + set tag value
            card.html('<i class="icon-time"></i> waited ' + minutes + " m, " + seconds + " s");

        }, 1000);
    });
});
