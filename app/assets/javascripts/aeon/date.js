/*
* Schedule Date date picker
*/

(function () {
    "use strict";

    var allowWeekends, minDate, maxDate, yearlyHolidays, floatingHolidays,floatingOpendays;

    /* 
    * Defines whether weekends will be enabled by default
    */
    allowWeekends = true;

    /*
    * Defines the minimum date that will be enabled
    * See http://docs.jquery.com/UI/Datepicker#option-minDate for more information on the available values
    */
    minDate = new Date();

    /*
    * Defines the maximum date that will be enabled
    * See http://docs.jquery.com/UI/Datepicker#option-maxDate for more information on the available values
    */
    maxDate = null;

    /*
    * Yearly holidays
    * Format is 2-digit month followed by 2-digit day (i.e. mmdd)
    */
    yearlyHolidays = [];
    //yearlyHolidays.push(['0101', 'New Year\'s Day']);
    //yearlyHolidays.push(['0116', 'Birthday of Martin Luther King, Jr.']);
    //yearlyHolidays.push(['0220', 'Washington\'s Birthday']);
    //yearlyHolidays.push(['0704', 'Independence Day']);
    //yearlyHolidays.push(['1111', 'Veterans Day']);
    //yearlyHolidays.push(['1225', 'Christmas Day']);

    /*
    * Floating holidays or other days that should be disabled
    * 
    * An array of 2 elements where the first is the date of the holiday and the second is the name of the
    * holiday which will be displayed in the tooltip for the date
    *
    * Format of first element is 4-digit year followed by 2-digit month followed by 2-digit day (i.e. yyyymmdd)
    */
    floatingHolidays = [];
    //floatingHolidays.push(['20111124', 'Thanksgiving Day']);
    //floatingHolidays.push(['20111226', 'Christmas Day']);
    //floatingHolidays.push(['20120102', 'New Year\'s Day']);
    //floatingHolidays.push(['20120528', 'Memorial Day']);
    //floatingHolidays.push(['20120903', 'Labor Day']);
    //floatingHolidays.push(['20121008', 'Columbus Day']);
    //floatingHolidays.push(['20121112', 'Veterans Day']);
    //floatingHolidays.push(['20121122', 'Thanksgiving Day']);
    function checkHoliday(array, value) {
        for (var i = 0; i < array.length; i++) {
            if (array[i][0] == value) {
                return array[i][1];
            }
        }

        return null;
    }

    /*
    * Floating open days.
    * An array of 2 elements where the first is the date of the Open day and the second is the 
    * special reason for being open which will be displayed in the tooltip for the date
    * Format of first element is 4-digit year followed by 2-digit month followed by 2-digit day (i.e. yyyymmdd)
    */
    floatingOpendays = [];
    floatingOpendays.push(['20130302', 'Open Saturday']);

    function checkOpenday(array, value) {
        for (var i = 0; i < array.length; i++) {
            if (array[i][0] == value) {
                return array[i][1];
            }
        }
        return null;
    }

    function isHoliday(dateToCheck) {
        var yearlyDate, floatingDate, result;

        yearlyDate = $.datepicker.formatDate('mmdd', dateToCheck);
        floatingDate = $.datepicker.formatDate('yymmdd', dateToCheck);

        result = checkHoliday(floatingHolidays, floatingDate);

        if (!result) {
            result = checkHoliday(yearlyHolidays, yearlyDate);
        }

        return result;
    }

    $(document).ready(function () {
        var scheduledDate = $('#ScheduledDate');
        if (scheduledDate.length > 0) {
        scheduledDate.datepicker({
            minDate: minDate,
            maxDate: maxDate,
            beforeShowDay: function (date) {
                var holiday = isHoliday(date);

                if (holiday) {
                    return [false, null, holiday];
                } else {
                    if (!allowWeekends) {
                        var noWeekendsResult = $.datepicker.noWeekends(date);

                        if (!noWeekendsResult[0]) {
                            return noWeekendsResult;
                        }
                    }

                    return [true, null, null];
                }
            }
        });

        // Disable manual entry for date
        scheduledDate.attr("readonly", true);
        }
    });
} ());
