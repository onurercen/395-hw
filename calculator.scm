
(define variables '())

(define (get-var x)
  (let ((pair (assoc x variables)))
    (if pair
        (cdr pair)
        (begin
          (display "Tanımsız değişken: ")
          (display x)
          (newline)
          0))))

(define (set-var! x val)
  (set! variables (cons (cons x val) 
                       (filter (lambda (p) (not (equal? (car p) x))) variables)))
  val)

(define (eval-expr expr)
  (cond
    ((number? expr) expr)
    ((symbol? expr) (get-var expr))
    ((and (list? expr) (= (length expr) 3))
     (let ((a (eval-expr (car expr)))
          (op (cadr expr))
          (b (eval-expr (caddr expr))))
       (cond
         ((eq? op '+) (+ a b))
         ((eq? op '-) (- a b))
         ((eq? op '*) (* a b))
         ((eq? op '/) (/ a b))
         ((eq? op '=) (set-var! (car expr) b))
         (else (display "Geçersiz operatör") 0))))
    (else (display "Geçersiz ifade") 0)))

(define (main)
  (display "> ")
  (let ((input (read)))
    (cond
      ((or (eof-object? input) (equal? input 'exit)) 
       (display "Program sonlandı"))
      (else
       (let ((result (eval-expr input)))
         (display "= ")
         (display result)
         (newline)
         (main))))))

(display "Hesap Makinesi Programı\n")
(display "Kullanım: (3 + 5) veya (x = 10) veya (x + 2)\n")
(display "Çıkmak için 'exit' yazın\n\n")
(main)