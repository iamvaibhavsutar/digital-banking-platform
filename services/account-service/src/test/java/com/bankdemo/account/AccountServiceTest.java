package com.bankdemo.account;

import com.bankdemo.account.entity.Account;
import com.bankdemo.account.exception.AccountNotFoundException;
import com.bankdemo.account.repository.AccountRepository;
import com.bankdemo.account.service.AccountService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import java.math.BigDecimal;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AccountServiceTest {
    @Mock AccountRepository repo;
    @InjectMocks AccountService service;

    @Test
    void returnsAccountWhenFound() {
        when(repo.findByAccountNumber("ACC1001"))
            .thenReturn(Optional.of(new Account("ACC1001", "Asha", new BigDecimal("500.00"))));
        assertEquals("Asha", service.get("ACC1001").holderName());
    }

    @Test
    void throwsWhenMissing() {
        when(repo.findByAccountNumber("X")).thenReturn(Optional.empty());
        assertThrows(AccountNotFoundException.class, () -> service.get("X"));
    }

    @Test
    void debitBeyondBalanceFails() {
        Account a = new Account("A", "n", new BigDecimal("10"));
        assertThrows(IllegalStateException.class, () -> a.debit(new BigDecimal("11")));
    }
}
