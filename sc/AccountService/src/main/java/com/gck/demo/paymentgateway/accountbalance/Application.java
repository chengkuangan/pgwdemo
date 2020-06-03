package com.gck.demo.paymentgateway.accountbalance;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

/**
 * Main application launcher
 *
 * Created by ganck.
 */
@SpringBootApplication
// @ComponentScan(basePackages = "com.gck")
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

}
