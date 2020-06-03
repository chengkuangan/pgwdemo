package com.gck.demo.paymentgateway.accountbalance.models;

import java.util.List;
import org.bson.types.ObjectId;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "balance")
public class Balance{

    @Id
    private String _id;
    private String accountId;
    private double balance;
    private long lastUpdatedDate;
    
    public Balance(){

    }

    public Balance(String _id, String accountId, double balance, long lastUpdatedDate){
        this._id = _id;
        this.accountId =accountId;
        this.balance = balance;
        this.lastUpdatedDate = lastUpdatedDate;
    }

    public Balance(String accountId, double balance, long lastUpdatedDate){
        this.accountId =accountId;
        this.balance = balance;
        this.lastUpdatedDate = lastUpdatedDate;
    }

    /**
     * @return ObjectId return the _id
     */
    public String get_id() {
        return _id;
    }

    /**
     * @param _id the _id to set
     */
    public void set_id(String _id) {
        this._id = _id;
    }

    /**
     * @return String return the accountId
     */
    public String getAccountId() {
        return accountId;
    }

    /**
     * @param accountId the accountId to set
     */
    public void setAccountId(String accountId) {
        this.accountId = accountId;
    }

    /**
     * @return double return the balance
     */
    public double getBalance() {
        return balance;
    }

    /**
     * @param balance the balance to set
     */
    public void setBalance(double balance) {
        this.balance = balance;
    }

    /**
     * @return long return the lastUpdatedDate
     */
    public long getLastUpdatedDate() {
        return lastUpdatedDate;
    }

    /**
     * @param lastUpdatedDate the lastUpdatedDate to set
     */
    public void setLastUpdatedDate(long lastUpdatedDate) {
        this.lastUpdatedDate = lastUpdatedDate;
    }

}