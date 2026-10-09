package com.bankdemo.transfer.exception;

public class AccountNotFoundException extends RuntimeException {
    public AccountNotFoundException(String n) { super("Account not found: " + n); }
}
