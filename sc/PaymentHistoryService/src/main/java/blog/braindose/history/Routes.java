package blog.braindose.history;

import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Set;

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.rest.RestBindingMode;
import org.apache.camel.component.mongodb.MongoDbConstants;
import com.mongodb.client.model.Filters;
import java.util.Date;
import java.util.List;
import java.util.ArrayList;
import org.apache.camel.component.jackson.JacksonDataFormat;
import org.apache.camel.model.dataformat.JsonLibrary;
import org.apache.camel.component.jackson.ListJacksonDataFormat;
import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.apache.camel.Message;
import org.bson.Document;
import java.util.Map;
import java.util.HashMap;
import com.fasterxml.jackson.databind.ObjectMapper;
/**
 * 
 * Sample data from creditresponse db:
 * { "_id" : ObjectId("60b5a1423a2789327939b8f9"), "sourceAccountRecordId" : "60b59b5f17a48522722e6531", "targetAccountRecordId" : "60b59b5f17a48522722e6530", 
 * "sourceAccountId" : "20191029-MY-123456789", "targetAccountId" : "20191029-MY-123456710", "sourceAccountBalance" : 249, "targetAccountBalance" : 151, 
 * "creditRecordId" : "ykx4snkpdg5k66", "creditAmount" : 1, "transactionDate" : NumberLong("1622516034024") }
 */
public class Routes extends RouteBuilder{

    private List<Payment> payments = new ArrayList<Payment>();
    private Map<String, String> accountNames = new HashMap<String, String>();
    
    public Routes(){
    }

    @Override
    public void configure() throws Exception {

        restConfiguration().bindingMode(RestBindingMode.json);
        
        rest("/payments")
                .get("/{sourceAccount}")
                .route()
                .streamCaching()
                //.setBody().simple("{\"sourceAccountId\":\"${header.sourceAccount}\"}")
                .setBody().simple("{ $or: [ { sourceAccountId: '${header.sourceAccount}' }, { targetAccountId: '${header.sourceAccount}' } ] }")
                .to("mongodb:camelMongoClient?database={{mongodb.dbname}}&collection={{mongodb.collection}}&operation=findAll")
                //.log("1. body = ${body}")
                .process(new Processor(){
                    public void process(Exchange exchange) {
                        Message in = exchange.getIn();
                        String sourceAccountId = (String) in.getHeader("sourceAccount");
                        List<Document> list = in.getBody(List.class);
                        payments.clear();
                        list.forEach((Document d) -> {
                            payments.add(
                                new Payment(
                                    d.getLong("transactionDate"), 
                                    d.getString("sourceAccountId"), 
                                    d.getString("targetAccountId"), 
                                    d.getDouble("creditAmount"), 
                                    d.getDouble("sourceAccountBalance"),
                                    (d.getString("sourceAccountId").equals(sourceAccountId) ? d.getString("targetAccountId") : d.getString("sourceAccountId")),
                                    (d.getString("sourceAccountId").equals(sourceAccountId) ? "Credit" : "Debit")
                                    )
                            );
                            accountNames.put(d.getString("sourceAccountId"), d.getString("sourceAccountId"));
                            accountNames.put(d.getString("targetAccountId"), d.getString("targetAccountId"));
                        });
                        //in.setBody(accountNames.keySet().iterator());
                        exchange.setProperty("ITERATOR", accountNames.keySet().iterator());
                        //System.out.println("param = " + Filters.eq("sourceAccountId", "20191029-MY-123456789"));
                        //System.out.println("param = " + Filters.or(Filters.eq("sourceAccountId", "20191029-MY-123456789"), Filters.eq("sourceAccountId", "20191029-MY-")));
                        System.out.println(">>>>>> 1. date = " + (new java.util.Date()).getTime());
                    }
                })
                .loopDoWhile(simple("${exchangeProperty.ITERATOR.hasNext}"))
                    .setBody(simple("${exchangeProperty.ITERATOR.next}"))
                    .to("direct:populateAccountNames")
                .end()
                .process(new Processor(){
                    public void process(Exchange exchange) {
                        Message in = exchange.getIn();
                        payments.forEach((Payment p) -> {
                            p.targetAccountName = accountNames.get(p.targetAccount);
                            p.sourceAccountName = accountNames.get(p.sourceAccount);
                            p.participateAccountName = accountNames.get(p.participateAccount);
                        });
                        in.setBody(payments);
                    }
                });
                //.log("3. response body = ${body}");
                //.endRest();
                //.end();
        
        from("direct:populateAccountNames")
            .streamCaching()
            .process(new Processor(){
                public void process(Exchange exchange) {
                    Message in = exchange.getIn();
                    String acc_Id = in.getBody(String.class);
                    exchange.setProperty("ACCOUNT_NO", acc_Id);
                    //System.out.println(">>>>>> 3. exchangeId = " + exchange.getExchangeId());
                }
            })
            .removeHeader("CamelHttpPath")
            .removeHeader("CamelHttpUri")
            .setHeader(Exchange.HTTP_PATH, simple("${exchangeProperty.ACCOUNT_NO}"))
            .log("Send GET request to {{accountprofile.get.endpoint}}/${exchangeProperty.ACCOUNT_NO}")
            .to("{{accountprofile.get.endpoint}}")
            //.log("body = ${body}")
            .unmarshal().json(JsonLibrary.Jackson, AccountProfile.class)
            .process(new Processor(){
                public void process(Exchange exchange) {
                    Message in = exchange.getIn();
                    AccountProfile acc = in.getBody(AccountProfile.class);
                    accountNames.put(acc.accountId, acc.name);
                }
            });

        /*
        from("direct:printHeaders")
            .process(new Processor(){
                public void process(Exchange exchange) {
                    Message in = exchange.getIn();
                    System.out.println("=======================================");
                    System.out.println("HTTP Headers");
                    System.out.println("=======================================");
                    in.getHeaders().forEach((k, v) -> {
                        System.out.printf("%s = %s%n", k, v);
                    });
                    System.out.println("=======================================");
                }
            });

        from("direct:restoreHeaders")
            .process(new Processor(){
                public void process(Exchange exchange) {
                    Message in = exchange.getIn();
                    headers.forEach((k, v) -> {
                        in.setHeader(k, v);
                    });
                }
            });
        */
        //DocumentList body : [Document{{_id=60b0b115b0c350a025b44fb1, id=00001, date=2021-05-21 10:15:03 PM, sourceAccount=20191029-MY-123456789, targetAccount=20191029-MY-123456710, amount=12.56}}, Document{{_id=60b0b17db0c350a025b44fb2, id=00002, date=2020-05-21 10:15:03 PM, sourceAccount=20191029-MY-123456789, targetAccount=20191029-MY-123456710, amount=25.52}}, Document{{_id=60b0b184b0c350a025b44fb3, id=00003, date=2021-04-18 10:15:03 PM, sourceAccount=20191029-MY-123456789, targetAccount=20191029-MY-123456710, amount=19.5}}]
        /*
        from("direct:accountdetail")
            .process(new Processor(){
                public void process(Exchange exchange) {
                    Message in = exchange.getIn();
                    Document doc = in.getBody(Document.class);
                    Payment payment = new Payment(doc.getString("id"), doc.getString("date"), doc.getString("sourceAccount"), doc.getString("targetAccount"), doc.getDouble("amount"));
                    exchange.setProperty("SOURCE_ACCOUNT", doc.getString("sourceAccount"));
                    exchange.setProperty("PAYMENT_RECORD", payment);
                    in.setBody(doc.getString("sourceAccount"));
                    //payments.put(payment.id, payment);
                    System.out.println("accountNames = " + accountNames);
                    accountNames.forEach((k, v) -> {
                        System.out.printf("%s : %s%n", k, v);
                    });
                }
            })
            .removeHeaders("CamelHttp*")
            .setHeader(Exchange.HTTP_METHOD, constant("GET"))
            //.setHeader(Exchange.CONTENT_TYPE, constant("application/json"))
            .setHeader("Accept",constant("application/json"))
            .setHeader(Exchange.HTTP_PATH, simple("${exchangeProperty.SOURCE_ACCOUNT}"))
            //.log("SOURCE_ACCOUNT = ${exchangeProperty.SOURCE_ACCOUNT}")
            .log("PAYMENT_RECORD = ${exchangeProperty.PAYMENT_RECORD}")
            .log("Send GET request to {{accountprofile.get.endpoint}}/${exchangeProperty.SOURCE_ACCOUNT}")
            //.streamCaching(true)
            .to("{{accountprofile.get.endpoint}}")
            .unmarshal().json(JsonLibrary.Jackson, AccountProfile.class)
            .log("body = ${body}")
            //.marshal(apdf)
            .process(new Processor(){
                public void process(Exchange exchange) {
                    Message in = exchange.getIn();
                    AccountProfile acc = in.getBody(AccountProfile.class);
                    System.out.println("acc = " + acc);
                    Payment payment = (Payment) exchange.getProperty("PAYMENT_RECORD");
                    payment.sourceAccountName = acc.name;
                    exchange.getOut().setBody(payment);
                }
            })
            .log("body = ${body}")
            .end();
            */
    }

    
}