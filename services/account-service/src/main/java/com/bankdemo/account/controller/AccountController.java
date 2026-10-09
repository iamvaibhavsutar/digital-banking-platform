package com.bankdemo.account.controller;

import com.bankdemo.account.dto.*;
import com.bankdemo.account.service.AccountService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/accounts")
public class AccountController {
    private final AccountService service;
    public AccountController(AccountService service) { this.service = service; }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public AccountResponse create(@Valid @RequestBody CreateAccountRequest req) {
        return service.create(req);
    }

    @GetMapping("/{accountNumber}")
    public AccountResponse get(@PathVariable String accountNumber) {
        return service.get(accountNumber);
    }
}
