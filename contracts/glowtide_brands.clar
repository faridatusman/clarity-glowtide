;; GlowTide Brand Registry Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

;; Data Variables
(define-map brands
    { brand-id: uint }
    {
        name: (string-ascii 50),
        owner: principal,
        sustainability-score: uint,
        ethical-score: uint,
        verified: bool,
        registration-date: uint
    }
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

(define-data-var next-brand-id uint u1)

;; Public Functions

;; Register new brand
(define-public (register-brand (name (string-ascii 50)) (sustainability-score uint) (ethical-score uint))
    (let
        (
            (brand-id (var-get next-brand-id))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-insert brands
            { brand-id: brand-id }
            {
                name: name,
                owner: tx-sender,
                sustainability-score: sustainability-score,
                ethical-score: ethical-score,
                verified: false,
                registration-date: block-height
            }
        )
        (var-set next-brand-id (+ brand-id u1))
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

;; Verify brand
(define-public (verify-brand (brand-id uint))
    (let
        (
            (brand-info (unwrap! (map-get? brands {brand-id: brand-id}) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set brands
            { brand-id: brand-id }
            (merge brand-info { verified: true })
        ))
    )
)

;; Read-only functions

(define-read-only (get-brand-info (brand-id uint))
    (ok (map-get? brands {brand-id: brand-id}))
)

(define-read-only (get-brand-certifications (brand-id uint))
    (ok (map-get? brand-certifications {brand-id: brand-id}))
)