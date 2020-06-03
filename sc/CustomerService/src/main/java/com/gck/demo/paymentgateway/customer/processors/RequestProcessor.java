package com.gck.demo.paymentgateway.customer.processors;

import java.util.StringTokenizer;

import org.apache.camel.Exchange;
import org.apache.camel.ExchangePattern;
import org.apache.camel.Message;
import org.apache.camel.Processor;
import org.apache.camel.component.cxf.common.message.CxfConstants;
import org.apache.cxf.message.MessageContentsList;

public class RequestProcessor implements Processor {
	
	@Override
    public void process(Exchange exchange) throws Exception {
            exchange.setPattern(ExchangePattern.InOut);
            Message inMessage = exchange.getIn();
            //String operationName = inMessage.getHeader("operationName", String.class);
            // set the operation name
            //inMessage.setHeader(CxfConstants.OPERATION_NAME, "getCustomerProfile");
            // using the proxy client API
            inMessage.setHeader(CxfConstants.CAMEL_CXF_RS_USING_HTTP_API, Boolean.FALSE);
            inMessage.setHeader(Exchange.CONTENT_ENCODING, "application/json");
             
            //creating the request
            String pathParam = inMessage.getBody(String.class);
            
            System.out.println("Body -> params: " + pathParam);
            
            StringTokenizer tokens = new StringTokenizer(pathParam, ",");
            
            MessageContentsList req = new MessageContentsList();
            while (tokens.hasMoreTokens()) {
            	req.add((String) tokens.nextToken());
            }
            
            inMessage.setBody(req);
            
 
        }

}
