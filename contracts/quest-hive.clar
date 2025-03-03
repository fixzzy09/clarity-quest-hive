;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-already-exists (err u101))
(define-constant err-already-completed (err u102))
(define-constant err-invalid-reward (err u103))
(define-constant err-invalid-length (err u104))
(define-constant err-not-authorized (err u105))
(define-constant err-quest-inactive (err u106))
(define-constant max-reward-xp u10000)

;; Data structures
(define-map quests 
  { quest-id: uint, owner: principal }
  { title: (string-ascii 64),
    description: (string-ascii 256),
    reward-xp: uint,
    created-at: uint,
    active: bool })

(define-map quest-completions
  { quest-id: uint, owner: principal, day: uint }
  { completed: bool,
    streak: uint })

(define-map user-stats
  { user: principal }
  { level: uint,
    experience: uint,
    total-completed: uint })
    
;; Data vars
(define-data-var quest-nonce uint u0)
(define-data-var contract-paused bool false)

;; Administrative functions
(define-public (set-contract-pause (paused bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (ok (var-set contract-paused paused))))

;; Public functions
(define-public (create-quest (title (string-ascii 64)) 
                           (description (string-ascii 256))
                           (reward-xp uint))
  (begin
    (asserts! (not (var-get contract-paused)) err-not-authorized)
    (asserts! (> reward-xp u0) err-invalid-reward)
    (asserts! (<= reward-xp max-reward-xp) err-invalid-reward)
    (asserts! (> (len title) u0) err-invalid-length)
    (asserts! (> (len description) u0) err-invalid-length)
    (let ((quest-id (+ (var-get quest-nonce) u1)))
      (map-insert quests
        { quest-id: quest-id, owner: tx-sender }
        { title: title,
          description: description,
          reward-xp: reward-xp,
          created-at: block-height,
          active: true })
      (var-set quest-nonce quest-id)
      (ok quest-id))))

(define-public (modify-quest (quest-id uint) 
                           (title (string-ascii 64))
                           (description (string-ascii 256))
                           (reward-xp uint))
  (let ((quest-data (unwrap! (map-get? quests { quest-id: quest-id, owner: tx-sender })
                            err-not-found)))
    (begin
      (asserts! (not (var-get contract-paused)) err-not-authorized)
      (asserts! (> reward-xp u0) err-invalid-reward)
      (asserts! (<= reward-xp max-reward-xp) err-invalid-reward)
      (ok (map-set quests
        { quest-id: quest-id, owner: tx-sender }
        { title: title,
          description: description,
          reward-xp: reward-xp,
          created-at: (get created-at quest-data),
          active: (get active quest-data) })))))

(define-public (toggle-quest-status (quest-id uint))
  (let ((quest-data (unwrap! (map-get? quests { quest-id: quest-id, owner: tx-sender })
                            err-not-found)))
    (begin
      (asserts! (not (var-get contract-paused)) err-not-authorized)
      (ok (map-set quests
        { quest-id: quest-id, owner: tx-sender }
        (merge quest-data { active: (not (get active quest-data)) }))))))

[... Rest of the original functions with added validation ...]

;; Enhanced read-only functions
(define-read-only (get-quest-details (quest-id uint))
  (map-get? quests { quest-id: quest-id, owner: tx-sender }))

(define-read-only (is-contract-paused)
  (var-get contract-paused))
