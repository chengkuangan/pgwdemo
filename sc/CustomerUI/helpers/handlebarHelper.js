var hbs = require('hbs');

exports.ifEquals = function (v1, v2, options) {
    //console.log('v1 = ' + v1 + ', v2 = ' + v2 + '. (v1 == v2) = ' + (v1 == v2));
    return (v1 == v2) ? options.fn(this) : options.inverse(this);
};

exports.ifNotEquals = function (v1, v2, options) {
    return (v1 != v2) ? options.fn(this) : options.inverse(this);
};

exports.ifNull = function (v1, options) {
    //console.log("v1 = " + v1);
    return (v1 == null) ? options.fn(this) : options.inverse(this);
};

exports.displayTopMenuBar = function () {
    //console.log("customer = " + customer);
    var str = '';
    
    str = '<div class="topmenu-bar">';
    str += '<div class="topmenu-bar-item" id="menu-home" onclick="javascript:window.location.href=\'/\'">Home</div>';
    str += '<div class="topmenu-bar-item" id="menu-home" onclick="javascript:window.location.href=\'/transfer\'">Make A Transfer</div>';
    str += '<div class="topmenu-bar-item" id="menu-home" onclick="javascript:window.location.href=\'/transactions\'">View Transactions</div>';
    str += '<div class="topmenu-bar-item" id="menu-logout" onclick="javascript:window.location.href=\'/logout\'">Logout</div>';
    str += '</div>';

    return new hbs.SafeString(str);
};

exports.displayFooter = function (){
    var str = '';
    str = '<div class="footer">';
    str += '<div class="footer-item"><a target="_blank" href="https://github.com/chengkuangan/pgwdemo">GitHub</a></div>';
    str += '<div class="footer-item"><a target="_blank" href="https://www.youtube.com/channel/UCrubQtLJ_hHPJK3xRHb1mzA">Youtube</a></div>';
    str += '<div class="footer-item"><a target="_blank" href="https://braindose.blog">Blog</a></div>';
    str += '</div>';
    return new hbs.SafeString(str);
}
