
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



(define-constant err-self-endorsement (err u104))
(define-constant err-invalid-skill (err u105))

(define-map SkillEndorsements 
    {employee: principal, skill: (string-ascii 30)}
    {endorsement-count: uint, endorsers: (list 20 principal)}
)

(define-public (endorse-skill (employee principal) (skill (string-ascii 30)))
    (let (
        (endorser tx-sender)
        (employee-data (map-get? Employees employee))
        (current-endorsement (default-to 
            {endorsement-count: u0, endorsers: (list)}
            (map-get? SkillEndorsements {employee: employee, skill: skill})))
    )
        (asserts! (is-some employee-data) err-not-found)
        (asserts! (not (is-eq endorser employee)) err-self-endorsement)
        (ok (map-set SkillEndorsements
            {employee: employee, skill: skill}
            {
                endorsement-count: (+ (get endorsement-count current-endorsement) u1),
                endorsers: (unwrap-panic (as-max-len? (append (get endorsers current-endorsement) endorser) u20))
            }))
    )
)



(define-map Projects 
    {project-id: uint, company: principal}
    {
        name: (string-ascii 50),
        description: (string-ascii 200),
        start-date: uint,
        end-date: uint
    }
)

(define-map EmployeeProjects
    {employee: principal, project-id: uint}
    {role: (string-ascii 50), verified: bool}
)

(define-data-var project-id-nonce uint u0)

(define-public (create-project 
    (name (string-ascii 50))
    (description (string-ascii 200))
    (start-date uint)
    (end-date uint))
    (let (
        (company tx-sender)
        (new-id (+ (var-get project-id-nonce) u1))
    )
        (var-set project-id-nonce new-id)
        (ok (map-set Projects
            {project-id: new-id, company: company}
            {
                name: name,
                description: description,
                start-date: start-date,
                end-date: end-date
            }))
    )
)


(define-map Certifications
    {employee: principal, cert-id: uint}
    {
        name: (string-ascii 50),
        issuer: (string-ascii 50),
        issue-date: uint,
        expiry-date: uint,
        verified: bool
    }
)

(define-data-var cert-id-nonce uint u0)

(define-public (add-certification
    (name (string-ascii 50))
    (issuer (string-ascii 50))
    (issue-date uint)
    (expiry-date uint))
    (let (
        (employee tx-sender)
        (new-id (+ (var-get cert-id-nonce) u1))
    )
        (var-set cert-id-nonce new-id)
        (ok (map-set Certifications
            {employee: employee, cert-id: new-id}
            {
                name: name,
                issuer: issuer,
                issue-date: issue-date,
                expiry-date: expiry-date,
                verified: false
            }))
    )
)


(define-map PerformanceReviews
    {employee: principal, review-id: uint}
    {
        reviewer: principal,
        rating: uint,
        review-date: uint,
        achievements: (string-ascii 200),
        goals: (string-ascii 200)
    }
)

(define-data-var review-id-nonce uint u0)

(define-public (add-performance-review
    (employee principal)
    (rating uint)
    (achievements (string-ascii 200))
    (goals (string-ascii 200)))
    (let (
        (reviewer tx-sender)
        (new-id (+ (var-get review-id-nonce) u1))
    )
        (asserts! (<= rating u5) err-invalid-status)
        (ok (map-set PerformanceReviews
            {employee: employee, review-id: new-id}
            {
                reviewer: reviewer,
                rating: rating,
                review-date: stacks-block-height,
                achievements: achievements,
                goals: goals
            }))
    )
)

(define-map TrainingRecords
    {employee: principal, training-id: uint}
    {
        course-name: (string-ascii 50),
        provider: (string-ascii 50),
        completion-date: uint,
        score: uint,
        verified: bool
    }
)

(define-data-var training-id-nonce uint u0)

(define-public (add-training-record
    (course-name (string-ascii 50))
    (provider (string-ascii 50))
    (completion-date uint)
    (score uint))
    (let (
        (employee tx-sender)
        (new-id (+ (var-get training-id-nonce) u1))
    )
        (asserts! (<= score u100) err-invalid-status)
        (ok (map-set TrainingRecords
            {employee: employee, training-id: new-id}
            {
                course-name: course-name,
                provider: provider,
                completion-date: completion-date,
                score: score,
                verified: false
            }))
    )
)

(define-map Departments
    {company: principal, dept-name: (string-ascii 50)}
    {
        head: principal,
        employee-count: uint,
        created-at: uint
    }
)

(define-map EmployeeDepartments
    {employee: principal, company: principal}
    {department: (string-ascii 50)}
)

(define-public (create-department 
    (dept-name (string-ascii 50))
    (head principal))
    (let (
        (company tx-sender)
        (company-data (map-get? Companies company))
    )
        (asserts! (is-some company-data) err-not-found)
        (ok (map-set Departments
            {company: company, dept-name: dept-name}
            {
                head: head,
                employee-count: u1,
                created-at: stacks-block-height
            }))
    )
)

(define-public (assign-employee-to-department 
    (employee principal)
    (dept-name (string-ascii 50)))
    (let (
        (company tx-sender)
        (department-data (map-get? Departments {company: company, dept-name: dept-name}))
        (employee-data (map-get? Employees employee))
    )
        (asserts! (is-some department-data) err-not-found)
        (asserts! (is-some employee-data) err-not-found)
        (ok (map-set EmployeeDepartments
            {employee: employee, company: company}
            {department: dept-name}))
    )
)
(define-public (get-department-employees (dept-name (string-ascii 50)))
    (let ((company tx-sender))
        (ok (map-get? Departments {company: company, dept-name: dept-name}))
    )
)
(define-public (get-employee-department (employee principal))
    (let ((company tx-sender))
        (ok (map-get? EmployeeDepartments {employee: employee, company: company}))
    )
)
(define-public (get-department-head (dept-name (string-ascii 50)))
    (let ((company tx-sender))
        (ok (map-get? Departments {company: company, dept-name: dept-name}))
    )
)
(define-public (get-employee-department-history (employee principal))
    (let ((company tx-sender))
        (ok (map-get? EmployeeDepartments {employee: employee, company: company}))
    )
)
(define-public (get-employee-skill-endorsements (employee principal) (skill (string-ascii 30)))
    (let ((endorsement-data (map-get? SkillEndorsements {employee: employee, skill: skill})))
        (ok endorsement-data)
    )
)
(define-public (get-employee-certifications (employee principal))
    (let ((certification-data (map-get? Certifications {employee: employee, cert-id: u0})))
        (ok certification-data)
    )
)
(define-public (get-employee-training-records (employee principal))
    (let ((training-data (map-get? TrainingRecords {employee: employee, training-id: u0})))
        (ok training-data)
    )
)
(define-public (get-employee-performance-reviews (employee principal))
    (let ((review-data (map-get? PerformanceReviews {employee: employee, review-id: u0})))
        (ok review-data)
    )
)
(define-public (get-employee-work-history (employee principal))
    (let ((work-history-data (map-get? WorkHistory {employee: employee, company: tx-sender})))
        (ok work-history-data)
    )
)
(define-public (get-employee-references (employee principal))
    (let ((reference-data (map-get? References {employee: employee, referee: tx-sender})))
        (ok reference-data)
    )
)
(define-public (get-employee-projects (employee principal))
    (let ((project-data (map-get? EmployeeProjects {employee: employee, project-id: u0})))
        (ok project-data)
    )
)