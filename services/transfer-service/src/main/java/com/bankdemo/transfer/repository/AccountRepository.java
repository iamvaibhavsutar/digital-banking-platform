package com.bankdemo.transfer.repository;

import com.bankdemo.transfer.entity.Account;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import java.util.Optional;

public interface AccountRepository extends JpaRepository<Account, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from Account a where a.accountNumber = :n")
    Optional<Account> findByAccountNumberForUpdate(String n);
}
