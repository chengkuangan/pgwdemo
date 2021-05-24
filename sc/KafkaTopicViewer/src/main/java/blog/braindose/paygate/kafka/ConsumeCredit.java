package blog.braindose.paygate.kafka;

import io.smallrye.reactive.messaging.annotations.Broadcast;
import org.eclipse.microprofile.reactive.messaging.Acknowledgment;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.eclipse.microprofile.reactive.messaging.Outgoing;
import org.eclipse.microprofile.reactive.messaging.Message;
import io.smallrye.reactive.messaging.kafka.IncomingKafkaRecordMetadata;
import java.time.Instant;
import java.util.Optional;
import javax.enterprise.context.ApplicationScoped;
import javax.enterprise.context.RequestScoped;
import java.util.concurrent.CompletionStage;
import java.util.Calendar;
import java.util.TimeZone;
import java.time.format.FormatStyle;

import com.fasterxml.jackson.core.*;
import com.fasterxml.jackson.databind.*;

import java.util.Date;
import java.time.format.DateTimeFormatter;

@ApplicationScoped
public class ConsumeCredit {

    @Incoming("credit-in")                                     
    @Outgoing("credit-data-stream")                             
    @Broadcast                                              
    @Acknowledgment(Acknowledgment.Strategy.PRE_PROCESSING) 
    public String consume(Message<String> credit) {

        String payload = credit.getPayload();
        System.out.println("payload = " + payload);
        ObjectMapper mapper = new ObjectMapper();
        String processed = "";
        String[] timeString = new String[]{""};       

            Optional<IncomingKafkaRecordMetadata> metadata = credit.getMetadata(IncomingKafkaRecordMetadata.class);
            metadata.ifPresent(meta -> {
                Instant timestamp = meta.getTimestamp();
                TimeZone timeZone = Calendar.getInstance().getTimeZone();
                DateTimeFormatter formatter = DateTimeFormatter.ofLocalizedDateTime( FormatStyle.LONG ).withZone( timeZone.toZoneId() );
                timeString[0] = formatter.format(timestamp);
            });
            
            credit.ack();
            processed = payload.substring(0, payload.length() - 1) + ",\"timestamp\": \"" + timeString[0] + "\"}";
        return  processed;
    }

}