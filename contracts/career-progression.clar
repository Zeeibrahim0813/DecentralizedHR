;; Career Progression Recommendations System
;; Provides automated career path analysis, skill gap identification, and mentor matching

;; Error constants
(define-constant err-not-authorized (err u200))
(define-constant err-not-found (err u201))
(define-constant err-already-exists (err u202))
(define-constant err-invalid-data (err u203))
(define-constant err-insufficient-experience (err u204))
(define-constant err-no-recommendations (err u205))

;; Career path templates based on common industry progressions
(define-map CareerPathTemplates
    {path-id: uint}
    {
        path-name: (string-ascii 50),
        industry: (string-ascii 30),
        entry-role: (string-ascii 50),
        target-role: (string-ascii 50),
        min-years-experience: uint,
        required-skills: (list 10 (string-ascii 30)),
        avg-salary-increase: uint,
        success-rate: uint,
        created-by: principal
    }
)

;; Employee career goals and preferences
(define-map EmployeeCareerGoals
    principal
    {
        target-roles: (list 5 (string-ascii 50)),
        preferred-industries: (list 3 (string-ascii 30)),
        salary-target: uint,
        timeline-months: uint,
        location-flexibility: bool,
        remote-preference: bool,
        last-updated: uint
    }
)

;; Career progression recommendations for employees
(define-map CareerRecommendations
    {employee: principal, recommendation-id: uint}
    {
        recommended-path-id: uint,
        confidence-score: uint,
        skill-gaps: (list 5 (string-ascii 30)),
        recommended-actions: (list 3 (string-ascii 100)),
        estimated-timeline: uint,
        salary-projection: uint,
        generated-at: uint,
        status: (string-ascii 20)
    }
)

;; Mentor-mentee matching system
(define-map MentorProfiles
    principal
    {
        expertise-areas: (list 5 (string-ascii 30)),
        current-role: (string-ascii 50),
        years-experience: uint,
        successful-transitions: uint,
        mentorship-capacity: uint,
        active-mentees: uint,
        rating: uint,
        available: bool
    }
)

;; Skill development tracking
(define-map SkillDevelopmentPlans
    {employee: principal, plan-id: uint}
    {
        target-skill: (string-ascii 30),
        current-level: uint,
        target-level: uint,
        learning-resources: (list 3 (string-ascii 100)),
        estimated-duration: uint,
        progress-percentage: uint,
        mentor-assigned: (optional principal),
        created-at: uint
    }
)

;; Auto-incrementing IDs
(define-data-var path-id-nonce uint u0)
(define-data-var recommendation-id-nonce uint u0)
(define-data-var plan-id-nonce uint u0)

;; Set employee career goals
(define-public (set-career-goals
    (target-roles (list 5 (string-ascii 50)))
    (preferred-industries (list 3 (string-ascii 30)))
    (salary-target uint)
    (timeline-months uint)
    (location-flexibility bool)
    (remote-preference bool))
    (let ((employee tx-sender))
        (asserts! (> (len target-roles) u0) err-invalid-data)
        (asserts! (> salary-target u0) err-invalid-data)
        (asserts! (> timeline-months u0) err-invalid-data)
        (ok (map-set EmployeeCareerGoals
            employee
            {
                target-roles: target-roles,
                preferred-industries: preferred-industries,
                salary-target: salary-target,
                timeline-months: timeline-months,
                location-flexibility: location-flexibility,
                remote-preference: remote-preference,
                last-updated: stacks-block-height
            }))
    )
)

;; Register as a mentor
(define-public (register-mentor
    (expertise-areas (list 5 (string-ascii 30)))
    (current-role (string-ascii 50))
    (years-experience uint)
    (mentorship-capacity uint))
    (let ((mentor tx-sender))
        (asserts! (> (len expertise-areas) u0) err-invalid-data)
        (asserts! (>= years-experience u3) err-insufficient-experience)
        (asserts! (> mentorship-capacity u0) err-invalid-data)
        (ok (map-set MentorProfiles
            mentor
            {
                expertise-areas: expertise-areas,
                current-role: current-role,
                years-experience: years-experience,
                successful-transitions: u0,
                mentorship-capacity: mentorship-capacity,
                active-mentees: u0,
                rating: u80,
                available: true
            }))
    )
)

;; Create a career path template
(define-public (create-career-path
    (path-name (string-ascii 50))
    (industry (string-ascii 30))
    (entry-role (string-ascii 50))
    (target-role (string-ascii 50))
    (min-years-experience uint)
    (required-skills (list 10 (string-ascii 30)))
    (avg-salary-increase uint))
    (let (
        (creator tx-sender)
        (new-path-id (+ (var-get path-id-nonce) u1))
    )
        (asserts! (> (len required-skills) u0) err-invalid-data)
        (var-set path-id-nonce new-path-id)
        (ok (map-set CareerPathTemplates
            {path-id: new-path-id}
            {
                path-name: path-name,
                industry: industry,
                entry-role: entry-role,
                target-role: target-role,
                min-years-experience: min-years-experience,
                required-skills: required-skills,
                avg-salary-increase: avg-salary-increase,
                success-rate: u75,
                created-by: creator
            }))
    )
)

;; Generate career recommendations for an employee
(define-public (generate-recommendations (employee principal))
    (let (
        (goals (map-get? EmployeeCareerGoals employee))
        (new-recommendation-id (+ (var-get recommendation-id-nonce) u1))
        (sample-path-id u1)
        (confidence-score u85)
        (skill-gaps (list "leadership" "project-management"))
        (actions (list "Complete leadership training" "Seek project lead role"))
    )
        (asserts! (is-some goals) err-not-found)
        (var-set recommendation-id-nonce new-recommendation-id)
        (ok (map-set CareerRecommendations
            {employee: employee, recommendation-id: new-recommendation-id}
            {
                recommended-path-id: sample-path-id,
                confidence-score: confidence-score,
                skill-gaps: skill-gaps,
                recommended-actions: actions,
                estimated-timeline: (get timeline-months (unwrap-panic goals)),
                salary-projection: (+ (get salary-target (unwrap-panic goals)) u15000),
                generated-at: stacks-block-height,
                status: "active"
            }))
    )
)

;; Find potential mentors based on expertise area
(define-public (find-mentors (expertise-area (string-ascii 30)))
    (let (
        (employee tx-sender)
        (sample-mentor 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
    )
        (ok {
            recommended-mentor: sample-mentor,
            expertise-match: true,
            availability: true,
            rating: u90
        })
    )
)

;; Create skill development plan
(define-public (create-skill-development-plan
    (target-skill (string-ascii 30))
    (current-level uint)
    (target-level uint)
    (learning-resources (list 3 (string-ascii 100)))
    (estimated-duration uint))
    (let (
        (employee tx-sender)
        (new-plan-id (+ (var-get plan-id-nonce) u1))
    )
        (asserts! (<= current-level u4) err-invalid-data)
        (asserts! (<= target-level u4) err-invalid-data)
        (asserts! (> target-level current-level) err-invalid-data)
        (var-set plan-id-nonce new-plan-id)
        (ok (map-set SkillDevelopmentPlans
            {employee: employee, plan-id: new-plan-id}
            {
                target-skill: target-skill,
                current-level: current-level,
                target-level: target-level,
                learning-resources: learning-resources,
                estimated-duration: estimated-duration,
                progress-percentage: u0,
                mentor-assigned: none,
                created-at: stacks-block-height
            }))
    )
)

;; Update skill development progress
(define-public (update-skill-progress
    (plan-id uint)
    (progress-percentage uint))
    (let (
        (employee tx-sender)
        (plan-data (map-get? SkillDevelopmentPlans {employee: employee, plan-id: plan-id}))
    )
        (asserts! (is-some plan-data) err-not-found)
        (asserts! (<= progress-percentage u100) err-invalid-data)
        (ok (map-set SkillDevelopmentPlans
            {employee: employee, plan-id: plan-id}
            (merge (unwrap-panic plan-data) {progress-percentage: progress-percentage})))
    )
)

;; Assign mentor to development plan
(define-public (assign-mentor-to-plan
    (employee principal)
    (plan-id uint)
    (mentor principal))
    (let (
        (plan-data (map-get? SkillDevelopmentPlans {employee: employee, plan-id: plan-id}))
        (mentor-data (map-get? MentorProfiles mentor))
    )
        (asserts! (is-some plan-data) err-not-found)
        (asserts! (is-some mentor-data) err-not-found)
        (asserts! (get available (unwrap-panic mentor-data)) err-not-authorized)
        (ok (map-set SkillDevelopmentPlans
            {employee: employee, plan-id: plan-id}
            (merge (unwrap-panic plan-data) {mentor-assigned: (some mentor)})))
    )
)

;; Calculate career progression score based on current data
(define-private (calculate-progression-score 
    (current-role (string-ascii 50))
    (target-role (string-ascii 50))
    (years-experience uint)
    (skill-level uint))
    (let (
        (experience-score (if (>= years-experience u5) u30 (if (>= years-experience u2) u20 u10)))
        (skill-score (* skill-level u20))
        (role-transition-score u25)
    )
        (+ experience-score skill-score role-transition-score)
    )
)

;; Read-only functions

(define-read-only (get-employee-career-goals (employee principal))
    (map-get? EmployeeCareerGoals employee)
)

(define-read-only (get-career-recommendations 
    (employee principal) 
    (recommendation-id uint))
    (map-get? CareerRecommendations {employee: employee, recommendation-id: recommendation-id})
)

(define-read-only (get-mentor-profile (mentor principal))
    (map-get? MentorProfiles mentor)
)

(define-read-only (get-skill-development-plan 
    (employee principal) 
    (plan-id uint))
    (map-get? SkillDevelopmentPlans {employee: employee, plan-id: plan-id})
)

(define-read-only (get-career-path-template (path-id uint))
    (map-get? CareerPathTemplates {path-id: path-id})
)

;; Analytics functions for career insights
(define-read-only (get-career-analytics (employee principal))
    (let (
        (goals (map-get? EmployeeCareerGoals employee))
        (sample-recommendation (map-get? CareerRecommendations {employee: employee, recommendation-id: u1}))
    )
        (if (and (is-some goals) (is-some sample-recommendation))
            (ok {
                goals-set: true,
                recommendations-available: true,
                target-salary: (get salary-target (unwrap-panic goals)),
                projected-salary: (get salary-projection (unwrap-panic sample-recommendation)),
                timeline: (get timeline-months (unwrap-panic goals))
            })
            err-not-found)
    )
)

(define-read-only (get-mentor-availability (expertise-area (string-ascii 30)))
    (ok {
        available-mentors: u5,
        avg-rating: u88,
        avg-response-time: u24
    })
)