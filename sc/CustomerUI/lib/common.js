

exports.currentDateTime = function(){
    let ts = Date.now();
    let date_ob = new Date(ts);
    let sec = date_ob.getSeconds();
    let min = date_ob.getMinutes();
    let hour = date_ob.getHours();
    let date = date_ob.getDate();
    let month = date_ob.getMonth() + 1;
    let year = date_ob.getFullYear();
    return year + '-' + (month < 10 ? "0" + month : "" ) + '-' + (date < 10 ? "0" + date : date) + ' ' + (hour < 10 ? "0" + hour : hour) + ':' + (min < 10 ? "0" + min : min) + ':' + (sec < 10 ? "0" + sec : sec); 
}