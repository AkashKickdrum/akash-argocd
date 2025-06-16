package com.example.demo.controller;

import com.example.demo.service.ExchangeRateService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin(origins = "*")
public class ExchangeRateController {

    @Autowired
    ExchangeRateService exchangeRateService;

    @GetMapping("/getTotalCount")
    public long getTotalExchangeRates() {
        return exchangeRateService.getTotalExchangeRates();
    }

    @GetMapping("/")
    public String getHealth() {
        return "second service is up";
    }

}
