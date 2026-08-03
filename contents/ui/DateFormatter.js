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

// Compiled tokenized format cache
const FORMAT_TOKEN_CACHE = {};

const WEEKDAY_MAP = {
  "Sun": 0, "Mon": 1, "Tue": 2, "Wed": 3, "Thu": 4, "Fri": 5, "Sat": 6
};

function padZero(num, length = 2) {
  if (length === 2) {
    return (num >= 0 && num < 10) ? '0' + num : String(num);
  }
  return String(num).padStart(length, '0');
}

function getOrdinal(n) {
  const v = n % 100;
  return n + (ORDINAL_SUFFIXES[(v - 20) % 10] || ORDINAL_SUFFIXES[v] || ORDINAL_SUFFIXES[0]);
}

function getWeekNumber(year, month, day) {
  var target = new Date(Date.UTC(year, month, day));
  var dayNr = (target.getUTCDay() + 6) % 7;
  target.setUTCDate(target.getUTCDate() - dayNr + 3);
  var firstThursday = target.getTime();
  target.setUTCMonth(0, 1);
  if (target.getUTCDay() !== 4) {
    target.setUTCMonth(0, 1 + ((4 - target.getUTCDay() + 7) % 7));
  }
  return 1 + Math.ceil((firstThursday - target.getTime()) / 604800000);
}

const DEFAULT_NAMES = {
  monthsFull: MONTH_NAMES_FULL,
  monthsShort: MONTH_NAMES_SHORT,
  daysFull: DAY_NAMES_FULL,
  daysShort: DAY_NAMES_SHORT
};

function getLocalizedNames(localeStr) {
  if (!localeStr || typeof localeStr !== "string" || localeStr.trim() === "" || localeStr === "default") {
    return DEFAULT_NAMES;
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

function compileFormat(formatStr) {
  if (FORMAT_TOKEN_CACHE[formatStr]) {
    return FORMAT_TOKEN_CACHE[formatStr];
  }

  var placeholders = [];
  var tempStr = formatStr.replace(/\[([^\]]+)\]/g, function(match, p1) {
    placeholders.push(p1);
    return "__PH_" + (placeholders.length - 1) + "__";
  });

  var tokens = [];
  var lastIndex = 0;
  TOKEN_REGEX.lastIndex = 0;
  var match;

  while ((match = TOKEN_REGEX.exec(tempStr)) !== null) {
    if (match.index > lastIndex) {
      tokens.push({ isToken: false, value: tempStr.substring(lastIndex, match.index) });
    }
    tokens.push({ isToken: true, value: match[0] });
    lastIndex = TOKEN_REGEX.lastIndex;
  }
  if (lastIndex < tempStr.length) {
    tokens.push({ isToken: false, value: tempStr.substring(lastIndex) });
  }

  var compiled = {
    tokens: tokens,
    placeholders: placeholders
  };

  FORMAT_TOKEN_CACHE[formatStr] = compiled;
  return compiled;
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
      for (var i = 0; i < parts.length; i++) {
        var part = parts[i];
        switch (part.type) {
          case 'year': year = parseInt(part.value, 10); break;
          case 'month': month = parseInt(part.value, 10) - 1; break;
          case 'day': dayOfMonth = parseInt(part.value, 10); break;
          case 'hour': hours24 = parseInt(part.value, 10) % 24; break;
          case 'minute': minutes = parseInt(part.value, 10); break;
          case 'second': seconds = parseInt(part.value, 10) || 0; break;
          case 'weekday': dayOfWeek = WEEKDAY_MAP[part.value] !== undefined ? WEEKDAY_MAP[part.value] : date.getDay(); break;
        }
      }
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

  const compiled = compileFormat(formatStr);

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

  var result = "";
  for (var k = 0; k < compiled.tokens.length; k++) {
    var tok = compiled.tokens[k];
    if (tok.isToken) {
      result += getValue(tok.value);
    } else {
      result += tok.value;
    }
  }

  for (var p = 0; p < compiled.placeholders.length; p++) {
    (function(val) {
      result = result.replace("__PH_" + p + "__", function() { return val; });
    })(compiled.placeholders[p]);
  }

  return result;
}
