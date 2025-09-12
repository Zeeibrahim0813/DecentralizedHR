;; Employee Availability & Time-Off Management System
;; A comprehensive time-off tracking system with approval workflows

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u1001))
(define-constant ERR-EMPLOYEE-NOT-FOUND (err u1002))
(define-constant ERR-INSUFFICIENT-BALANCE (err u1003))
(define-constant ERR-INVALID-DATE-RANGE (err u1004))
(define-constant ERR-REQUEST-NOT-FOUND (err u1005))
(define-constant ERR-ALREADY-PROCESSED (err u1006))
(define-constant ERR-INVALID-MANAGER (err u1007))
(define-constant ERR-POLICY-NOT-SET (err u1008))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-INVALID-STATUS (err u103))


;; Data Variables
(define-data-var next-request-id uint u1)

;; Data Maps
(define-map EmployeeTimeOffBalance
    principal
    {
        vacation-days: uint,
        sick-days: uint, 
        personal-days: uint,
        used-vacation: uint,
        used-sick: uint,
        used-personal: uint,
        manager: principal,
        company: principal,
        last-updated: uint
    }
)

(define-map TimeOffRequests
    {request-id: uint}
    {
        employee: principal,
        request-type: (string-ascii 20),
        start-date: uint,
        end-date: uint,
        days-requested: uint,
        reason: (string-ascii 200),
        status: (string-ascii 20),
        manager: principal,
        submitted-at: uint,
        reviewed-at: (optional uint),
        reviewer-notes: (optional (string-ascii 300))
    }
)

(define-map CompanyTimeOffPolicies
    principal
    {
        vacation-days-per-year: uint,
        sick-days-per-year: uint,
        personal-days-per-year: uint,
        max-consecutive-days: uint,
        min-advance-notice-hours: uint,
        carryover-limit: uint
    }
)

(define-map EmployeeAvailability
    principal
    {
        status: (string-ascii 20),
        last-updated: uint,
        emergency-contact: (optional principal),
        out-of-office-message: (optional (string-ascii 200))
    }
)

;; TODO: Implement functions for time-off management
;; e.g., request-time-off, approve-request, get-balance, etc.
;; These functions should use contract-call? to interact with the main DecentralizedHR contract
;; to verify employee and company data.
