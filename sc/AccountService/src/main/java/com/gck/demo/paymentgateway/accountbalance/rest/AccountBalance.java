package com.gck.demo.paymentgateway.accountbalance.rest;

import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.core.env.Environment;
import org.springframework.data.domain.Example;
import org.springframework.data.repository.Repository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;

import com.gck.demo.paymentgateway.accountbalance.db.*;
import com.gck.demo.paymentgateway.accountbalance.models.*;

/**
 * Provides information about this service
 *
 * Created by ganck.
 */
@RequestMapping("/ws/pg")
@RestController
public class AccountBalance{
    
    @Autowired
    private Environment env;

    @Autowired
	private BalanceRepository repository;
    
    @RequestMapping(method = RequestMethod.GET, value = "/balance/{accountid}")
    @ResponseBody
    public Balance get(
        @PathVariable("accountid") String accountId) {
    	Balance result = repository.findByAccountId(accountId);
    	return result;
    }
    
    @RequestMapping(method = RequestMethod.GET, value = "/balance/all")
    @ResponseBody
    public List<Balance> get() {
        List<Balance> result = repository.findAll();
        //System.out.println("result = " + result);
    	return result;
    }

    @RequestMapping(method = RequestMethod.POST, value = "/balance")
    @ResponseBody
    public Balance createBalance(@RequestBody Balance balance) {
        repository.insert(balance);
        return balance;
    }

    @RequestMapping(method = RequestMethod.PUT, value = "/balance")
    @ResponseBody
    public Balance updateBalance(@RequestBody Balance balance) {
        repository.save(balance);
        return balance;
    }

}
