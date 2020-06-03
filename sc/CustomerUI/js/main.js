

function submitTransfer(){
    var validator = new Validator();
    validator.addField(document.getElementsByName("toAccountId")[0]);
    validator.addField(document.getElementsByName("amount")[0]);
    
    if (validator.validate()){
        document.getElementsByName("frmTransfer")[0].action="/transfer";
        document.getElementsByName("frmTransfer")[0].submit();
    }
}