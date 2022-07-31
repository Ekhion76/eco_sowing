let saveBtn;
let inProgress = false;
const resourceName = GetParentResourceName();

$(document).ready(function () {

    $('.pMinus, .pPlus').click(function () {


            let variable = $(this).parent().data('var');
            let value = $(this).data('value') * 1;

            let pField = $('.' + variable);
            let pValue = pField.html() * 1;

            if (pValue >= 0 && pValue < 360) {

                pValue = (pValue + value).toFixed(1) * 1;

                if (pValue < 0 || pValue > 359) {

                    pValue = 0;
                }

                pField.html(pValue);

                $.post(`https://${resourceName}/paramSet`, JSON.stringify({
                    key: variable,
                    value: pValue
                }));
            }
        }
    );

    saveBtn = $('.saveBtn');
    saveBtn.click(function (e) {

        e.preventDefault();

        if (!inProgress) {

            inProgress = true;
            $.post(`https://${resourceName}/saveCoords`, JSON.stringify({}));
        }
    });


    $('#wrapper').draggable({
        handle: '#header',
        containment: 'parent'
    });

});


// Listen for NUI Events
window.addEventListener('message', function (event) {

    let item = event.data;

    if (item.subject === 'OPEN') {

        $('#wrapper').css("display", "block");

        $.each(item.data, function (index, value) {

            $('.' + index).html(value.toFixed(1));
        });

    } else if (item.subject === 'SAVE_TO_CLIPBOARD') {

        copyToClipboard(item.data);

        let text = saveBtn.text();

        saveBtn.text('SAVED');
        saveBtn.addClass('saving');

        setTimeout(function () {

            saveBtn.text(text);
            saveBtn.removeClass('saving');
            inProgress = false;
        }, 1000);

    } else if (item.subject === 'CLOSE') {

        $('#wrapper').css("display", "none");
    }
});


$(document).keyup(function (key) {

    if (key.which === 27 || key.which === 17) { // LEFT ALT 18, LEFT CTRL 17

        $.post(`https://${resourceName}/exit`, JSON.stringify({}));
    }
});


$('.btnClose').click(function (e) {

    e.preventDefault();

    $('#wrapper').css("display", "none");

    $.post(`https://${resourceName}/exit`, JSON.stringify({
        inWork: 'off'
    }));
});

function copyToClipboard(string) {

    let temp = $("<textarea>");
    $("body").append(temp);
    temp.val(string).select();
    document.execCommand("copy");
    temp.remove();
}

