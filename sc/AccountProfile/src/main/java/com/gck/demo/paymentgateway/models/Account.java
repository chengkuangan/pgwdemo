package com.gck.demo.paymentgateway.models;

import java.util.List;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "account")
public class Account{

    @Id
    private String _id;
    private String accountId;
    private String socialId;
    private String email;
    private String contactNumber;
    private String name;
    private int age;
    private String nationality;
    private String address;
    private long lastUpdatedDate;
    private long createdDate;
    
    public Account(){

    }

    public Account(String _id, String accountId, String socialId, String email, String contactNumber, String name, int age, String nationality, String address, long lastUpdatedDate, long createdDate){
        this._id = _id;
        this.accountId =accountId;
        this.socialId = socialId;
        this.email = email;
        this.contactNumber = contactNumber;
        this.name = name;
        this.age = age;
        this.nationality = nationality;
        this.address = address;
        this.lastUpdatedDate = lastUpdatedDate;
        this.createdDate = createdDate;
    }
    
    
    public Account(String accountId, String socialId, String email, String contactNumber, String name, int age, String nationality, String address, long lastUpdatedDate, long createdDate){
        this.accountId =accountId;
        this.socialId = socialId;
        this.email = email;
        this.contactNumber = contactNumber;
        this.name = name;
        this.age = age;
        this.nationality = nationality;
        this.address = address;
        this.lastUpdatedDate = lastUpdatedDate;
        this.createdDate = createdDate;
    }
    


    /**
     * @return String return the _id
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
     * @return String return the name
     */
    public String getName() {
        return name;
    }

    /**
     * @param name the name to set
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * @return int return the age
     */
    public int getAge() {
        return age;
    }

    /**
     * @param age the age to set
     */
    public void setAge(int age) {
        this.age = age;
    }

    /**
     * @return String return the nationality
     */
    public String getNationality() {
        return nationality;
    }

    /**
     * @param nationality the nationality to set
     */
    public void setNationality(String nationality) {
        this.nationality = nationality;
    }

    /**
     * @return String return the address
     */
    public String getAddress() {
        return address;
    }

    /**
     * @param address the address to set
     */
    public void setAddress(String address) {
        this.address = address;
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

    /**
     * @return long return the createdDate
     */
    public long getCreatedDate() {
        return createdDate;
    }

    /**
     * @param createdDate the createdDate to set
     */
    public void setCreatedDate(long createdDate) {
        this.createdDate = createdDate;
    }

}