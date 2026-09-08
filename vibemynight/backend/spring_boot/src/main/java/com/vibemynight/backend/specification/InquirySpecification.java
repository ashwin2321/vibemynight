package com.vibemynight.backend.specification;

import com.vibemynight.backend.entity.Inquiry;
import com.vibemynight.backend.entity.InquiryStatus;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * Admin inquiries screen filters: status / event / date / artist / pass,
 * plus a free-text search across inquiry number, customer name, mobile and event name.
 */
public class InquirySpecification {

    public static Specification<Inquiry> filter(
            String search,
            InquiryStatus status,
            Long eventId,
            Long artistId,
            Long ticketCategoryId,
            LocalDate date
    ) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (search != null && !search.isBlank()) {
                String like = "%" + search.toLowerCase() + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(root.get("inquiryNumber")), like),
                        cb.like(cb.lower(root.get("customerName")), like),
                        cb.like(cb.lower(root.get("customerMobile")), like),
                        cb.like(cb.lower(root.get("event").get("name")), like)
                ));
            }
            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }
            if (eventId != null) {
                predicates.add(cb.equal(root.get("event").get("id"), eventId));
            }
            if (artistId != null) {
                predicates.add(cb.equal(root.get("artist").get("id"), artistId));
            }
            if (ticketCategoryId != null) {
                predicates.add(cb.equal(root.get("ticketCategory").get("id"), ticketCategoryId));
            }
            if (date != null) {
                predicates.add(cb.equal(root.get("eventDay").get("date"), date));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
