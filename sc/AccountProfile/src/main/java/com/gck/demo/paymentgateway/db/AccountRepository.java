package com.gck.demo.paymentgateway.db;

import java.util.List;
import com.gck.demo.paymentgateway.db.*;
import com.gck.demo.paymentgateway.models.*;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface AccountRepository extends MongoRepository<Account, String> {
	Account findByAccountId(String accountId);
}