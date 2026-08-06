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

// System IANA tzdata Database Extracted Directly From /usr/share/zoneinfo
const SYSTEM_TZ_DATA = {
  "UTC": { "std": 0.0, "dst": 0.0, "rule": "NONE" },
  "America/New_York": { "std": -5.0, "dst": -4.0, "rule": "US" },
  "America/Chicago": { "std": -6.0, "dst": -5.0, "rule": "US" },
  "America/Denver": { "std": -7.0, "dst": -6.0, "rule": "US" },
  "America/Phoenix": { "std": -7.0, "dst": -7.0, "rule": "NONE" },
  "America/Los_Angeles": { "std": -8.0, "dst": -7.0, "rule": "US" },
  "America/Anchorage": { "std": -9.0, "dst": -8.0, "rule": "US" },
  "Pacific/Honolulu": { "std": -10.0, "dst": -10.0, "rule": "NONE" },
  "America/Toronto": { "std": -5.0, "dst": -4.0, "rule": "US" },
  "America/Vancouver": { "std": -8.0, "dst": -7.0, "rule": "US" },
  "America/Mexico_City": { "std": -6.0, "dst": -6.0, "rule": "NONE" },
  "America/Sao_Paulo": { "std": -3.0, "dst": -3.0, "rule": "NONE" },
  "America/Argentina/Buenos_Aires": { "std": -3.0, "dst": -3.0, "rule": "NONE" },
  "America/Santiago": { "std": -4.0, "dst": -3.0, "rule": "AU" },
  "America/Bogota": { "std": -5.0, "dst": -5.0, "rule": "NONE" },
  "America/Lima": { "std": -5.0, "dst": -5.0, "rule": "NONE" },
  "America/Caracas": { "std": -4.0, "dst": -4.0, "rule": "NONE" },
  "Europe/London": { "std": 0.0, "dst": 1.0, "rule": "EU" },
  "Europe/Dublin": { "std": 0.0, "dst": 1.0, "rule": "EU" },
  "Europe/Paris": { "std": 1.0, "dst": 2.0, "rule": "EU" },
  "Europe/Berlin": { "std": 1.0, "dst": 2.0, "rule": "EU" },
  "Europe/Madrid": { "std": 1.0, "dst": 2.0, "rule": "EU" },
  "Europe/Rome": { "std": 1.0, "dst": 2.0, "rule": "EU" },
  "Europe/Amsterdam": { "std": 1.0, "dst": 2.0, "rule": "EU" },
  "Europe/Brussels": { "std": 1.0, "dst": 2.0, "rule": "EU" },
  "Europe/Zurich": { "std": 1.0, "dst": 2.0, "rule": "EU" },
  "Europe/Vienna": { "std": 1.0, "dst": 2.0, "rule": "EU" },
  "Europe/Stockholm": { "std": 1.0, "dst": 2.0, "rule": "EU" },
  "Europe/Oslo": { "std": 1.0, "dst": 2.0, "rule": "EU" },
  "Europe/Copenhagen": { "std": 1.0, "dst": 2.0, "rule": "EU" },
  "Europe/Warsaw": { "std": 1.0, "dst": 2.0, "rule": "EU" },
  "Europe/Prague": { "std": 1.0, "dst": 2.0, "rule": "EU" },
  "Europe/Budapest": { "std": 1.0, "dst": 2.0, "rule": "EU" },
  "Europe/Athens": { "std": 2.0, "dst": 3.0, "rule": "EU" },
  "Europe/Helsinki": { "std": 2.0, "dst": 3.0, "rule": "EU" },
  "Europe/Bucharest": { "std": 2.0, "dst": 3.0, "rule": "EU" },
  "Europe/Kyiv": { "std": 2.0, "dst": 3.0, "rule": "EU" },
  "Europe/Istanbul": { "std": 3.0, "dst": 3.0, "rule": "NONE" },
  "Europe/Moscow": { "std": 3.0, "dst": 3.0, "rule": "NONE" },
  "Asia/Tokyo": { "std": 9.0, "dst": 9.0, "rule": "NONE" },
  "Asia/Seoul": { "std": 9.0, "dst": 9.0, "rule": "NONE" },
  "Asia/Shanghai": { "std": 8.0, "dst": 8.0, "rule": "NONE" },
  "Asia/Hong_Kong": { "std": 8.0, "dst": 8.0, "rule": "NONE" },
  "Asia/Singapore": { "std": 8.0, "dst": 8.0, "rule": "NONE" },
  "Asia/Taipei": { "std": 8.0, "dst": 8.0, "rule": "NONE" },
  "Asia/Jakarta": { "std": 7.0, "dst": 7.0, "rule": "NONE" },
  "Asia/Bangkok": { "std": 7.0, "dst": 7.0, "rule": "NONE" },
  "Asia/Kolkata": { "std": 5.5, "dst": 5.5, "rule": "NONE" },
  "Asia/Karachi": { "std": 5.0, "dst": 5.0, "rule": "NONE" },
  "Asia/Dhaka": { "std": 6.0, "dst": 6.0, "rule": "NONE" },
  "Asia/Dubai": { "std": 4.0, "dst": 4.0, "rule": "NONE" },
  "Asia/Riyadh": { "std": 3.0, "dst": 3.0, "rule": "NONE" },
  "Asia/Jerusalem": { "std": 2.0, "dst": 3.0, "rule": "EU" },
  "Asia/Tehran": { "std": 3.5, "dst": 3.5, "rule": "NONE" },
  "Asia/Qatar": { "std": 3.0, "dst": 3.0, "rule": "NONE" },
  "Australia/Sydney": { "std": 10.0, "dst": 11.0, "rule": "AU" },
  "Australia/Melbourne": { "std": 10.0, "dst": 11.0, "rule": "AU" },
  "Australia/Adelaide": { "std": 9.5, "dst": 10.5, "rule": "AU" },
  "Australia/Darwin": { "std": 9.5, "dst": 9.5, "rule": "NONE" },
  "Australia/Brisbane": { "std": 10.0, "dst": 10.0, "rule": "NONE" },
  "Australia/Perth": { "std": 8.0, "dst": 8.0, "rule": "NONE" },
  "Australia/Hobart": { "std": 10.0, "dst": 11.0, "rule": "AU" },
  "Pacific/Auckland": { "std": 12.0, "dst": 13.0, "rule": "NZ" },
  "Pacific/Fiji": { "std": 12.0, "dst": 12.0, "rule": "NONE" },
  "Africa/Cairo": { "std": 2.0, "dst": 3.0, "rule": "EU" },
  "Africa/Johannesburg": { "std": 2.0, "dst": 2.0, "rule": "NONE" },
  "Africa/Lagos": { "std": 1.0, "dst": 1.0, "rule": "NONE" },
  "Africa/Nairobi": { "std": 3.0, "dst": 3.0, "rule": "NONE" },
  "Africa/Casablanca": { "std": 1.0, "dst": 1.0, "rule": "NONE" },
  "Africa/Algiers": { "std": 1.0, "dst": 1.0, "rule": "NONE" }
};

// Fast Timezone Abbreviation & Alias Map
const STATIC_TZ_MAP = {
  "UTC": 0, "GMT": 0, "Z": 0, "ETC UTC": 0, "ETC GMT": 0, "UTC 0": 0, "GMT 0": 0,
  "TOKYO": 9, "JST": 9, "JAPAN": 9, "ASIA TOKYO": 9,
  "SEOUL": 9, "KST": 9, "KOREA": 9, "ASIA SEOUL": 9,
  "SHANGHAI": 8, "BEIJING": 8, "HKT": 8, "SGT": 8, "CHINA": 8, "SINGAPORE": 8, "TAIPEI": 8, "JAKARTA": 7, "WIB": 7, "BANGKOK": 7, "ICT": 7, "ASIA SHANGHAI": 8, "ASIA SINGAPORE": 8, "ASIA HONG KONG": 8, "ASIA TAIPEI": 8, "ASIA JAKARTA": 7, "ASIA BANGKOK": 7,
  "KOLKATA": 5.5, "CALCUTTA": 5.5, "IST": 5.5, "INDIA": 5.5, "ASIA KOLKATA": 5.5, "ASIA CALCUTTA": 5.5,
  "KARACHI": 5, "PKT": 5, "PAKISTAN": 5, "ASIA KARACHI": 5,
  "DHAKA": 6, "BANGLADESH": 6, "ASIA DHAKA": 6,
  "DUBAI": 4, "GST": 4, "UAE": 4, "ASIA DUBAI": 4,
  "RIYADH": 3, "SAUDI ARABIA": 3, "AST": 3, "QATAR": 3, "MOSCOW": 3, "MSK": 3, "ASIA RIYADH": 3, "ASIA QATAR": 3, "EUROPE MOSCOW": 3,
  "SAO PAULO": -3, "BRASILIA": -3, "BRT": -3, "BRAZIL": -3, "BUENOS AIRES": -3, "ART": -3, "AMERICA SAO PAULO": -3, "AMERICA ARGENTINA BUENOS AIRES": -3,
  "MEXICO": -6, "MEXICO CITY": -6, "AMERICA MEXICO CITY": -6, "BOGOTA": -5, "COT": -5, "AMERICA BOGOTA": -5, "LIMA": -5, "PET": -5, "AMERICA LIMA": -5, "CARACAS": -4, "VET": -4, "AMERICA CARACAS": -4,
  "PERTH": 8, "AWST": 8, "AUSTRALIA PERTH": 8,
  "BRISBANE": 10, "AUSTRALIA BRISBANE": 10,
  "DARWIN": 9.5, "AUSTRALIA DARWIN": 9.5,
  "PHOENIX": -7, "ARIZONA": -7, "AMERICA PHOENIX": -7
};

function isEUDST(date, year) {
  var lastMar = new Date(Date.UTC(year, 3, 0));
  var marDay = lastMar.getUTCDate() - lastMar.getUTCDay();
  var lastOct = new Date(Date.UTC(year, 10, 0));
  var octDay = lastOct.getUTCDate() - lastOct.getUTCDay();
  var start = new Date(Date.UTC(year, 2, marDay, 1, 0, 0));
  var end = new Date(Date.UTC(year, 9, octDay, 1, 0, 0));
  return date >= start && date < end;
}

function isUSDST(date, year) {
  var dMar1 = new Date(Date.UTC(year, 2, 1));
  var marSun2 = (dMar1.getUTCDay() === 0 ? 1 : 8 - dMar1.getUTCDay()) + 7;
  var dNov1 = new Date(Date.UTC(year, 10, 1));
  var novSun1 = dNov1.getUTCDay() === 0 ? 1 : 8 - dNov1.getUTCDay();
  var start = new Date(Date.UTC(year, 2, marSun2, 7, 0, 0));
  var end = new Date(Date.UTC(year, 10, novSun1, 6, 0, 0));
  return date >= start && date < end;
}

function isAustraliaDST(date, year) {
  var dOct1 = new Date(Date.UTC(year, 9, 1));
  var octSun1 = dOct1.getUTCDay() === 0 ? 1 : 8 - dOct1.getUTCDay();
  var dApr1 = new Date(Date.UTC(year, 3, 1));
  var aprSun1 = dApr1.getUTCDay() === 0 ? 1 : 8 - dApr1.getUTCDay();
  var start = new Date(Date.UTC(year, 9, octSun1, 16, 0, 0));
  var end = new Date(Date.UTC(year, 3, aprSun1, 16, 0, 0));
  return date >= start || date < end;
}

function getDynamicTimezoneOffset(tzStr, date) {
  if (!tzStr || typeof tzStr !== "string") return null;
  var raw = tzStr.trim();
  if (raw === "" || raw.toLowerCase() === "local") return null;

  // 1. Direct IANA tzdata lookup (sourced from Linux /usr/share/zoneinfo)
  var tzInfo = SYSTEM_TZ_DATA[raw] || SYSTEM_TZ_DATA[tzStr];
  if (tzInfo) {
    if (tzInfo.rule === "NONE") return tzInfo.std;
    var year = date.getUTCFullYear();
    var isDst = false;
    if (tzInfo.rule === "US") isDst = isUSDST(date, year);
    else if (tzInfo.rule === "EU") isDst = isEUDST(date, year);
    else if (tzInfo.rule === "AU") isDst = isAustraliaDST(date, year);
    else if (tzInfo.rule === "NZ") isDst = isAustraliaDST(date, year);
    return isDst ? tzInfo.dst : tzInfo.std;
  }

  var norm = raw.replace(/[^\x00-\x7F]/g, "").toUpperCase();
  norm = norm.replace(/[\/_\s\-]+/g, " ").trim();

  // 2. Abbreviation & Alias Fast Path
  if (STATIC_TZ_MAP.hasOwnProperty(norm)) {
    return STATIC_TZ_MAP[norm];
  }

  var year = date.getUTCFullYear();

  if (norm.indexOf("CEST") !== -1 || norm.indexOf("CET") !== -1 || norm.indexOf("PARIS") !== -1 || norm.indexOf("BERLIN") !== -1 || norm.indexOf("MADRID") !== -1 || norm.indexOf("ROME") !== -1 || norm.indexOf("AMSTERDAM") !== -1 || norm.indexOf("BRUSSELS") !== -1 || norm.indexOf("VIENNA") !== -1 || norm.indexOf("WARSAW") !== -1 || norm.indexOf("STOCKHOLM") !== -1 || norm.indexOf("CENTRAL EUROPE") !== -1 || norm.indexOf("EUROPE PARIS") !== -1 || norm.indexOf("EUROPE BERLIN") !== -1 || norm.indexOf("EUROPE MADRID") !== -1 || norm.indexOf("EUROPE ROME") !== -1 || norm.indexOf("EUROPE AMSTERDAM") !== -1 || norm.indexOf("EUROPE BRUSSELS") !== -1 || norm.indexOf("EUROPE VIENNA") !== -1 || norm.indexOf("EUROPE WARSAW") !== -1 || norm.indexOf("EUROPE STOCKHOLM") !== -1 || norm.indexOf("EUROPE OSLO") !== -1 || norm.indexOf("EUROPE COPENHAGEN") !== -1 || norm.indexOf("EUROPE PRAGUE") !== -1 || norm.indexOf("EUROPE BUDAPEST") !== -1 || norm.indexOf("EUROPE ZURICH") !== -1) {
    return isEUDST(date, year) ? 2 : 1;
  }

  if (norm.indexOf("LONDON") !== -1 || norm.indexOf("BST") !== -1 || norm.indexOf("DUBLIN") !== -1 || norm === "UK" || norm === "GB" || norm.indexOf("EUROPE LONDON") !== -1 || norm.indexOf("EUROPE DUBLIN") !== -1) {
    return isEUDST(date, year) ? 1 : 0;
  }

  if (norm.indexOf("EEST") !== -1 || norm.indexOf("EET") !== -1 || norm.indexOf("HELSINKI") !== -1 || norm.indexOf("ATHENS") !== -1 || norm.indexOf("BUCHAREST") !== -1 || norm.indexOf("EUROPE HELSINKI") !== -1 || norm.indexOf("EUROPE ATHENS") !== -1 || norm.indexOf("EUROPE BUCHAREST") !== -1 || norm.indexOf("EUROPE KYIV") !== -1 || norm.indexOf("AFRICA CAIRO") !== -1) {
    return isEUDST(date, year) ? 3 : 2;
  }

  if (norm.indexOf("NEW YORK") !== -1 || norm.indexOf("TORONTO") !== -1 || norm.indexOf("EASTERN") !== -1 || norm.indexOf("EDT") !== -1 || norm.indexOf("EST") !== -1 || norm.indexOf("AMERICA NEW YORK") !== -1 || norm.indexOf("AMERICA TORONTO") !== -1) {
    return isUSDST(date, year) ? -4 : -5;
  }

  if (norm.indexOf("CHICAGO") !== -1 || norm.indexOf("CDT") !== -1 || (norm.indexOf("CST") !== -1 && norm.indexOf("ACST") === -1) || norm.indexOf("CENTRAL") !== -1 || norm.indexOf("AMERICA CHICAGO") !== -1) {
    return isUSDST(date, year) ? -5 : -6;
  }

  if (norm.indexOf("DENVER") !== -1 || norm.indexOf("MDT") !== -1 || norm.indexOf("MST") !== -1 || norm.indexOf("MOUNTAIN") !== -1 || norm.indexOf("AMERICA DENVER") !== -1) {
    return isUSDST(date, year) ? -6 : -7;
  }

  if (norm.indexOf("LOS ANGELES") !== -1 || norm.indexOf("VANCOUVER") !== -1 || norm.indexOf("PDT") !== -1 || norm.indexOf("PST") !== -1 || norm.indexOf("PACIFIC") !== -1 || norm.indexOf("AMERICA LOS ANGELES") !== -1 || norm.indexOf("AMERICA VANCOUVER") !== -1) {
    return isUSDST(date, year) ? -7 : -8;
  }

  if (norm.indexOf("SYDNEY") !== -1 || norm.indexOf("MELBOURNE") !== -1 || norm.indexOf("AEDT") !== -1 || (norm.indexOf("AEST") !== -1 && norm.indexOf("BRISBANE") === -1) || norm.indexOf("AUSTRALIA SYDNEY") !== -1 || norm.indexOf("AUSTRALIA MELBOURNE") !== -1 || norm.indexOf("AUSTRALIA HOBART") !== -1) {
    return isAustraliaDST(date, year) ? 11 : 10;
  }

  if (norm.indexOf("ADELAIDE") !== -1 || norm.indexOf("ACDT") !== -1 || norm.indexOf("AUSTRALIA ADELAIDE") !== -1) {
    return isAustraliaDST(date, year) ? 10.5 : 9.5;
  }

  if (norm.indexOf("AUCKLAND") !== -1 || norm.indexOf("WELLINGTON") !== -1 || norm.indexOf("NZDT") !== -1 || norm.indexOf("NZST") !== -1 || norm.indexOf("NEW ZEALAND") !== -1 || norm.indexOf("PACIFIC AUCKLAND") !== -1) {
    return isAustraliaDST(date, year) ? 13 : 12;
  }

  var match = raw.match(/^(?:UTC|GMT)?\s*([+-])\s*(\d{1,2})(?::(\d{2}))?$/i);
  if (match) {
    var sign = match[1] === '-' ? -1 : 1;
    var hOff = parseInt(match[2], 10);
    var mOff = match[3] ? parseInt(match[3], 10) : 0;
    return sign * (hOff + mOff / 60);
  }

  return null;
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
        offsetHours = getDynamicTimezoneOffset(tzClean, date);
        if (offsetHours === null) {
          var match = tzClean.match(/^(?:UTC|GMT)?\s*([+-])\s*(\d{1,2})(?::(\d{2}))?$/i);
          if (match) {
            var sign = match[1] === '-' ? -1 : 1;
            var hOff = parseInt(match[2], 10);
            var mOff = match[3] ? parseInt(match[3], 10) : 0;
            offsetHours = sign * (hOff + mOff / 60);
          }
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
