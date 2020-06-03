package com.gck.demo.paymentgateway.accountbalance.rest;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

/**
 * Healthz endpoint for liveness and readiness of the application
 *
 * Created by ganck.
 */
@RestController
@RequestMapping("/ws/healthz")
public class Healthz {

    @RequestMapping(method = RequestMethod.GET, value = "/")
    public String healthz() {
        return "OK";
    }
}
