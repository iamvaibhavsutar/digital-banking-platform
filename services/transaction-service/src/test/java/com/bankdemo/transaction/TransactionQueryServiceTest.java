package com.bankdemo.transaction;

import com.bankdemo.transaction.entity.Transaction;
import com.bankdemo.transaction.repository.TransactionRepository;
import com.bankdemo.transaction.service.TransactionQueryService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Pageable;
import java.math.BigDecimal;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TransactionQueryServiceTest {
    @Mock TransactionRepository repo;
    @InjectMocks TransactionQueryService service;

    @Test
    void marksDebitAndCreditFromViewerPerspective() {
        when(repo.findForAccount(eq("ACC1001"), any(Pageable.class))).thenReturn(List.of(
            new Transaction(1L, "ACC1001", "ACC1002", new BigDecimal("10.00"), "COMPLETED"),
            new Transaction(2L, "ACC1003", "ACC1001", new BigDecimal("5.00"), "COMPLETED")));
        var out = service.history("ACC1001", 20);
        assertEquals("DEBIT", out.get(0).direction());
        assertEquals("CREDIT", out.get(1).direction());
    }
}
