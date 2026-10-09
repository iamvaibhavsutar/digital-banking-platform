package com.bankdemo.account.repository;

import com.bankdemo.account.entity.Account;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import java.util.Optional;

public interface AccountRepository extends JpaRepository<Account, Long> {
    Optional<Account> findByAccountNumber(String accountNumber);

    // SELECT ... FOR UPDATE: locks the row until the transaction ends
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from Account a where a.accountNumber = :n")
    Optional<Account> findByAccountNumberForUpdate(String n);
}
