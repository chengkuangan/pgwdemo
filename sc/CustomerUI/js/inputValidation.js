function Validator(){
    
    var fields = [];
    this.addField = function(element){
        fields.push({'element': element});
        element.addEventListener('keyup', this.keyupEvent);
    };

    this.validate = function(){
        var isValid = true;
        for (var i = 0; i < fields.length; i++){
            var f = fields[i];
            f.element.style.borderBottomColor = '';
            if (f.element !== 'undefined'){
                if (f.element.getAttribute('data-mandatory') && f.element.value.trim() == ''){
                    f.element.style.borderBottomColor = 'red';
                    isValid = false;
                }
                else if (f.element.getAttribute('data-type') !== 'undefined' && f.element.getAttribute('data-type') == 'email'){
                    var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
                    if (!re.test(String(f.element.value).toLowerCase())){
                        f.element.style.borderBottomColor = 'red';
                        isValid = false;
                    }
                } 
            }
        }
        return isValid;
    };

    this.keyupEvent = function(event){
        if (event.target.value.length > 0){
            event.target.style.borderBottomColor = '';
        }
    }

}