package com.bankdemo.transaction.controller;

import com.bankdemo.transaction.dto.TransactionResponse;
import com.bankdemo.transaction.service.TransactionQueryService;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/transactions")
public class TransactionController {
    private final TransactionQueryService service;
    public TransactionController(TransactionQueryService service) { this.service = service; }

    @GetMapping("/{accountNumber}")
    public List<TransactionResponse> history(@PathVariable String accountNumber,
                                             @RequestParam(defaultValue = "20") int limit) {
        return service.history(accountNumber, limit);
    }
}
