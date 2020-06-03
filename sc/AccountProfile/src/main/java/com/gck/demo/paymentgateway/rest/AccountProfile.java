package com.gck.demo.paymentgateway.rest;

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

import com.gck.demo.paymentgateway.db.*;
import com.gck.demo.paymentgateway.models.*;

/**
 * Provides information about this service
 *
 * Created by ganck.
 */
@RequestMapping("/ws/pg")
@RestController
public class AccountProfile{
    
    @Autowired
    private Environment env;

    @Autowired
	private AccountRepository repository;
    
    @RequestMapping(method = RequestMethod.GET, value = "/account/{accountid}")
    @ResponseBody
    public Account get(
        @PathVariable("accountid") String accountId) {
    	Account result = repository.findByAccountId(accountId);
    	return result;
    }
    
    @RequestMapping(method = RequestMethod.GET, value = "/account/all")
    @ResponseBody
    public List<Account> get() {
        List<Account> result = repository.findAll();
    	return result;
    }

    @RequestMapping(method = RequestMethod.POST, value = "/account")
    @ResponseBody
    public Account createAccount(@RequestBody Account account) {
        Account result = repository.save(account);
    	return result;
    }

}
