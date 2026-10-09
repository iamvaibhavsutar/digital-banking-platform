package com.bankdemo.transfer.service;

import com.bankdemo.transfer.dto.*;
import com.bankdemo.transfer.entity.Transaction;
import com.bankdemo.transfer.exception.AccountNotFoundException;
import com.bankdemo.transfer.repository.AccountRepository;
import com.bankdemo.transfer.repository.TransactionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TransferService {
    private final AccountRepository accounts;
    private final TransactionRepository txns;

    public TransferService(AccountRepository a, TransactionRepository t) { accounts = a; txns = t; }

    @Transactional
    public TransferResponse transfer(String idemKey, TransferRequest req) {

        // 1. Idempotency: same key seen before? Return the old result, do NOT move money again.
        var existing = txns.findByIdempotencyKey(idemKey);
        if (existing.isPresent()) return TransferResponse.from(existing.get());

        if (req.fromAccount().equals(req.toAccount()))
            throw new IllegalArgumentException("Cannot transfer to the same account");

        // 2. Lock rows in a FIXED order (alphabetical) so A->B and B->A can never deadlock.
        String first  = req.fromAccount().compareTo(req.toAccount()) < 0 ? req.fromAccount() : req.toAccount();
        String second = first.equals(req.fromAccount()) ? req.toAccount() : req.fromAccount();
        var a1 = accounts.findByAccountNumberForUpdate(first).orElseThrow(() -> new AccountNotFoundException(first));
        var a2 = accounts.findByAccountNumberForUpdate(second).orElseThrow(() -> new AccountNotFoundException(second));

        var from = a1.getAccountNumber().equals(req.fromAccount()) ? a1 : a2;
        var to   = (from == a1) ? a2 : a1;

        // 3. Move the money. Both updates commit together or neither does.
        from.debit(req.amount());
        to.credit(req.amount());

        // 4. Audit record (the UNIQUE key is the last safety net)
        var saved = txns.save(new Transaction(idemKey, req.fromAccount(), req.toAccount(),
                                              req.amount(), "COMPLETED"));
        return TransferResponse.from(saved);
    }

    /** Used by the controller after losing a race on the UNIQUE idempotency key. */
    @Transactional(readOnly = true)
    public TransferResponse findByKey(String idemKey) {
        return txns.findByIdempotencyKey(idemKey).map(TransferResponse::from).orElseThrow();
    }
}
