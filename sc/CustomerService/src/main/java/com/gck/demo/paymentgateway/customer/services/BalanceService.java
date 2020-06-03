package com.gck.demo.paymentgateway.customer.services;

import javax.ws.rs.Consumes;
import javax.ws.rs.DELETE;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.PUT;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

import org.apache.camel.Body;
import org.springframework.web.bind.annotation.PathVariable;


@Path("/ws/pg")
public interface BalanceService {
	
	@GET
	@Path("/balance/{accountid}")
	@Consumes(MediaType.APPLICATION_JSON)
	@Produces (MediaType.APPLICATION_JSON)
	public String getBalance(@PathParam("accountid") String accountId);
	

}
