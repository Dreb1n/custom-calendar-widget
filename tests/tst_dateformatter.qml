import QtQuick 2.15
import QtTest 1.15
import "../contents/ui/DateFormatter.js" as DateFormatter

TestCase {
    name: "DateFormatterTests"

    function test_basic_formatting() {
        // Create an explicit mock date: Friday August 7, 2026 12:30:45 UTC
        const date = new Date(Date.UTC(2026, 7, 7, 12, 30, 45));

        compare(DateFormatter.format(date, "yyyy-MM-dd", "UTC"), "2026-08-07");
        compare(DateFormatter.format(date, "HH:i:ss", "UTC"), "12:30:45");
        compare(DateFormatter.format(date, "do", "UTC"), "7th");
    }

    function test_locale_resolution() {
        const date = new Date(Date.UTC(2026, 7, 7, 12, 0, 0));

        // Test French locale ("fr_FR") -> "août" / "vendredi"
        const frMonth = DateFormatter.format(date, "MMMM", "UTC", "fr_FR");
        verify(frMonth.toLowerCase().indexOf("août") !== -1 || frMonth.toLowerCase().indexOf("aout") !== -1, "French month name should resolve to août");

        // Test German locale ("de_DE") -> "Freitag"
        const deDay = DateFormatter.format(date, "dddd", "UTC", "de_DE");
        verify(deDay.toLowerCase().indexOf("freitag") !== -1, "German day name should resolve to Freitag");

        // Test Spanish locale ("es_ES") -> "viernes"
        const esDay = DateFormatter.format(date, "dddd", "UTC", "es_ES");
        verify(esDay.toLowerCase().indexOf("viernes") !== -1, "Spanish day name should resolve to viernes");

        // Test C / English locale ("C") -> "August" / "Friday"
        compare(DateFormatter.format(date, "MMMM", "UTC", "C").toUpperCase(), "AUGUST");
        compare(DateFormatter.format(date, "dddd", "UTC", "C").toUpperCase(), "FRIDAY");
    }

    function test_external_iana_timezones() {
        const date = new Date(Date.UTC(2026, 7, 7, 12, 0, 0));

        // Verify numeric offset strings
        compare(DateFormatter.format(date, "HH:i", "UTC-5"), "07:00");
        compare(DateFormatter.format(date, "HH:i", "UTC+3"), "15:00");
        compare(DateFormatter.format(date, "HH:i", "GMT+5:30"), "17:30");

        // Verify IANA timezone strings return valid HH:i formatted timestamps
        const nyTime = DateFormatter.format(date, "HH:i", "America/New_York");
        verify(nyTime.length === 5 && nyTime.indexOf(":") === 2, "America/New_York timezone resolution must return valid HH:i timestamp");

        const tokTime = DateFormatter.format(date, "HH:i", "Asia/Tokyo");
        verify(tokTime.length === 5 && tokTime.indexOf(":") === 2, "Asia/Tokyo timezone resolution must return valid HH:i timestamp");
    }

    function test_unclosed_bracket_safety() {
        const date = new Date(Date.UTC(2026, 7, 7, 12, 0, 0));

        // Testing unclosed brackets to make sure parser does not trigger infinite loop
        const res1 = DateFormatter.format(date, "yyyy [escaped text] [uncl", "UTC");
        compare(res1, "2026 escaped text [uncl");
    }

    function test_caching_and_boundaries() {
        const date = new Date(Date.UTC(2026, 7, 7, 12, 0, 0));

        // Repeating calls to verify token compilation cache checks
        for (let i = 0; i < 50; i++) {
            compare(DateFormatter.format(date, "yyyy-MM-dd", "UTC"), "2026-08-07");
        }
    }
}
