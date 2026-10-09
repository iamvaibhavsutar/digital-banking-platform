package com.bankdemo.account.service;

import com.bankdemo.account.dto.*;
import com.bankdemo.account.entity.Account;
import com.bankdemo.account.exception.AccountNotFoundException;
import com.bankdemo.account.repository.AccountRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.concurrent.ThreadLocalRandom;

@Service
public class AccountService {
    private final AccountRepository repo;
    public AccountService(AccountRepository repo) { this.repo = repo; }

    @Transactional
    public AccountResponse create(CreateAccountRequest req) {
        String number = "ACC" + (2000 + ThreadLocalRandom.current().nextInt(7999));
        Account saved = repo.save(new Account(number, req.holderName(), req.openingBalance()));
        return AccountResponse.from(saved);
    }

    @Transactional(readOnly = true)
    public AccountResponse get(String accountNumber) {
        return repo.findByAccountNumber(accountNumber)
                   .map(AccountResponse::from)
                   .orElseThrow(() -> new AccountNotFoundException(accountNumber));
    }
}
