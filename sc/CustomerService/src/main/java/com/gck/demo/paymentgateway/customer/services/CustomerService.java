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


@Path("/ws/pg")
public class CustomerService {
	
	public CustomerService(){}
	
	@POST
	@Path("/customer")
	@Consumes(MediaType.APPLICATION_JSON)
	@Produces (MediaType.APPLICATION_JSON)
	public String create(@Body String data){
		return "{\"status\":\"OK\"}";
	}
	
	@GET
	@Path("/customer/{cust_id}")
	@Consumes(MediaType.APPLICATION_JSON)
	@Produces (MediaType.APPLICATION_JSON)
	public String get(@PathParam("cust_id") String custId){
		return "{\"status\":\"OK\"}";
	}
	
	@GET
	@Path("/customer")
	@Consumes(MediaType.APPLICATION_JSON)
	@Produces (MediaType.APPLICATION_JSON)
	public String getAll(){
		return "{\"status\":\"OK\"}";
	}
	
	@PUT
	@Path("/customer/{cust_id}")
	@Consumes(MediaType.APPLICATION_JSON)
	@Produces (MediaType.APPLICATION_JSON)
	public String update(@Body String data, @PathParam("cust_id") String custId ){
		return "{\"status\":\"OK\"}";
	}
	
	@DELETE
	@Path("/customer/{cust_id}")
	@Consumes(MediaType.APPLICATION_JSON)
	@Produces (MediaType.APPLICATION_JSON)
	public String delete(@Body String data, @PathParam("cust_id") String custId ){
		return "{\"status\":\"OK\"}";
	}

}
