;; GlowTide Brand Registry Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-already-voted (err u104))
(define-constant err-invalid-score (err u105))
(define-constant err-brand-inactive (err u106))
(define-constant err-empty-name (err u107))
(define-constant err-duplicate-name (err u108))

;; Data Variables
(define-map brands
    { brand-id: uint }
    {
        name: (string-ascii 50),
        owner: principal,
        sustainability-score: uint,
        ethical-score: uint,
        verified: bool,
        active: bool,
        registration-date: uint,
        community-trust-score: uint,
        vote-count: uint
    }
)

(define-map brand-names
    { name: (string-ascii 50) }
    { brand-id: uint }
)

(define-map brand-certifications
    { brand-id: uint }
    {
        organic: bool,
        fair-trade: bool,
        recycled-materials: bool,
        last-updated: uint
    }
)

(define-map user-votes
    { brand-id: uint, voter: principal }
    { score: uint }
)

(define-data-var next-brand-id uint u1)

;; Public Functions

;; Register new brand
(define-public (register-brand (name (string-ascii 50)) (sustainability-score uint) (ethical-score uint))
    (let
        (
            (brand-id (var-get next-brand-id))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> (len name) u0) err-empty-name)
        (asserts! (is-none (map-get? brand-names {name: name})) err-duplicate-name)
        (asserts! (<= sustainability-score u100) err-invalid-score)
        (asserts! (<= ethical-score u100) err-invalid-score)
        
        (map-insert brands
            { brand-id: brand-id }
            {
                name: name,
                owner: tx-sender,
                sustainability-score: sustainability-score,
                ethical-score: ethical-score,
                verified: false,
                active: true,
                registration-date: block-height,
                community-trust-score: u0,
                vote-count: u0
            }
        )
        (map-insert brand-names {name: name} {brand-id: brand-id})
        (var-set next-brand-id (+ brand-id u1))
        (print { event: "brand-registered", brand-id: brand-id, name: name })
        (ok brand-id)
    )
)

;; Update certifications
(define-public (update-certifications (brand-id uint) (organic bool) (fair-trade bool) (recycled bool))
    (let
        (
            (brand-info (unwrap! (map-get? brands {brand-id: brand-id}) err-not-found))
        )
        (asserts! (is-eq tx-sender (get owner brand-info)) err-unauthorized)
        (asserts! (get active brand-info) err-brand-inactive)
        (print { 
            event: "certifications-updated", 
            brand-id: brand-id,
            organic: organic,
            fair-trade: fair-trade,
            recycled: recycled
        })
        (ok (map-set brand-certifications
            { brand-id: brand-id }
            {
                organic: organic,
                fair-trade: fair-trade,
                recycled-materials: recycled,
                last-updated: block-height
            }
        ))
    )
)

;; Submit community trust vote with improved precision
(define-public (submit-trust-vote (brand-id uint) (score uint))
    (let
        (
            (brand-info (unwrap! (map-get? brands {brand-id: brand-id}) err-not-found))
            (existing-vote (map-get? user-votes {brand-id: brand-id, voter: tx-sender}))
            (scaled-score (* score u100))
            (current-total (* (get community-trust-score brand-info) (get vote-count brand-info)))
        )
        (asserts! (get active brand-info) err-brand-inactive)
        (asserts! (is-none existing-vote) err-already-voted)
        (asserts! (<= score u100) err-invalid-score)
        
        (map-set user-votes
            {brand-id: brand-id, voter: tx-sender}
            {score: score}
        )
        
        (print { event: "trust-vote-submitted", brand-id: brand-id, voter: tx-sender, score: score })
        
        (ok (map-set brands
            { brand-id: brand-id }
            (merge brand-info
                {
                    community-trust-score: (/ (+ (* current-total u100) scaled-score)
                                            (+ (get vote-count brand-info) u1)),
                    vote-count: (+ (get vote-count brand-info) u1)
                }
            ))
        )
    )
)

[Previous read-only functions remain unchanged...]
