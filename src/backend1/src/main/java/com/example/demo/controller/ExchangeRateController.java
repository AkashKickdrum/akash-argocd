package com.example.demo.controller;

import com.example.demo.model.ExchangeRate;
import com.example.demo.service.ExchangeRateService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

@RestController
@CrossOrigin(origins = "*")
public class ExchangeRateController {

    @Autowired
    ExchangeRateService exchangeRateService;

    @GetMapping("/getAmount")
    public double getAmount(@RequestParam String sourceCurrency, @RequestParam String targetCurrency) {
        return exchangeRateService.getAmount(sourceCurrency, targetCurrency);
    }

    @GetMapping("/getTotalCount")
    public double getTotalExchangeRates() {
        return exchangeRateService.getTotalExchangeRates();
    }

    @PostMapping("/addExchangeRate")
    public ExchangeRate addExchangeRate(@RequestBody ExchangeRate exchangeRate) {
        return exchangeRateService.addExchangeRate(exchangeRate);
    }

    @GetMapping("/")
    public String getHealth() {
        return "up";
    }

}
