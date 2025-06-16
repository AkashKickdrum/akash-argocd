package com.example.demo.service;

import com.example.demo.model.ExchangeRate;
import com.example.demo.repository.ExchangeRateRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Objects;

@Service
public class ExchangeRateService {

    @Autowired
    private ExchangeRateRepository exchangeRateRepository;

    @Autowired
    private ITotalExchangeCount iTotalExchangeCount;

    public ExchangeRate addExchangeRate(ExchangeRate exchangeRate) {
        return exchangeRateRepository.save(exchangeRate);
    }

    public double getAmount(String sourceCurrency, String targetCurrency) {
        List<ExchangeRate> exchangeRate =  exchangeRateRepository.findBySourceCurrencyAndTargetCurrency(sourceCurrency, targetCurrency);
        if (exchangeRate.isEmpty()) {
            // Handle the case where no matching exchange rate is found
            return 0;
        } else if (exchangeRate.size() > 1) {
            // Handle the case where multiple matching exchange rates are found
            return exchangeRate.get(0).getAmount();
        }
        return exchangeRate.get(0).getAmount();
    }

    public long getTotalExchangeRates(){
        return iTotalExchangeCount.getTotalExchangeRates();
    }

}
