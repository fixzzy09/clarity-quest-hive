;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-already-exists (err u101))
(define-constant err-already-completed (err u102))
(define-constant err-invalid-reward (err u103))
(define-constant err-invalid-length (err u104))
(define-constant max-reward-xp u10000)

;; Data structures
(define-map quests 
  { quest-id: uint, owner: principal }
  { title: (string-ascii 64),
    description: (string-ascii 256),
    reward-xp: uint,
    created-at: uint })

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

;; Public functions
(define-public (create-quest (title (string-ascii 64)) 
                           (description (string-ascii 256))
                           (reward-xp uint))
  (begin
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
          created-at: block-height })
      (var-set quest-nonce quest-id)
      (ok quest-id))))

(define-public (complete-quest (quest-id uint))
  (let ((current-day (/ block-height u144))
        (completion-key { quest-id: quest-id, 
                        owner: tx-sender,
                        day: current-day }))
    (asserts! (is-none (map-get? quest-completions completion-key))
      err-already-completed)
    (asserts! (is-some (map-get? quests { quest-id: quest-id, owner: tx-sender }))
      err-not-found)
    (let ((streak (get-streak quest-id current-day)))
      (map-set quest-completions
        completion-key
        { completed: true,
          streak: (+ streak u1) })
      (add-experience tx-sender
        (calculate-reward
          (unwrap! (get reward-xp
            (map-get? quests { quest-id: quest-id, owner: tx-sender }))
            err-not-found)
          streak))
      (ok true))))

;; Private functions  
(define-private (add-experience (user principal) (xp uint))
  (let ((current-stats (default-to
          { level: u1, experience: u0, total-completed: u0 }
          (map-get? user-stats { user: user }))))
    (let ((new-xp (+ (get experience current-stats) xp)))
      (map-set user-stats
        { user: user }
        { level: (calculate-level new-xp),
          experience: new-xp,
          total-completed: (+ (get total-completed current-stats) u1) }))))
          
(define-private (calculate-level (xp uint))
  (+ u1 (/ xp u1000)))
  
(define-private (get-streak (quest-id uint) (current-day uint))
  (default-to u0
    (get streak
      (map-get? quest-completions
        { quest-id: quest-id,
          owner: tx-sender,
          day: (- current-day u1) }))))
          
(define-private (calculate-reward (base-xp uint) (streak uint))
  (let ((bonus-multiplier (+ u100 (* streak u10))))
    (/ (* base-xp bonus-multiplier) u100)))

;; Read only functions
(define-read-only (get-quest-status (quest-id uint))
  (let ((current-day (/ block-height u144)))
    (map-get? quest-completions
      { quest-id: quest-id,
        owner: tx-sender,
        day: current-day })))
        
(define-read-only (get-user-level (user principal))
  (map-get? user-stats { user: user }))
  
(define-read-only (get-user-quests (user principal))
  (map-get? quests { owner: user }))
  
(define-read-only (get-quest-streak (quest-id uint))
  (let ((current-day (/ block-height u144)))
    (get-streak quest-id current-day)))
