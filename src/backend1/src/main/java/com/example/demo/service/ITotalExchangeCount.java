package com.example.demo.service;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;

@FeignClient(name = "${feign.client.name}", url = "${feign.client.url}")
public interface ITotalExchangeCount {

    @GetMapping("/getTotalCount")
    public long getTotalExchangeRates();
}
