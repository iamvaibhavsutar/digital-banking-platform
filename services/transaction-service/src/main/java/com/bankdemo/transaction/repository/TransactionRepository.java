package com.bankdemo.transaction.repository;

import com.bankdemo.transaction.entity.Transaction;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.*;
import java.util.List;

public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    @Query("select t from Transaction t where t.fromAccount = :a or t.toAccount = :a order by t.createdAt desc")
    List<Transaction> findForAccount(String a, Pageable page);
}
