package com.gck.demo.paymentgateway.reconcile.kafka;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import com.gck.demo.paymentgateway.reconcile.models.Credit;
import com.gck.demo.paymentgateway.reconcile.models.CreditResponse;
import com.gck.demo.paymentgateway.reconcile.connect.WebService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gck.demo.paymentgateway.reconcile.models.Balance;
import java.io.IOException;
import java.util.Date;

import com.fasterxml.jackson.core.JsonProcessingException;

@Component
public class CreditReceiver {
    @Value("${accountbalance.get.url}")
    String accBalanceGetURL;
    @Value("${accountbalance.post.url}")
    String accBalancePostURL;
    @Value("${credit.response.topic}")
    String creditResponseTopic;
    @Autowired
    KafkaSender kafkaSender;

    @KafkaListener(topics = "${credit.consumer.topic}")
    public void listenCredit(ConsumerRecord<?, ?> consumerRecord) {

        System.out.println("Receiver on credit: " + consumerRecord.toString());

        
        String value = consumerRecord.value().toString();
        // System.out.println(">>> 1. value = " + value);
        ObjectMapper mapper = new ObjectMapper();
        try {
            Credit credit = mapper.readValue(value, Credit.class);
            // System.out.println(">>> 1. credit = " + credit.getAmount());
            WebService ws = new WebService();
            String resp = ws.get(accBalanceGetURL + "/" + credit.getTargetAccount());
            // System.out.println(">>> 2. resp = " + resp);
            Balance targetAccount = mapper.readValue(resp,
                    Balance.class);
            resp = ws.get(accBalanceGetURL + "/" + credit.getSourceAccount());
            // System.out.println(">>> 3. resp = " + resp);
            Balance sourceAccount = mapper.readValue(resp,
                    Balance.class);
            double amt = credit.getAmount();
            Date transactionDate = new Date();
            long timestamp = transactionDate.getTime();
            targetAccount.setBalance(targetAccount.getBalance() + amt);
            targetAccount.setLastUpdatedDate(timestamp);
            sourceAccount.setBalance(sourceAccount.getBalance() - amt);
            sourceAccount.setLastUpdatedDate(timestamp);
            String targetAccountStr = mapper.writeValueAsString(targetAccount);
            String sourceAccountStr = mapper.writeValueAsString(sourceAccount);
            // System.out.println("---> accBalancePostURL = " + accBalancePostURL);
            // System.out.println("---> targetAccountStr = " + targetAccountStr);
            ws.put(accBalancePostURL, targetAccountStr);
            // System.out.println("---> sourceAccountStr = " + sourceAccountStr);
            ws.put(accBalancePostURL, sourceAccountStr);

            CreditResponse cResp = new CreditResponse();
            cResp.setCreditRecordId(credit.get_id());
            cResp.setSourceAccountRecordId(sourceAccount.get_id());
            cResp.setSourceAccountId(sourceAccount.getAccountId());
            cResp.setTargetAccountRecordId(targetAccount.get_id());
            cResp.setTargetAccountId(targetAccount.getAccountId());
            cResp.setCreditAmount(credit.getAmount());
            cResp.setTargetAccountBalance(targetAccount.getBalance());
            cResp.setSourceAccountBalance(sourceAccount.getBalance());
            cResp.setTransactionDate(transactionDate);
            
            String cRespStr = mapper.writeValueAsString(cResp);
            kafkaSender.send(creditResponseTopic, cRespStr);

        } catch (JsonProcessingException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

}
