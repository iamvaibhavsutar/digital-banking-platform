package com.bankdemo.transfer;

import com.bankdemo.transfer.dto.TransferRequest;
import com.bankdemo.transfer.entity.Account;
import com.bankdemo.transfer.entity.Transaction;
import com.bankdemo.transfer.repository.AccountRepository;
import com.bankdemo.transfer.repository.TransactionRepository;
import com.bankdemo.transfer.service.TransferService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import java.math.BigDecimal;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TransferServiceTest {
    @Mock AccountRepository accounts;
    @Mock TransactionRepository txns;
    @InjectMocks TransferService service;

    @Test
    void movesMoneyAndRecordsTransaction() {
        var a = new Account("ACC1001", "A", new BigDecimal("100.00"));
        var b = new Account("ACC1002", "B", new BigDecimal("10.00"));
        when(txns.findByIdempotencyKey("k1")).thenReturn(Optional.empty());
        when(accounts.findByAccountNumberForUpdate("ACC1001")).thenReturn(Optional.of(a));
        when(accounts.findByAccountNumberForUpdate("ACC1002")).thenReturn(Optional.of(b));
        when(txns.save(any(Transaction.class))).thenAnswer(i -> i.getArgument(0));

        var r = service.transfer("k1", new TransferRequest("ACC1001", "ACC1002", new BigDecimal("40.00")));

        assertEquals("COMPLETED", r.status());
        assertEquals(new BigDecimal("60.00"), a.getBalance());
        assertEquals(new BigDecimal("50.00"), b.getBalance());
    }

    @Test
    void sameKeyReturnsOldResultWithoutMovingMoney() {
        var old = new Transaction("k1", "ACC1001", "ACC1002", new BigDecimal("40.00"), "COMPLETED");
        when(txns.findByIdempotencyKey("k1")).thenReturn(Optional.of(old));

        var r = service.transfer("k1", new TransferRequest("ACC1001", "ACC1002", new BigDecimal("40.00")));

        assertEquals("COMPLETED", r.status());
        verify(accounts, never()).findByAccountNumberForUpdate(any());
        verify(txns, never()).save(any());
    }

    @Test
    void sameAccountIsRejected() {
        when(txns.findByIdempotencyKey("k2")).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class,
            () -> service.transfer("k2", new TransferRequest("ACC1001", "ACC1001", BigDecimal.TEN)));
    }

    @Test
    void insufficientFundsIsRejected() {
        var a = new Account("ACC1001", "A", new BigDecimal("5.00"));
        var b = new Account("ACC1002", "B", new BigDecimal("0.00"));
        when(txns.findByIdempotencyKey("k3")).thenReturn(Optional.empty());
        when(accounts.findByAccountNumberForUpdate("ACC1001")).thenReturn(Optional.of(a));
        when(accounts.findByAccountNumberForUpdate("ACC1002")).thenReturn(Optional.of(b));
        assertThrows(IllegalStateException.class,
            () -> service.transfer("k3", new TransferRequest("ACC1001", "ACC1002", BigDecimal.TEN)));
        verify(txns, never()).save(any());
    }
}
