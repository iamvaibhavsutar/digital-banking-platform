package com.bankdemo.transaction.service;

import com.bankdemo.transaction.dto.TransactionResponse;
import com.bankdemo.transaction.repository.TransactionRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
public class TransactionQueryService {
    private final TransactionRepository repo;
    public TransactionQueryService(TransactionRepository repo) { this.repo = repo; }

    @Transactional(readOnly = true)
    public List<TransactionResponse> history(String account, int limit) {
        int n = Math.max(1, Math.min(limit, 100));
        return repo.findForAccount(account, PageRequest.of(0, n)).stream()
                   .map(t -> TransactionResponse.from(t, account)).toList();
    }
}
