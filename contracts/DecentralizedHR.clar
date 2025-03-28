
;; DecentralizedHR - Employee Verification Platform
;; Core features: Work history, skills, references, and company subscriptions

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-already-exists (err u101))
(define-constant err-not-found (err u102))
(define-constant err-invalid-status (err u103))

;; Data Maps
(define-map Employees 
    principal 
    {
        name: (string-ascii 50),
        current-status: (string-ascii 20),
        skills: (list 10 (string-ascii 30)),
        verified: bool
    }
)

(define-map WorkHistory
    {employee: principal, company: principal}
    {
        position: (string-ascii 50),
        start-date: uint,
        end-date: uint,
        verified: bool
    }
)

(define-map Companies
    principal
    {
        name: (string-ascii 50),
        subscription-status: bool,
        verification-count: uint
    }
)

(define-map References
    {employee: principal, referee: principal}
    {
        relationship: (string-ascii 30),
        rating: uint,
        comment: (string-ascii 200)
    }
)

;; Public functions

;; Employee Registration
(define-public (register-employee (name (string-ascii 50)) (skills (list 10 (string-ascii 30))))
    (let ((employee tx-sender))
        (if (is-none (map-get? Employees employee))
            (ok (map-set Employees 
                employee 
                {
                    name: name,
                    current-status: "active",
                    skills: skills,
                    verified: false
                }))
            err-already-exists
        )
    )
)

;; Company Registration
(define-public (register-company (name (string-ascii 50)))
    (let ((company tx-sender))
        (if (is-none (map-get? Companies company))
            (ok (map-set Companies 
                company 
                {
                    name: name,
                    subscription-status: false,
                    verification-count: u0
                }))
            err-already-exists
        )
    )
)

;; Add Work History
(define-public (add-work-history 
    (company principal) 
    (position (string-ascii 50))
    (start-date uint)
    (end-date uint))
    (let ((employee tx-sender))
        (ok (map-set WorkHistory
            {employee: employee, company: company}
            {
                position: position,
                start-date: start-date,
                end-date: end-date,
                verified: false
            }))
    )
)

;; Verify Work History
(define-public (verify-work-history (employee principal))
    (let (
        (company tx-sender)
        (history-entry (map-get? WorkHistory {employee: employee, company: company}))
        (company-data (map-get? Companies company))
    )
        (asserts! (is-some company-data) err-not-found)
        (asserts! (is-some history-entry) err-not-found)
        (asserts! (get subscription-status (unwrap-panic company-data)) err-not-authorized)
        
        (ok (map-set WorkHistory
            {employee: employee, company: company}
            (merge (unwrap-panic history-entry) {verified: true})))
    )
)

;; Add Reference
(define-public (add-reference 
    (employee principal)
    (relationship (string-ascii 30))
    (rating uint)
    (comment (string-ascii 200)))
    (let ((referee tx-sender))
        (asserts! (<= rating u5) err-invalid-status)
        (ok (map-set References
            {employee: employee, referee: referee}
            {
                relationship: relationship,
                rating: rating,
                comment: comment
            }))
    )
)

;; Subscribe Company
(define-public (subscribe-company)
    (let (
        (company tx-sender)
        (company-data (map-get? Companies company))
    )
        (asserts! (is-some company-data) err-not-found)
        (ok (map-set Companies
            company
            (merge (unwrap-panic company-data) {subscription-status: true})))
    )
)

;; Read-only functions

(define-read-only (get-employee-details (employee principal))
    (map-get? Employees employee)
)

(define-read-only (get-work-history (employee principal) (company principal))
    (map-get? WorkHistory {employee: employee, company: company})
)

(define-read-only (get-company-details (company principal))
    (map-get? Companies company)
)

(define-read-only (get-references (employee principal) (referee principal))
    (map-get? References {employee: employee, referee: referee})
)
