package com.gck.demo.paymentgateway.customer.model;

import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.Date;

public class Customer {
	private String accountId;
    private String name;
    private int age;
    private String nationality;
    private String address;
    private long accountLastUpdatedDate;
    private long accountCreatedDate;
    private double balance;
    private long balanceLastUpdatedDate;
    private SimpleDateFormat df;
    private DecimalFormat ef;
    
    public Customer() {
    	df = new SimpleDateFormat("dd/MM/yyyy hh:mm:ss");
    	ef = new DecimalFormat("#,###,##0.00");
    }
    
    
	public String getAccountId() {
		return accountId;
	}
	public void setAccountId(String accountId) {
		this.accountId = accountId;
	}
	
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public int getAge() {
		return age;
	}
	public void setAge(int age) {
		this.age = age;
	}
	public String getNationality() {
		return nationality;
	}
	public void setNationality(String nationality) {
		this.nationality = nationality;
	}
	public String getAddress() {
		return address;
	}
	public void setAddress(String address) {
		this.address = address;
	}
	public long getAccountLastUpdatedDate() {
		return accountLastUpdatedDate;
	}
	
	public String getFormattedAccountLastUpdatedDate() {
		return df.format(new Date(accountLastUpdatedDate));
	}
	
	public void setAccountLastUpdatedDate(long accountLastUpdatedDate) {
		this.accountLastUpdatedDate = accountLastUpdatedDate;
	}
	public long getAccountCreatedDate() {
		return accountCreatedDate;
	}
	
	public String getFormattedAccountCreatedDate() {
		return df.format(new Date(accountCreatedDate));
	}
	
	public void setAccountCreatedDate(long accountCreatedDate) {
		this.accountCreatedDate = accountCreatedDate;
	}
	public double getBalance() {
		return balance;
	}
	public String getFormattedBalance() {
		return ef.format(balance);
	}
	public void setBalance(double balance) {
		this.balance = balance;
	}
	public long getBalanceLastUpdatedDate() {
		return balanceLastUpdatedDate;
	}
	public void setBalanceLastUpdatedDate(long balanceLastUpdatedDate) {
		this.balanceLastUpdatedDate = balanceLastUpdatedDate;
	}
	
	public String getFormattedBalanceLastUpdatedDate() {
		return df.format(new Date(balanceLastUpdatedDate));
	}
}
