package blog.braindose.paygate.kafka;

import io.smallrye.reactive.messaging.annotations.Channel;
import org.reactivestreams.Publisher;

import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import org.jboss.resteasy.annotations.SseElementType;
//import javax.json.bind.JsonbBuilder;

@Path("/credit")
public class CreditResource {

    @Inject
    @Channel("credit-data-stream") Publisher<String> credit; 

    @GET
    @Path("/stream")
    @Produces(MediaType.SERVER_SENT_EVENTS) 
    //@SseElementType(MediaType.APPLICATION_JSON) 
    @SseElementType(MediaType.TEXT_PLAIN) 
    public Publisher<String> stream() { 
        //return credit.map(s -> JsonbBuilder.create().fromJson(s, Credit.class)); 
        return credit;
    }
}