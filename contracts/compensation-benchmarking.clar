;; Employee Compensation Benchmarking System
;; Provides anonymous salary comparison and market benchmarking

(define-constant err-insufficient-data-points (err u109))
(define-constant err-invalid-benchmark-data (err u110))
(define-constant err-benchmark-not-found (err u111))

(define-map CompensationBenchmarks
    {industry: (string-ascii 30), location: (string-ascii 30), position: (string-ascii 50)}
    {
        min-salary: uint,
        max-salary: uint,
        median-salary: uint,
        data-points: uint,
        last-updated: uint
    }
)

(define-map AnonymousSalarySubmissions
    {submission-id: uint}
    {
        salary-hash: (buff 32),
        industry: (string-ascii 30),
        location: (string-ascii 30),
        position: (string-ascii 50),
        years-experience: uint,
        submitted-at: uint,
        verified: bool
    }
)

;; Add Employees map definition
(define-map Employees
    principal
    {
        name: (string-ascii 50),
        position: (string-ascii 50),
        industry: (string-ascii 30),
        location: (string-ascii 30),
        years-experience: uint
    }
)

(define-map EmployeeBenchmarkAccess
    principal
    {
        submissions-count: uint,
        last-access: uint,
        access-tier: (string-ascii 10)
    }
)

;; Add Companies map definition
(define-map Companies
    principal
    {
        name: (string-ascii 50),
        subscription-status: bool
    }
)

(define-data-var benchmark-submission-nonce uint u0)

(define-public (submit-salary-benchmark
    (salary-hash (buff 32))
    (industry (string-ascii 30))
    (location (string-ascii 30))
    (position (string-ascii 50))
    (years-experience uint))
    (let (
        (employee tx-sender)
        (new-id (+ (var-get benchmark-submission-nonce) u1))
        (employee-data (map-get? Employees employee))
        (current-access (default-to 
            {submissions-count: u0, last-access: u0, access-tier: "basic"}
            (map-get? EmployeeBenchmarkAccess employee)))
    )
        (asserts! (is-some employee-data) (err u404))
        (asserts! (> years-experience u0) err-invalid-benchmark-data)
        (var-set benchmark-submission-nonce new-id)
        (map-set AnonymousSalarySubmissions
            {submission-id: new-id}
            {
                salary-hash: salary-hash,
                industry: industry,
                location: location,
                position: position,
                years-experience: years-experience,
                submitted-at: stacks-block-height,
                verified: false
            })
        (map-set EmployeeBenchmarkAccess
            employee
            (merge current-access {
                submissions-count: (+ (get submissions-count current-access) u1),
                last-access: stacks-block-height,
                access-tier: (if (>= (+ (get submissions-count current-access) u1) u3) "premium" "basic")
            }))
        (ok new-id)
    )
)

(define-private (calculate-benchmark-metrics 
    (industry (string-ascii 30))
    (location (string-ascii 30))
    (position (string-ascii 50)))
    (let (
        (sample-data (list 
            {salary: u65000, exp: u3}
            {salary: u75000, exp: u5}
            {salary: u85000, exp: u7}
            {salary: u95000, exp: u10}
            {salary: u105000, exp: u12}))
        (data-count (len sample-data))
        (total-salary (fold + (map get-salary sample-data) u0))
        (avg-salary (/ total-salary data-count))
        (min-salary u60000)
        (max-salary u110000)
        (median-salary u85000)
    )
        {
            min-salary: min-salary,
            max-salary: max-salary,
            median-salary: median-salary,
            data-points: data-count,
            last-updated: stacks-block-height
        }
    )
)

(define-private (get-salary (item {salary: uint, exp: uint}))
    (get salary item)
)

(define-public (update-market-benchmark
    (industry (string-ascii 30))
    (location (string-ascii 30))
    (position (string-ascii 50)))
    (let (
        (requester tx-sender)
        (company-data (map-get? Companies requester))
        (calculated-metrics (calculate-benchmark-metrics industry location position))
    )
        (asserts! (is-some company-data) (err u404))
        (asserts! (get subscription-status (unwrap-panic company-data)) (err u403))
        (ok (map-set CompensationBenchmarks
            {industry: industry, location: location, position: position}
            calculated-metrics))
    )
)

(define-public (get-salary-benchmark
    (industry (string-ascii 30))
    (location (string-ascii 30))
    (position (string-ascii 50)))
    (let (
        (requester tx-sender)
        (access-data (map-get? EmployeeBenchmarkAccess requester))
        (benchmark-data (map-get? CompensationBenchmarks {industry: industry, location: location, position: position}))
    )
        (asserts! (is-some access-data) (err u403))
        (asserts! (is-some benchmark-data) err-benchmark-not-found)
        (asserts! (>= (get data-points (unwrap-panic benchmark-data)) u3) err-insufficient-data-points)
        (map-set EmployeeBenchmarkAccess
            requester
            (merge (unwrap-panic access-data) {last-access: stacks-block-height}))
        (ok benchmark-data)
    )
)

(define-public (compare-salary-to-market
    (encrypted-salary (buff 32))
    (industry (string-ascii 30))
    (location (string-ascii 30))
    (position (string-ascii 50))
    (years-experience uint))
    (let (
        (employee tx-sender)
        (benchmark-data (map-get? CompensationBenchmarks {industry: industry, location: location, position: position}))
        (access-data (map-get? EmployeeBenchmarkAccess employee))
        (experience-adjustment (if (> years-experience u10) u15000 
                              (if (> years-experience u5) u10000 
                              (if (> years-experience u2) u5000 u0))))
    )
        (asserts! (is-some access-data) (err u403))
        (asserts! (is-some benchmark-data) err-benchmark-not-found)
        (let (
            (benchmark (unwrap-panic benchmark-data))
            (adjusted-median (+ (get median-salary benchmark) experience-adjustment))
            (adjusted-min (+ (get min-salary benchmark) experience-adjustment))
            (adjusted-max (+ (get max-salary benchmark) experience-adjustment))
        )
            (ok {
                market-median: adjusted-median,
                market-range-min: adjusted-min,
                market-range-max: adjusted-max,
                data-points: (get data-points benchmark),
                percentile-estimate: u50,
                experience-adjustment: experience-adjustment
            })
        )
    )
)

(define-public (verify-salary-submission (submission-id uint))
    (let (
        (verifier tx-sender)
        (company-data (map-get? Companies verifier))
        (submission-data (map-get? AnonymousSalarySubmissions {submission-id: submission-id}))
    )
        (asserts! (is-some company-data) (err u404))
        (asserts! (get subscription-status (unwrap-panic company-data)) (err u403))
        (asserts! (is-some submission-data) (err u404))
        (ok (map-set AnonymousSalarySubmissions
            {submission-id: submission-id}
            (merge (unwrap-panic submission-data) {verified: true})))
    )
)





(define-read-only (get-benchmark-access-status (employee principal))
    (map-get? EmployeeBenchmarkAccess employee)
)

(define-read-only (get-industry-benchmark-summary
    (industry (string-ascii 30))
    (location (string-ascii 30)))
    (let (
        (sample-benchmark (map-get? CompensationBenchmarks {industry: industry, location: location, position: "developer"}))
    )
        (if (is-some sample-benchmark)
            (ok {
                has-data: true,
                data-points: (get data-points (unwrap-panic sample-benchmark)),
                last-updated: (get last-updated (unwrap-panic sample-benchmark))
            })
            (ok {
                has-data: false,
                data-points: u0,
                last-updated: u0
            }))
    )
)
(define-read-only (get-employee-submission (submission-id uint))
    (map-get? AnonymousSalarySubmissions {submission-id: submission-id})
)