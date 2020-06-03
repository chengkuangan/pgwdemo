
var uniqid = require('uniqid');

function Credit(){
    this._id = uniqid();
    this.createdDate = Date.now;
}

function Credit(_id, amount, targetAccount, sourceAccount, createdDate){
    this._id = _id;
    this.amount = amount;
    this.targetAccount = targetAccount;
    this.sourceAccount = sourceAccount;
    this.createdDate = createdDate;
}

function Credit(amount, targetAccount, sourceAccount, createdDate){
    this._id = uniqid();
    this.amount = amount;
    this.targetAccount = targetAccount;
    this.sourceAccount = sourceAccount;
    this.createdDate = createdDate;
}

function Credit(amount, targetAccount, sourceAccount){
    this._id = uniqid();
    this.amount = amount;
    this.targetAccount = targetAccount;
    this.sourceAccount = sourceAccount;
    this.createdDate = Date.now;
}

Credit.prototype.get_id = function() {
    return this._id;
}

Credit.prototype.set_id = function(_id) {
    this._id = _id;
}

Credit.prototype.getAmount = function() {
    return this.amount;
}

Credit.prototype.setAmount = function(amount) {
    this.amount = amount;
}

Credit.prototype.getTargetAccount = function() {
    return this.targetAccount;
}

Credit.prototype.setTargetAccount = function(targetAccount) {
    this.targetAccount = targetAccount;
}

Credit.prototype.getSourceAccount = function() {
    return this.sourceAccount;
}

Credit.prototype.setSourceAccount = function(sourceAccount) {
    this.sourceAccount = sourceAccount;
}

Credit.prototype.getCreatedDate = function() {
    return this.createdDate;
}

Credit.prototype.setAmount = function(createdDate) {
    this.createdDate = this.createdDate;
}

Credit.prototype.equals = function(otherCredit) {
    return otherCredit.get_id() == this.get_id();
}

Credit.prototype.fill = function(newFields) {
    for (var field in newFields) {
        if (this.hasOwnProperty(field) && newFields.hasOwnProperty(field)) {
            if (this[field] !== 'undefined') {
                this[field] = newFields[field];
            }
        }
    }
};

module.exports = Credit;  