(display
  (let ((x 2) (y 3))
    (+ x y)))
(newline)

(display
  (let ((x 2) (y 3))
    (+ x y)
    (* x y)))
(newline)

(display
  (let ((x 2) (y 3))
    (let ((x 7)
          (z (+ x y)))
      (* z x))))
(newline)
