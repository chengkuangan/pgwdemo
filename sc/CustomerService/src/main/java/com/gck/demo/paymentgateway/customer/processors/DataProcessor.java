package com.gck.demo.paymentgateway.customer.processors;

import java.util.List;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;

import com.gck.demo.paymentgateway.customer.model.AccountProfile;
import com.gck.demo.paymentgateway.customer.model.Balance;
import com.gck.demo.paymentgateway.customer.model.Customer;
import com.gck.demo.paymentgateway.customer.model.CustomerList;

public class DataProcessor implements Processor {

	@Override
	public void process(Exchange exchange) throws Exception {
		
		boolean singleRecord = exchange.getProperty("SINGLE_RECORD", Boolean.class);
		AccountProfile profile = null;
		
		if (singleRecord) {
			//List<AccountProfile> profileList = (List) exchange.getProperty("CUST_PROFILES");
			//profile = profileList.get(0);
			profile = (AccountProfile) exchange.getProperty("CUST_PROFILES");
		}
		else {
			profile = (AccountProfile) exchange.getProperty("CUST_PROF");
		}
		
		Balance balance = (Balance) exchange.getProperty("ACCOUNT_BALANCE");
		
		Customer customer = new Customer();
		customer.setAccountCreatedDate(profile.getCreatedDate());
		customer.setAccountId(profile.getAccountId());
		customer.setAccountLastUpdatedDate(profile.getLastUpdatedDate());
		customer.setAddress(profile.getAddress());
		customer.setAge(profile.getAge());
		customer.setBalance(balance.getBalance());
		customer.setBalanceLastUpdatedDate(balance.getLastUpdatedDate());
		customer.setName(profile.getName());
		customer.setNationality(profile.getNationality());
		
		Object obj = exchange.getProperty("CUST_LIST");
		List<Customer> list = null;
		
		if (obj != null) {
			list = (List<Customer>)obj;
		}
		else {
			list = new CustomerList();
			exchange.setProperty("CUST_LIST", list);
		}
		
		list.add(customer);
		
		exchange.getOut().setBody(list);
		
		
		/*
		AccountProfile profile = (AccountProfile) exchange.getProperty("custProfile");
		Balance balance = (Balance) exchange.getProperty("accountBalance");
		Customer customer = new Customer();
		
		customer.setAccountCreatedDate(profile.getCreatedDate());
		customer.setAccountId(profile.getAccountId());
		customer.setAccountLastUpdatedDate(profile.getLastUpdatedDate());
		customer.setAddress(profile.getAddress());
		customer.setAge(profile.getAge());
		customer.setBalance(balance.getBalance());
		customer.setBalanceLastUpdatedDate(balance.getLastUpdatedDate());
		customer.setName(profile.getName());
		customer.setNationality(profile.getNationality());
		
		
		*/
	}

}
