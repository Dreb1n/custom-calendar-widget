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

function getOrdinal(n) {
  const v = n % 100;
  return n + (ORDINAL_SUFFIXES[(v - 20) % 10] || ORDINAL_SUFFIXES[v] || ORDINAL_SUFFIXES[0]);
}

function padZero(num, length) {
  if (length === undefined) length = 2;
  var str = String(num);
  while (str.length < length) {
    str = "0" + str;
  }
  return str;
}

function getWeekNumber(d) {
  const target = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
  target.setUTCDate(target.getUTCDate() + 4 - (target.getUTCDay() || 7));
  const yearStart = new Date(Date.UTC(target.getUTCFullYear(), 0, 1));
  return Math.ceil((((target - yearStart) / 86400000) + 1) / 7);
}

function getDateInTimezone(date, timeZone) {
  if (!timeZone || timeZone === "local" || timeZone.trim() === "") {
    return date;
  }
  const key = timeZone.trim();
  try {
    if (!FORMATTER_CACHE[key]) {
      FORMATTER_CACHE[key] = new Intl.DateTimeFormat('en-US', {
        timeZone: key,
        year: 'numeric', month: 'numeric', day: 'numeric',
        hour: 'numeric', minute: 'numeric', second: 'numeric',
        hour12: false
      });
    }
    const parts = FORMATTER_CACHE[key].formatToParts(date);
    var p = {};
    for (var i = 0; i < parts.length; i++) {
      p[parts[i].type] = parseInt(parts[i].value, 10);
    }
    return new Date(p.year, p.month - 1, p.day, p.hour % 24, p.minute, p.second || 0);
  } catch (e) {
    return date;
  }
}

function format(date, formatStr, timeZone) {
  if (!date || isNaN(date.getTime())) {
    date = new Date();
  }
  if (!formatStr || typeof formatStr !== "string") {
    return "";
  }

  const tzDate = getDateInTimezone(date, timeZone);

  const year = tzDate.getFullYear();
  const month = tzDate.getMonth();
  const dayOfMonth = tzDate.getDate();
  const dayOfWeek = tzDate.getDay();
  const hours24 = tzDate.getHours();
  const hours12 = hours24 % 12 || 12;
  const minutes = tzDate.getMinutes();
  const seconds = tzDate.getSeconds();
  const ampmUpper = hours24 >= 12 ? "PM" : "AM";
  const ampmLower = hours24 >= 12 ? "pm" : "am";
  const tzLabel = timeZone && timeZone !== "local" ? timeZone : "";

  var placeholders = [];
  var tempStr = formatStr.replace(/\[([^\]]+)\]/g, function(match, p1) {
    placeholders.push(p1);
    return "__PH_" + (placeholders.length - 1) + "__";
  });

  const getValue = function(token) {
    switch (token) {
      case "dddd": case "EEEE": return DAY_NAMES_FULL[dayOfWeek];
      case "ddd": case "EEE": return DAY_NAMES_SHORT[dayOfWeek];
      case "mmmm": case "MMMM": return MONTH_NAMES_FULL[month];
      case "mmm": case "MMM": return MONTH_NAMES_SHORT[month];
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
      case "WW": return padZero(getWeekNumber(tzDate), 2);
      case "W": return String(getWeekNumber(tzDate));
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
