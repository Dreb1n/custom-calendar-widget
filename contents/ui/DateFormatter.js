.pragma library

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
const TOKEN_REGEX = /DDDD|EEEE|eeee|DDD|EEE|eee|dddd|ddd|MMMM|MMM|mmmm|mmm|mm|MM|yyyy|YYYY|yyy|YYY|yy|YY|DO|do|dd|d|HH|H|hh|h|i|MN|ss|s|A|a|TZ_OFFSET|TZ_OFF|TZ_UPPER|TZ_UC|TZ_REL|TZ_DIFF|TZ|WW|W|X/g;

// Cache for Intl.DateTimeFormat timezone formatters
const TZ_FORMATTER_CACHE = {};
// Cache for standalone localized month/day names
const LOC_NAMES_CACHE = {};
const FORMAT_TOKEN_CACHE = {};
const MAX_CACHE_ENTRIES = 32;

function setBoundedCache(cacheObj, key, value) {
  var keys = Object.keys(cacheObj);
  if (keys.length >= MAX_CACHE_ENTRIES) {
    delete cacheObj[keys[0]];
  }
  cacheObj[key] = value;
}


function padZero(num, length) {
  if (length === undefined) length = 2;
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
  var key = (localeStr && typeof localeStr === "string") ? localeStr.trim() : "";
  if (key.toLowerCase() === "default" || key.toLowerCase() === "local" || key.toLowerCase() === "system default") {
    key = "";
  }
  var cacheKey = "loc_" + (key || "sys");
  if (LOC_NAMES_CACHE[cacheKey]) {
    return LOC_NAMES_CACHE[cacheKey];
  }
  try {
    var loc = key !== "" ? Qt.locale(key) : Qt.locale();
    var monthsFull = [];
    var monthsShort = [];
    var daysFull = [];
    var daysShort = [];

    var fmtLong = (typeof Locale !== "undefined" && Locale.LongFormat !== undefined) ? Locale.LongFormat : 0;
    var fmtShort = (typeof Locale !== "undefined" && Locale.ShortFormat !== undefined) ? Locale.ShortFormat : 1;

    for (var m = 0; m < 12; m++) {
      monthsFull.push(loc.standaloneMonthName(m, fmtLong));
      monthsShort.push(loc.standaloneMonthName(m, fmtShort));
    }
    for (var d = 0; d < 7; d++) {
      daysFull.push(loc.dayName(d, fmtLong));
      daysShort.push(loc.dayName(d, fmtShort));
    }
    var res = { monthsFull: monthsFull, monthsShort: monthsShort, daysFull: daysFull, daysShort: daysShort };
    setBoundedCache(LOC_NAMES_CACHE, cacheKey, res);
    return res;
  } catch (e) {
    return DEFAULT_NAMES;
  }
}

function compileFormat(formatStr) {
  if (FORMAT_TOKEN_CACHE[formatStr]) {
    return FORMAT_TOKEN_CACHE[formatStr];
  }

  var tokens = [];
  var pos = 0;
  var len = formatStr.length;

  while (pos < len) {
    if (formatStr[pos] === "[") {
      var endBracket = formatStr.indexOf("]", pos + 1);
      if (endBracket !== -1) {
        var literalText = formatStr.substring(pos + 1, endBracket);
        tokens.push({ isToken: false, value: literalText });
        pos = endBracket + 1;
        continue;
      } else {
        tokens.push({ isToken: false, value: "[" });
        pos = pos + 1;
        continue;
      }
    }

    var nextBracket = formatStr.indexOf("[", pos);
    var segmentEnd = (nextBracket !== -1) ? nextBracket : len;
    var segment = formatStr.substring(pos, segmentEnd);
    pos = segmentEnd;

    var tokenRegex = new RegExp(TOKEN_REGEX.source, "g");
    var lastIndex = 0;
    var match;
    while ((match = tokenRegex.exec(segment)) !== null) {
      if (match.index > lastIndex) {
        tokens.push({ isToken: false, value: segment.substring(lastIndex, match.index) });
      }
      tokens.push({ isToken: true, value: match[0] });
      lastIndex = tokenRegex.lastIndex;
    }
    if (lastIndex < segment.length) {
      tokens.push({ isToken: false, value: segment.substring(lastIndex) });
    }
  }

  setBoundedCache(FORMAT_TOKEN_CACHE, formatStr, tokens);
  return tokens;
}

// Module-scoped Static Helper Functions (Zero Heap Allocation Per Tick)
function formatTzOffset(off) {
  var absOff = Math.abs(off);
  var h = Math.floor(absOff);
  var m = Math.round((absOff - h) * 60);
  var sign = off >= 0 ? "+" : "-";
  return sign + padZero(h, 2) + ":" + padZero(m, 2);
}

function formatTzRelative(off, locOff) {
  var diff = off - locOff;
  if (Math.abs(diff) < 0.01) return "same time";
  var sign = diff > 0 ? "+" : "";
  var rounded = Math.round(diff * 100) / 100;
  return sign + rounded + "h";
}

function getTokenValue(token, year, month, dayOfMonth, dayOfWeek, hours24, hours12, minutes, seconds, ampmUpper, ampmLower, tzLabel, names, tzOffsetStr, tzRelStr, date) {
  switch (token) {
    case "DDDD": case "EEEE": return names.daysFull[dayOfWeek].toUpperCase();
    case "DDD": case "EEE": return names.daysShort[dayOfWeek].toUpperCase();
    case "dddd": return names.daysFull[dayOfWeek];
    case "ddd": return names.daysShort[dayOfWeek];
    case "eeee": return names.daysFull[dayOfWeek].toLowerCase();
    case "eee": return names.daysShort[dayOfWeek].toLowerCase();
    case "MMMM": return names.monthsFull[month].toUpperCase();
    case "MMM": return names.monthsShort[month].toUpperCase();
    case "mmmm": return names.monthsFull[month];
    case "mmm": return names.monthsShort[month];
    case "mm": case "MM": return padZero(month + 1, 2);
    case "yyyy": case "YYYY": case "yyy": case "YYY": return String(year);
    case "yy": case "YY": return String(year).slice(-2);
    case "DO": return getOrdinal(dayOfMonth).toUpperCase();
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
    case "TZ_OFFSET": case "TZ_OFF": return tzOffsetStr;
    case "TZ_REL": case "TZ_DIFF": return tzRelStr;
    case "TZ_UPPER": case "TZ_UC": return tzLabel.toUpperCase();
    case "TZ": return tzLabel;
    case "WW": return padZero(getWeekNumber(year, month, dayOfMonth), 2);
    case "W": return String(getWeekNumber(year, month, dayOfMonth));
    case "X": return String(Math.floor(date.getTime() / 1000));
    default: return token;
  }
}

function format(date, formatStr, timeZone, localeStr) {
  if (!date) date = new Date();
  if (!formatStr || typeof formatStr !== "string") return "";

  var year, month, dayOfMonth, dayOfWeek, hours24, minutes, seconds;
  var tzClean = (timeZone || "").trim();
  var tzUpper = tzClean.toUpperCase();
  var offsetHours = null;

  if (tzClean !== "" && tzClean !== "local") {
    if (tzUpper === "UTC" || tzUpper === "GMT" || tzUpper === "Z" || tzUpper === "ETC/UTC" || tzUpper === "ETC/GMT" || tzUpper === "UTC+0" || tzUpper === "UTC-0" || tzUpper === "GMT+0" || tzUpper === "GMT-0") {
      offsetHours = 0;
      year = date.getUTCFullYear();
      month = date.getUTCMonth();
      dayOfMonth = date.getUTCDate();
      dayOfWeek = date.getUTCDay();
      hours24 = date.getUTCHours();
      minutes = date.getUTCMinutes();
      seconds = date.getUTCSeconds();
    } else {
      var resolved = false;
      if (typeof Intl !== "undefined" && Intl.DateTimeFormat) {
        try {
          if (!TZ_FORMATTER_CACHE[tzClean]) {
            setBoundedCache(TZ_FORMATTER_CACHE, tzClean, new Intl.DateTimeFormat('en-US', {
              timeZone: tzClean,
              year: 'numeric', month: 'numeric', day: 'numeric',
              hour: 'numeric', minute: 'numeric', second: 'numeric',
              hour12: false
            }));
          }
          const parts = TZ_FORMATTER_CACHE[tzClean].formatToParts(date);
          for (var i = 0; i < parts.length; i++) {
            var part = parts[i];
            switch (part.type) {
              case 'year': year = parseInt(part.value, 10); break;
              case 'month': month = parseInt(part.value, 10) - 1; break;
              case 'day': dayOfMonth = parseInt(part.value, 10); break;
              case 'hour': hours24 = parseInt(part.value, 10) % 24; break;
              case 'minute': minutes = parseInt(part.value, 10); break;
              case 'second': seconds = parseInt(part.value, 10) || 0; break;
            }
          }
          dayOfWeek = new Date(Date.UTC(year, month, dayOfMonth)).getUTCDay();
          var targetUtc = Date.UTC(year, month, dayOfMonth, hours24, minutes, seconds);
          var baseUtc = Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds());
          offsetHours = (targetUtc - baseUtc) / 3600000;
          resolved = true;
        } catch (e) {}
      }

      if (!resolved) {
        var match = tzClean.match(/^(?:UTC|GMT)?\s*([+-])\s*(\d{1,2})(?::(\d{2}))?$/i);
        if (match) {
          var sign = match[1] === '-' ? -1 : 1;
          var hOff = parseInt(match[2], 10);
          var mOff = match[3] ? parseInt(match[3], 10) : 0;
          offsetHours = sign * (hOff + mOff / 60);
        }

        if (offsetHours !== null) {
          var offsetMs = Math.round(offsetHours * 3600000);
          var targetDate = new Date(date.getTime() + offsetMs);
          year = targetDate.getUTCFullYear();
          month = targetDate.getUTCMonth();
          dayOfMonth = targetDate.getUTCDate();
          dayOfWeek = targetDate.getUTCDay();
          hours24 = targetDate.getUTCHours();
          minutes = targetDate.getUTCMinutes();
          seconds = targetDate.getUTCSeconds();
        } else {
          year = date.getFullYear();
          month = date.getMonth();
          dayOfMonth = date.getDate();
          dayOfWeek = date.getDay();
          hours24 = date.getHours();
          minutes = date.getMinutes();
          seconds = date.getSeconds();
        }
      }
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

  const localOffsetHours = -date.getTimezoneOffset() / 60;
  const effectiveOffsetHours = (offsetHours !== null && offsetHours !== undefined) ? offsetHours : localOffsetHours;

  const tzOffsetStr = formatTzOffset(effectiveOffsetHours);
  const tzRelStr = formatTzRelative(effectiveOffsetHours, localOffsetHours);

  const compiled = compileFormat(formatStr);

  var result = "";
  for (var k = 0; k < compiled.length; k++) {
    var tok = compiled[k];
    if (tok.isToken) {
      result += getTokenValue(tok.value, year, month, dayOfMonth, dayOfWeek, hours24, hours12, minutes, seconds, ampmUpper, ampmLower, tzLabel, names, tzOffsetStr, tzRelStr, date);
    } else {
      result += tok.value;
    }
  }

  return result;
}