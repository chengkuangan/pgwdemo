
var log_level = process.env.LOG_LEVEL || 'debug';
var commond = require('./common');

exports.info = function (message) {
    console.info(commond.currentDateTime() + '  INFO  ' + message);
}

exports.error = function (message) {
    console.error(commond.currentDateTime() + '  ERROR  ' + message);
}

exports.debug = function (message) {
    if (log_level == 'debug'){
        console.debug(commond.currentDateTime() + '  DEBUG  ' + message);
    }
}

exports.warn = function (message) {
    console.warn(commond.currentDateTime() + '  WARN  ' + message);
}

