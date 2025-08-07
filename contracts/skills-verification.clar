;; Skills Verification Network
;; Decentralized system for objective skill assessment and validation

;; Error constants
(define-constant err-not-authorized (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-invalid-score (err u104))
(define-constant err-challenge-expired (err u105))
(define-constant err-insufficient-validators (err u106))
(define-constant err-already-validated (err u107))
(define-constant err-self-validation (err u108))

;; Challenge categories and difficulty levels
(define-constant challenge-beginner u1)
(define-constant challenge-intermediate u2)
(define-constant challenge-advanced u3)
(define-constant challenge-expert u4)

;; Validation thresholds
(define-constant min-validators-required u3)
(define-constant max-validators-per-challenge u7)
(define-constant challenge-duration-blocks u1440) ;; ~24 hours

;; Core data structures for skill challenges
(define-map SkillChallenges
    {challenge-id: uint}
    {
        skill-category: (string-ascii 30),
        difficulty-level: uint,
        challenge-text: (string-ascii 500),
        expected-solution-hash: (buff 32),
        creator: principal,
        reward-amount: uint,
        created-at: uint,
        expiry-block: uint,
        active: bool
    }
)

;; Employee skill assessment requests
(define-map SkillAssessmentRequests
    {request-id: uint}
    {
        employee: principal,
        skill-category: (string-ascii 30),
        requested-difficulty: uint,
        assessment-fee: uint,
        status: (string-ascii 20),
        created-at: uint,
        assigned-challenge-id: (optional uint)
    }
)

;; Validator network registration and reputation
(define-map SkillValidators
    principal
    {
        expertise-areas: (list 5 (string-ascii 30)),
        validation-count: uint,
        reputation-score: uint,
        total-earnings: uint,
        active-status: bool,
        registered-at: uint
    }
)

;; Challenge submissions and results
(define-map ChallengeSubmissions
    {submission-id: uint}
    {
        challenge-id: uint,
        employee: principal,
        solution-hash: (buff 32),
        submitted-at: uint,
        validation-status: (string-ascii 20),
        final-score: uint,
        validator-scores: (list 7 uint),
        validated-by: (list 7 principal)
    }
)

;; Skill verification results for employees
(define-map EmployeeSkillVerifications
    {employee: principal, skill-category: (string-ascii 30)}
    {
        proficiency-level: uint,
        verification-score: uint,
        challenges-completed: uint,
        last-assessment: uint,
        verified-by-count: uint,
        skill-badge-hash: (buff 32)
    }
)

;; Validator assignments for challenges
(define-map ValidatorAssignments
    {challenge-id: uint, validator: principal}
    {
        assigned-at: uint,
        validation-submitted: bool,
        score-given: uint,
        validation-notes: (string-ascii 200)
    }
)

;; Auto-incrementing IDs
(define-data-var challenge-id-nonce uint u0)
(define-data-var request-id-nonce uint u0)
(define-data-var submission-id-nonce uint u0)

;; Register as a skill validator
(define-public (register-validator (expertise-areas (list 5 (string-ascii 30))))
    (let (
        (validator tx-sender)
        (existing-validator (map-get? SkillValidators validator))
    )
        (asserts! (is-none existing-validator) err-already-exists)
        (asserts! (> (len expertise-areas) u0) err-invalid-status)
        (ok (map-set SkillValidators
            validator
            {
                expertise-areas: expertise-areas,
                validation-count: u0,
                reputation-score: u100, ;; Starting reputation
                total-earnings: u0,
                active-status: true,
                registered-at: stacks-block-height
            }))
    )
)

;; Create a new skill challenge
(define-public (create-skill-challenge
    (skill-category (string-ascii 30))
    (difficulty-level uint)
    (challenge-text (string-ascii 500))
    (expected-solution-hash (buff 32))
    (reward-amount uint))
    (let (
        (creator tx-sender)
        (new-challenge-id (+ (var-get challenge-id-nonce) u1))
        (expiry-block (+ stacks-block-height challenge-duration-blocks))
    )
        (asserts! (<= difficulty-level challenge-expert) err-invalid-status)
        (asserts! (>= difficulty-level challenge-beginner) err-invalid-status)
        (asserts! (> reward-amount u0) err-invalid-status)
        (var-set challenge-id-nonce new-challenge-id)
        (ok (map-set SkillChallenges
            {challenge-id: new-challenge-id}
            {
                skill-category: skill-category,
                difficulty-level: difficulty-level,
                challenge-text: challenge-text,
                expected-solution-hash: expected-solution-hash,
                creator: creator,
                reward-amount: reward-amount,
                created-at: stacks-block-height,
                expiry-block: expiry-block,
                active: true
            }))
    )
)

;; Request skill assessment
(define-public (request-skill-assessment
    (skill-category (string-ascii 30))
    (requested-difficulty uint)
    (assessment-fee uint))
    (let (
        (employee tx-sender)
        (new-request-id (+ (var-get request-id-nonce) u1))
    )
        (asserts! (<= requested-difficulty challenge-expert) err-invalid-status)
        (asserts! (>= requested-difficulty challenge-beginner) err-invalid-status)
        (var-set request-id-nonce new-request-id)
        (ok (map-set SkillAssessmentRequests
            {request-id: new-request-id}
            {
                employee: employee,
                skill-category: skill-category,
                requested-difficulty: requested-difficulty,
                assessment-fee: assessment-fee,
                status: "pending",
                created-at: stacks-block-height,
                assigned-challenge-id: none
            }))
    )
)

;; Submit solution to challenge
(define-public (submit-challenge-solution
    (challenge-id uint)
    (solution-hash (buff 32)))
    (let (
        (employee tx-sender)
        (challenge-data (map-get? SkillChallenges {challenge-id: challenge-id}))
        (new-submission-id (+ (var-get submission-id-nonce) u1))
    )
        (asserts! (is-some challenge-data) err-not-found)
        (asserts! (get active (unwrap-panic challenge-data)) err-invalid-status)
        (asserts! (<= stacks-block-height (get expiry-block (unwrap-panic challenge-data))) err-challenge-expired)
        (var-set submission-id-nonce new-submission-id)
        (ok (map-set ChallengeSubmissions
            {submission-id: new-submission-id}
            {
                challenge-id: challenge-id,
                employee: employee,
                solution-hash: solution-hash,
                submitted-at: stacks-block-height,
                validation-status: "pending",
                final-score: u0,
                validator-scores: (list),
                validated-by: (list)
            }))
    )
)

;; Validate challenge submission
(define-public (validate-submission
    (submission-id uint)
    (score uint)
    (validation-notes (string-ascii 200)))
    (let (
        (validator tx-sender)
        (submission-data (map-get? ChallengeSubmissions {submission-id: submission-id}))
        (validator-data (map-get? SkillValidators validator))
    )
        (asserts! (is-some submission-data) err-not-found)
        (asserts! (is-some validator-data) err-not-found)
        (asserts! (get active-status (unwrap-panic validator-data)) err-not-authorized)
        (asserts! (<= score u100) err-invalid-score)
        (asserts! (not (is-eq validator (get employee (unwrap-panic submission-data)))) err-self-validation)
        
        (let (
            (submission (unwrap-panic submission-data))
            (challenge-id (get challenge-id submission))
            (current-scores (get validator-scores submission))
            (current-validators (get validated-by submission))
        )
            ;; Check if validator already validated this submission
            (asserts! (is-none (index-of current-validators validator)) err-already-validated)
            (asserts! (< (len current-scores) max-validators-per-challenge) err-insufficient-validators)
            
            ;; Record validator assignment
            (map-set ValidatorAssignments
                {challenge-id: challenge-id, validator: validator}
                {
                    assigned-at: stacks-block-height,
                    validation-submitted: true,
                    score-given: score,
                    validation-notes: validation-notes
                })
            
            ;; Update submission with new validation
            (let (
                (updated-scores (unwrap-panic (as-max-len? (append current-scores score) u7)))
                (updated-validators (unwrap-panic (as-max-len? (append current-validators validator) u7)))
                (new-final-score (if (>= (len updated-scores) min-validators-required)
                                   (calculate-final-score updated-scores)
                                   u0))
            )
                (ok (map-set ChallengeSubmissions
                    {submission-id: submission-id}
                    (merge submission {
                        validator-scores: updated-scores,
                        validated-by: updated-validators,
                        final-score: new-final-score,
                        validation-status: (if (>= (len updated-scores) min-validators-required) "completed" "pending")
                    }))))
        )
    )
)

;; Calculate weighted final score from validator inputs
(define-private (calculate-final-score (scores (list 7 uint)))
    (let (
        (score-sum (fold + scores u0))
        (score-count (len scores))
    )
        (if (> score-count u0)
            (/ score-sum score-count)
            u0)
    )
)

;; Update employee skill verification based on completed assessments
(define-public (update-skill-verification
    (employee principal)
    (skill-category (string-ascii 30))
    (submission-id uint))
    (let (
        (submission-data (map-get? ChallengeSubmissions {submission-id: submission-id}))
        (current-verification (default-to
            {
                proficiency-level: u0,
                verification-score: u0,
                challenges-completed: u0,
                last-assessment: u0,
                verified-by-count: u0,
                skill-badge-hash: 0x00
            }
            (map-get? EmployeeSkillVerifications {employee: employee, skill-category: skill-category})))
    )
        (asserts! (is-some submission-data) err-not-found)
        (asserts! (is-eq (get validation-status (unwrap-panic submission-data)) "completed") err-invalid-status)
        (asserts! (is-eq (get employee (unwrap-panic submission-data)) employee) err-not-authorized)
        
        (let (
            (submission (unwrap-panic submission-data))
            (final-score (get final-score submission))
            (validator-count (len (get validated-by submission)))
            (new-proficiency (determine-proficiency-level final-score))
            (updated-score (calculate-updated-verification-score 
                           (get verification-score current-verification) 
                           final-score))
        )
            (ok (map-set EmployeeSkillVerifications
                {employee: employee, skill-category: skill-category}
                {
                    proficiency-level: new-proficiency,
                    verification-score: updated-score,
                    challenges-completed: (+ (get challenges-completed current-verification) u1),
                    last-assessment: stacks-block-height,
                    verified-by-count: (+ (get verified-by-count current-verification) validator-count),
                    skill-badge-hash: (generate-skill-badge-hash employee skill-category new-proficiency)
                }))
        )
    )
)

;; Determine proficiency level based on score
(define-private (determine-proficiency-level (score uint))
    (if (>= score u90) u4  ;; Expert
    (if (>= score u75) u3  ;; Advanced  
    (if (>= score u60) u2  ;; Intermediate
    u1))))                 ;; Beginner

;; Calculate updated verification score with weighted averaging
(define-private (calculate-updated-verification-score (current-score uint) (new-score uint))
    (if (is-eq current-score u0)
        new-score
        (/ (+ (* current-score u7) (* new-score u3)) u10)) ;; 70/30 weighted average
)

;; Generate skill badge hash for verification
(define-private (generate-skill-badge-hash 
    (employee principal) 
    (skill-category (string-ascii 30)) 
    (proficiency-level uint))
    (keccak256 (concat 
        (unwrap-panic (to-consensus-buff? employee))
        (unwrap-panic (to-consensus-buff? proficiency-level))))
)

;; Read-only functions

(define-read-only (get-skill-challenge (challenge-id uint))
    (map-get? SkillChallenges {challenge-id: challenge-id})
)

(define-read-only (get-validator-info (validator principal))
    (map-get? SkillValidators validator)
)

(define-read-only (get-employee-skill-verification 
    (employee principal) 
    (skill-category (string-ascii 30)))
    (map-get? EmployeeSkillVerifications {employee: employee, skill-category: skill-category})
)

(define-read-only (get-submission-details (submission-id uint))
    (map-get? ChallengeSubmissions {submission-id: submission-id})
)

(define-read-only (get-assessment-request (request-id uint))
    (map-get? SkillAssessmentRequests {request-id: request-id})
)

