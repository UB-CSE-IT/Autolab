var hideStudent;  // This isn't great, but it's required to maintain compatibility with the submission partial popup

$(document).ready(function () {
    let $floater = $("#floater"),
        $backdrop = $("#gradeBackdrop");
    $('.trigger').bind('ajax:success', function showStudent(event, data, status, xhr) {
        $floater.html(data);
        $floater.show();
        $backdrop.show();
        $backdrop.click(function () {
            hideStudent();
        });
    });

    /** override the global **/
    hideStudent = function hideStudent() {
        $floater.hide();
        $backdrop.hide();
    };
});
