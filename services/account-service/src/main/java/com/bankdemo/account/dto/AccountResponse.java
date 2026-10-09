package com.bankdemo.account.dto;

import com.bankdemo.account.entity.Account;
import java.math.BigDecimal;

public record AccountResponse(String accountNumber, String holderName,
                              BigDecimal balance, String currency, String status) {
    public static AccountResponse from(Account a) {
        return new AccountResponse(a.getAccountNumber(), a.getHolderName(),
                                   a.getBalance(), a.getCurrency(), a.getStatus());
    }
}
