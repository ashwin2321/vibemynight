package com.vibemynight.backend.repository;

import com.vibemynight.backend.entity.Inquiry;
import com.vibemynight.backend.entity.InquiryStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface InquiryRepository extends JpaRepository<Inquiry, Long>, JpaSpecificationExecutor<Inquiry> {
    Optional<Inquiry> findByInquiryNumber(String inquiryNumber);
    List<Inquiry> findByStatus(InquiryStatus status);
    long countByStatus(InquiryStatus status);

    @Query("select count(i) from Inquiry i")
    long countAllInquiries();
}
