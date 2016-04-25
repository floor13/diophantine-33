;; This code is a direct interface to the computational portion of the code. Certain definitions like compute-with-output are designed to be run in a while loop that checks for user input.
;; all functions that have references to functions or values defined in dio-3d will mention them in the comment immediately above it
(load "./diophantine-3d.scm")
(use-srfis `(1))

(define helpstring
  "Incorrect command. Currently supported commands are:
  \tc : display where we're at
  \tv : toggle verbosity, at the cost of slowing down
  \tw : write the results of the next try to file, and quit
  \tanything else: display this message. It's free!\n")



;; return the victorystring
(define (victorystring victorylist)
  (format #f "Hooray! ~a yields ~a! Back to work.\n" victorylist solution))

;; given an attempt, display the result of the attempt, and return the comparison to the solution defined in dio-3d. needs to be generalized to write to any port (aka not using straight up display)
;; sum-list is sourced from dio-3d
;; solution is sourced from dio-3d
(define (verbose-attempt cubed-list)
  (let ((result (sum-list cubed-list))) ; don't get confused here...
    (display (format #f "\tTrying ~a yields ~a\n" cubed-list result))
    (= result solution)))

;; given a list fresh from our enumerator, cube it, generate the coefficient family, and see if any attempt satisfies the predicate. return the result of the find attempt (if it's not false, then we've found an attempt)
;; this function is partly the reason we don't consolidate all these attempt procedures into one generic one, the family of solutions line can't be encapsulated well, and is relatively necessary
;; list-generate is sourced from dio-3d
(define (verbose-lump-attempt root-list)
  (let ((attempt-list (list-generate root-list)))
    (display (format #f "Attempting family of solutions for ~a\n" root-list))
    (find 
      (lambda (attempt)
	(verbose-attempt attempt))
      attempt-list)))

;; quiet calculation
;; sum-list is sourced from dio-3d
(define (silent-attempt some-list)
  (= solution
     (sum-list some-list)))

;; calls quiet-attempt for each list in attempt-list, generated by list-generate in a similar manner as verbose-lump-attempt
(define (silent-lump-attempt root-list)
  (let ((attempt-list (list-generate root-list)))
    (find
      (lambda (attempt)
	(silent-attempt attempt))
      attempt-list)))

(define input-port (standard-input-port))

;; big function. given parameters, check for input on the input-port (above) apply the list-procedure to the current list, with the comparison, then if it returns false, try again with a new list as defined by inc-list
;; parameters are: 
;; a procedure that takes a list and a value and returns a boolean
;; the value (applied to the above proc)
;; a list
;; a procedure that takes a list and returns a new one (that can also be applied to this proc)
;; needs to also take an input/output port. wondering if that's a performance hit.
;; this function is tail-calling, but generalized. this isn't actually used at all, but I thought it was a neat solution, so I'll keep it here until i'm finished or it bothers me enough.
(define (try-until-input list-procedure compared-value current-list inc-list)
  (cond ((char-ready? input-port)
	 (handle-input (read input-port)
		       (list list-procedure
			     compared-value
			     current-list
			     inc-list))) ; pass over control to handle-input, with a list of state
	((list-procedure current-list compared-value)
	 (display (victorystring current-list))) ; we win!
	(else
	  (try-until-input
	    list-procedure
	    compared-value
	    (inc-list current-list)
	    inc-list)))) ; try again with another list


;; using inc-3-pivot-list from dio-3d, verbose checks for input, then checks if verbose-lump-attempt returns #t, at which point we've found a solution, display it, and stop. otherwise call itself again with the list specified from increment-3-pivot-list.
(define (verbose-try-until-input current-list)
  (cond ((char-ready? input-port)
	 (handle-input current-list))
	((verbose-lump-attempt current-list)
	 (display (victorystring current-list)))
	(else
	  (verbose-try-until-input
	    (increment-3-pivot-list current-list)))))

;; silent try-until-input loop.
(define (silent-try-until-input current-list)
  (cond ((char-ready? input-port)
	 (handle-input current-list))
	((silent-lump-attempt current-list)
	 (display (victorystring current-list)))
	(else
	  (silent-try-until-input
	    (increment-3-pivot-list current-list)))))

;; one-off-loop
;; calls verbose-lump-attempt on the list passed, if it returns true, we're done. 
;; if it returns false, then go back to silently attempting solutions.
(define (one-off-loop current-list)
  (if (verbose-lump-attempt current-list)
    (display (victorystring current-list))
    (silent-try-until-input (increment-3-pivot-list current-list))))

;; display the helpstring, then silently resume computing
(define (help-me current-list)
  (display helpstring)
  (silent-try-until-input current-list))

;; mapping of signals to procedures. all of these procedures check for input every time they're run, and call themselves.
(define signal-proc-pairing
  (list
    (list `v verbose-try-until-input)
    (list `c one-off-loop)
    (list `q silent-try-until-input)
))


;; looks up signal-proc-pairing directly, given a signal, return the signal-proc-pairing defined in signal-proc-pairing. returns false when there is no signal to match
(define (search-signal-proc-pairing signal)
  (find
    (lambda (signal-proc-pair)
      (eq? signal
	   (car signal-proc-pair)))
    signal-proc-pairing))

(define (find-proc-from-signal signal)
  (let ((proc (search-signal-proc-pairing signal)))
    (if proc
      (cadr proc)
      #f)))

;; only gets called when char-ready? on input port holds true, so there should be no hanging
(define (handle-input state)
  (let ((signal (read input-port)))
    (display (format #f "Signal: ~a : with state: ~a\n" signal state))
    (let ((proc (find-proc-from-signal signal)))
      (if proc
	proc
	(help-me state)))))
