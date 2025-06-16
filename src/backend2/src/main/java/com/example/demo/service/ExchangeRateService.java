package com.example.demo.service;

import com.example.demo.model.ExchangeRate;
import com.example.demo.repository.ExchangeRateRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class ExchangeRateService {

    @Autowired
    private ExchangeRateRepository exchangeRateRepository;

    public long getTotalExchangeRates() {
        return exchangeRateRepository.count();
    }
}
