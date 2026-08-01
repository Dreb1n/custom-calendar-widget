.pragma library

// Top-level static constants (Allocated ONCE at load time for maximum performance)
const MONTH_NAMES_FULL = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

const MONTH_NAMES_SHORT = [
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
];

const DAY_NAMES_FULL = [
  "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
];

const DAY_NAMES_SHORT = [
  "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
];

const ORDINAL_SUFFIXES = ["th", "st", "nd", "rd"];

// Pre-compiled Token Regex matching format specifiers
const TOKEN_REGEX = /dddd|EEEE|ddd|EEE|mmmm|MMMM|mmm|MMM|mm|MM|yyyy|YYYY|yyy|YYY|yy|YY|do|dd|d|HH|H|hh|h|i|MN|ss|s|A|a|TZ|WW|W|X/g;

// Formatter Cache for Intl.DateTimeFormat (prevents parsing ICU locale data on every tick)
const FORMATTER_CACHE = {};

const WEEKDAY_MAP = {
  "Sun": 0, "Mon": 1, "Tue": 2, "Wed": 3, "Thu": 4, "Fri": 5, "Sat": 6
};

function padZero(num, length = 2) {
  return String(num).padStart(length, '0');
}

function getOrdinal(n) {
  const v = n % 100;
  return n + (ORDINAL_SUFFIXES[(v - 20) % 10] || ORDINAL_SUFFIXES[v] || ORDINAL_SUFFIXES[0]);
}

function getWeekNumber(year, month, day) {
  const target = new Date(Date.UTC(year, month, day));
  target.setUTCDate(target.getUTCDate() + 4 - (target.getUTCDay() || 7));
  const yearStart = new Date(Date.UTC(target.getUTCFullYear(), 0, 1));
  return Math.ceil((((target - yearStart) / 86400000) + 1) / 7);
}

function getLocalizedNames(localeStr) {
  if (!localeStr || typeof localeStr !== "string" || localeStr.trim() === "" || localeStr === "default") {
    return {
      monthsFull: MONTH_NAMES_FULL,
      monthsShort: MONTH_NAMES_SHORT,
      daysFull: DAY_NAMES_FULL,
      daysShort: DAY_NAMES_SHORT
    };
  }
  const key = localeStr.trim();
  if (FORMATTER_CACHE["loc_" + key]) {
    return FORMATTER_CACHE["loc_" + key];
  }
  try {
    var loc = Qt.locale(key);
    var monthsFull = [];
    var monthsShort = [];
    var daysFull = [];
    var daysShort = [];

    for (var m = 0; m < 12; m++) {
      var dM = new Date(2026, m, 15);
      monthsFull.push(dM.toLocaleDateString(loc, "MMMM"));
      monthsShort.push(dM.toLocaleDateString(loc, "MMM"));
    }
    for (var d = 0; d < 7; d++) {
      var dD = new Date(2026, 0, 4 + d); // 2026-01-04 is Sunday
      daysFull.push(dD.toLocaleDateString(loc, "dddd"));
      daysShort.push(dD.toLocaleDateString(loc, "ddd"));
    }
    var res = {
      monthsFull: monthsFull,
      monthsShort: monthsShort,
      daysFull: daysFull,
      daysShort: daysShort
    };
    FORMATTER_CACHE["loc_" + key] = res;
    return res;
  } catch (e) {
    return {
      monthsFull: MONTH_NAMES_FULL,
      monthsShort: MONTH_NAMES_SHORT,
      daysFull: DAY_NAMES_FULL,
      daysShort: DAY_NAMES_SHORT
    };
  }
}

function format(date, formatStr, timeZone, localeStr) {
  if (!date || isNaN(date.getTime())) {
    date = new Date();
  }
  if (!formatStr || typeof formatStr !== "string") {
    return "";
  }

  var year, month, dayOfMonth, dayOfWeek, hours24, minutes, seconds;

  if (timeZone && timeZone !== "local" && timeZone.trim() !== "") {
    const tzKey = timeZone.trim();
    const locKey = (localeStr && localeStr.trim().length > 0) ? localeStr.trim() : 'en-US';
    const cacheKey = tzKey + "_" + locKey;
    try {
      if (!FORMATTER_CACHE[cacheKey]) {
        FORMATTER_CACHE[cacheKey] = new Intl.DateTimeFormat(locKey, {
          timeZone: tzKey,
          weekday: 'short',
          year: 'numeric', month: 'numeric', day: 'numeric',
          hour: 'numeric', minute: 'numeric', second: 'numeric',
          hour12: false
        });
      }
      const parts = FORMATTER_CACHE[cacheKey].formatToParts(date);
      var p = {};
      for (var i = 0; i < parts.length; i++) {
        p[parts[i].type] = parts[i].value;
      }
      year = parseInt(p.year, 10);
      month = parseInt(p.month, 10) - 1;
      dayOfMonth = parseInt(p.day, 10);
      hours24 = parseInt(p.hour, 10) % 24;
      minutes = parseInt(p.minute, 10);
      seconds = parseInt(p.second, 10) || 0;
      dayOfWeek = WEEKDAY_MAP[p.weekday] !== undefined ? WEEKDAY_MAP[p.weekday] : date.getDay();
    } catch (e) {
      year = date.getFullYear();
      month = date.getMonth();
      dayOfMonth = date.getDate();
      dayOfWeek = date.getDay();
      hours24 = date.getHours();
      minutes = date.getMinutes();
      seconds = date.getSeconds();
    }
  } else {
    year = date.getFullYear();
    month = date.getMonth();
    dayOfMonth = date.getDate();
    dayOfWeek = date.getDay();
    hours24 = date.getHours();
    minutes = date.getMinutes();
    seconds = date.getSeconds();
  }

  const hours12 = hours24 % 12 || 12;
  const ampmUpper = hours24 >= 12 ? "PM" : "AM";
  const ampmLower = hours24 >= 12 ? "pm" : "am";
  const tzLabel = timeZone && timeZone !== "local" ? timeZone : "";
  const names = getLocalizedNames(localeStr);

  var placeholders = [];
  var tempStr = formatStr.replace(/\[([^\]]+)\]/g, function(match, p1) {
    placeholders.push(p1);
    return "__PH_" + (placeholders.length - 1) + "__";
  });

  const getValue = function(token) {
    switch (token) {
      case "dddd": case "EEEE": return names.daysFull[dayOfWeek];
      case "ddd": case "EEE": return names.daysShort[dayOfWeek];
      case "mmmm": case "MMMM": return names.monthsFull[month];
      case "mmm": case "MMM": return names.monthsShort[month];
      case "mm": case "MM": return padZero(month + 1, 2);
      case "yyyy": case "YYYY": case "yyy": case "YYY": return String(year);
      case "yy": case "YY": return String(year).slice(-2);
      case "do": return getOrdinal(dayOfMonth);
      case "dd": return padZero(dayOfMonth, 2);
      case "d": return String(dayOfMonth);
      case "HH": return padZero(hours24, 2);
      case "H": return String(hours24);
      case "hh": return padZero(hours12, 2);
      case "h": return String(hours12);
      case "i": case "MN": return padZero(minutes, 2);
      case "ss": return padZero(seconds, 2);
      case "s": return String(seconds);
      case "A": return ampmUpper;
      case "a": return ampmLower;
      case "TZ": return tzLabel;
      case "WW": return padZero(getWeekNumber(year, month, dayOfMonth), 2);
      case "W": return String(getWeekNumber(year, month, dayOfMonth));
      case "X": return String(Math.floor(date.getTime() / 1000));
      default: return token;
    }
  };

  var result = tempStr.replace(TOKEN_REGEX, function(match) {
    return getValue(match);
  });

  for (var i = 0; i < placeholders.length; i++) {
    result = result.replace("__PH_" + i + "__", placeholders[i]);
  }

  return result;
}

