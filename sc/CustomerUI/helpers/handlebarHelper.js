var hbs = require('hbs');

exports.ifEquals = function (v1, v2, options) {
    return (v1 == v2) ? options.fn(this) : options.inverse(this);
};

exports.ifNull = function (v1, options) {
    console.log("v1 = " + v1);
    return (v1 == null) ? options.fn(this) : options.inverse(this);
};
