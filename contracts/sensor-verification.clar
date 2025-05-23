;; Sensor Verification Contract
;; This contract validates noise monitoring devices in the smart city network

(define-data-var admin principal tx-sender)
(define-map verified-sensors principal bool)
(define-map sensor-details principal
  {
    sensor-id: (string-utf8 36),
    location: (string-utf8 100),
    installation-date: uint,
    last-maintenance: uint,
    is-active: bool
  }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-ALREADY-VERIFIED u101)
(define-constant ERR-NOT-FOUND u102)

;; Read-only functions
(define-read-only (is-admin (account principal))
  (is-eq account (var-get admin))
)

(define-read-only (is-sensor-verified (sensor-address principal))
  (default-to false (map-get? verified-sensors sensor-address))
)

(define-read-only (get-sensor-details (sensor-address principal))
  (map-get? sensor-details sensor-address)
)

;; Public functions
(define-public (register-sensor
    (sensor-address principal)
    (sensor-id (string-utf8 36))
    (location (string-utf8 100))
  )
  (begin
    (asserts! (is-admin tx-sender) (err ERR-NOT-AUTHORIZED))
    (asserts! (not (is-sensor-verified sensor-address)) (err ERR-ALREADY-VERIFIED))

    (map-set verified-sensors sensor-address true)
    (map-set sensor-details sensor-address {
      sensor-id: sensor-id,
      location: location,
      installation-date: block-height,
      last-maintenance: block-height,
      is-active: true
    })
    (ok true)
  )
)

(define-public (deactivate-sensor (sensor-address principal))
  (begin
    (asserts! (is-admin tx-sender) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-sensor-verified sensor-address) (err ERR-NOT-FOUND))

    (let ((current-details (unwrap! (get-sensor-details sensor-address) (err ERR-NOT-FOUND))))
      (map-set sensor-details sensor-address (merge current-details { is-active: false }))
      (ok true)
    )
  )
)

(define-public (update-maintenance (sensor-address principal))
  (begin
    (asserts! (is-admin tx-sender) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-sensor-verified sensor-address) (err ERR-NOT-FOUND))

    (let ((current-details (unwrap! (get-sensor-details sensor-address) (err ERR-NOT-FOUND))))
      (map-set sensor-details sensor-address (merge current-details { last-maintenance: block-height }))
      (ok true)
    )
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin tx-sender) (err ERR-NOT-AUTHORIZED))
    (var-set admin new-admin)
    (ok true)
  )
)
