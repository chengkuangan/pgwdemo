package com.gck.demo.paymentgateway.customer.processors;


import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.apache.camel.component.cxf.common.message.CxfConstants;
import org.eclipse.jetty.http.HttpStatus;

import com.gck.demo.paymentgateway.customer.model.AccountProfile;
import com.gck.demo.paymentgateway.customer.model.Balance;
import com.gck.demo.paymentgateway.customer.model.Customer;
import com.gck.demo.paymentgateway.customer.model.CustomerError;

public class ErrorProcessor implements Processor {

	@Override
	public void process(Exchange exchange) throws Exception {

		Exception exception = (Exception) exchange.getProperty(Exchange.EXCEPTION_CAUGHT);
		
		
		CustomerError error = new CustomerError();
		error.setMessage(exception.getMessage());
		error.setDetail((String) exchange.getIn().getHeader("errorDetail"));
		error.setStatus("Error");
		
		exchange.getOut().setHeader(Exchange.HTTP_RESPONSE_CODE, 500);
		exchange.getOut().setBody(error);
		

	}

}
