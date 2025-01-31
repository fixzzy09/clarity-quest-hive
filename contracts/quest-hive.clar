;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-already-exists (err u101))
(define-constant err-already-completed (err u102))

;; Data structures
(define-map quests 
  { quest-id: uint, owner: principal }
  { title: (string-ascii 64),
    description: (string-ascii 256),
    reward-xp: uint,
    created-at: uint })

(define-map quest-completions
  { quest-id: uint, owner: principal, day: uint }
  { completed: bool })
  
(define-map user-stats
  { user: principal }
  { level: uint,
    experience: uint })
    
;; Data vars
(define-data-var quest-nonce uint u0)

;; Public functions
(define-public (create-quest (title (string-ascii 64)) 
                           (description (string-ascii 256))
                           (reward-xp uint))
  (let ((quest-id (+ (var-get quest-nonce) u1)))
    (map-insert quests
      { quest-id: quest-id, owner: tx-sender }
      { title: title,
        description: description,
        reward-xp: reward-xp,
        created-at: block-height })
    (var-set quest-nonce quest-id)
    (ok quest-id)))
    
(define-public (complete-quest (quest-id uint))
  (let ((current-day (/ block-height u144))
        (completion-key { quest-id: quest-id, 
                        owner: tx-sender,
                        day: current-day }))
    (asserts! (is-none (map-get? quest-completions completion-key))
      err-already-completed)
    (map-set quest-completions
      completion-key
      { completed: true })
    (add-experience tx-sender
      (unwrap! (get reward-xp
        (map-get? quests { quest-id: quest-id, owner: tx-sender }))
        err-not-found))
    (ok true)))
    
;; Private functions  
(define-private (add-experience (user principal) (xp uint))
  (let ((current-stats (default-to
          { level: u1, experience: u0 }
          (map-get? user-stats { user: user }))))
    (let ((new-xp (+ (get experience current-stats) xp)))
      (map-set user-stats
        { user: user }
        { level: (calculate-level new-xp),
          experience: new-xp }))))
          
(define-private (calculate-level (xp uint))
  (+ u1 (/ xp u1000)))
  
;; Read only functions
(define-read-only (get-quest-status (quest-id uint))
  (let ((current-day (/ block-height u144)))
    (map-get? quest-completions
      { quest-id: quest-id,
        owner: tx-sender,
        day: current-day })))
        
(define-read-only (get-user-level (user principal))
  (map-get? user-stats { user: user }))
