;; DecentraResearch - Decentralized Research Funding and Peer Review Network
(define-fungible-token research-credit)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u401))
(define-constant err-insufficient-credits (err u201))
(define-constant err-study-not-found (err u202))
(define-constant err-already-reviewed (err u203))
(define-constant err-review-period-ended (err u204))
(define-constant err-review-period-active (err u205))
(define-constant err-invalid-study-title (err u206))
(define-constant err-invalid-methodology (err u207))
(define-constant err-invalid-data-url (err u208))
(define-constant err-invalid-funding-amount (err u209))

;; Storage
(define-map research-studies uint {
  researcher: principal,
  study-title: (string-utf8 64),
  methodology: (string-utf8 256),
  data-repository: (string-utf8 128),
  peer-approvals: uint,
  peer-rejections: uint,
  funding-status: (string-utf8 16),
  review-deadline: uint
})

(define-map peer-reviews {study-id: uint, reviewer: principal} bool)
(define-map researcher-credits principal uint)
(define-data-var study-counter uint u0)
(define-data-var minimum-credit-threshold uint u50000000) ;; 50 credits
(define-data-var peer-review-duration uint u288) ;; ~2 days in blocks

;; Initialize research credits for institution
(define-public (mint-research-credits (credit-amount uint))
  (begin
    ;; Validate inputs
    (asserts! (> credit-amount u0) err-invalid-funding-amount)
    
    ;; Check authorization
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    
    ;; Mint credits
    (try! (ft-mint? research-credit credit-amount tx-sender))
    
    ;; Update researcher credits
    (ok (map-set researcher-credits tx-sender credit-amount))
  )
)

;; Submit research study for peer review
(define-public (submit-study (study-title (string-utf8 64)) (methodology (string-utf8 256)) (data-repository (string-utf8 128)))
  (let
    ((researcher tx-sender)
     (study-id (var-get study-counter))
     (credit-balance (default-to u0 (map-get? researcher-credits researcher))))
    
    ;; Validate inputs
    (asserts! (> (len study-title) u0) err-invalid-study-title)
    (asserts! (> (len methodology) u0) err-invalid-methodology)
    (asserts! (> (len data-repository) u0) err-invalid-data-url)
    
    ;; Check if researcher has enough credits
    (asserts! (>= credit-balance (var-get minimum-credit-threshold)) err-insufficient-credits)
    
    ;; Store the research study
    (map-set research-studies study-id {
      researcher: researcher,
      study-title: study-title,
      methodology: methodology,
      data-repository: data-repository,
      peer-approvals: u0,
      peer-rejections: u0,
      funding-status: u"under-review",
      review-deadline: (+ burn-block-height (var-get peer-review-duration))
    })
    
    ;; Increment the study ID counter
    (var-set study-counter (+ study-id u1))
    
    (ok study-id)))

;; Peer review a research study
(define-public (peer-review (study-id uint) (approve bool))
  (let
    ((study (unwrap! (map-get? research-studies study-id) err-study-not-found))
     (reviewer tx-sender)
     (credit-balance (default-to u0 (map-get? researcher-credits reviewer)))
     (review-key {study-id: study-id, reviewer: reviewer}))
    
    ;; Check if review period is still active
    (asserts! (< burn-block-height (get review-deadline study)) err-review-period-ended)
    
    ;; Check if reviewer has already reviewed
    (asserts! (is-none (map-get? peer-reviews review-key)) err-already-reviewed)
    
    ;; Record the review
    (map-set peer-reviews review-key true)
    
    ;; Update review counts
    (if approve
      (ok (map-set research-studies study-id (merge study {peer-approvals: (+ (get peer-approvals study) credit-balance)})))
      (ok (map-set research-studies study-id (merge study {peer-rejections: (+ (get peer-rejections study) credit-balance)})))
    )
  )
)

;; Finalize research funding decision
(define-public (finalize-funding (study-id uint))
  (let
    ((study (unwrap! (map-get? research-studies study-id) err-study-not-found)))
    
    ;; Check if review period has ended
    (asserts! (>= burn-block-height (get review-deadline study)) err-review-period-active)
    
    ;; Update funding status
    (ok (map-set research-studies study-id 
      (merge study 
        {funding-status: (if (> (get peer-approvals study) (get peer-rejections study)) u"funded" u"declined")})))
  )
)

;; Get research study details
(define-read-only (get-study (study-id uint))
  (map-get? research-studies study-id))

;; Get researcher credit balance
(define-read-only (get-researcher-credits (researcher principal))
  (default-to u0 (map-get? researcher-credits researcher)))

;; Transfer research credits
(define-public (transfer-credits (credit-amount uint) (recipient principal))
  (let
    ((sender tx-sender)
     (sender-balance (default-to u0 (map-get? researcher-credits sender)))
     (recipient-balance (default-to u0 (map-get? researcher-credits recipient))))
    
    ;; Validate inputs
    (asserts! (> credit-amount u0) err-invalid-funding-amount)
    (asserts! (not (is-eq recipient 'SP000000000000000000002Q6VF78)) err-unauthorized)
    
    ;; Check if sender has enough credits
    (asserts! (>= sender-balance credit-amount) err-insufficient-credits)
    
    ;; Update balances
    (map-set researcher-credits sender (- sender-balance credit-amount))
    (ok (map-set researcher-credits recipient (+ recipient-balance credit-amount)))
  )
)