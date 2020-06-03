package com.gck.demo.paymentgateway.accountbalance.db;

import java.util.List;
import com.gck.demo.paymentgateway.accountbalance.db.*;
import com.gck.demo.paymentgateway.accountbalance.models.*;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface BalanceRepository extends MongoRepository<Balance, String> {
	Balance findByAccountId(String accountId);
	//List<Balance> findAll();
}