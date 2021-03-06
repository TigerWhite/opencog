; XXX Temp quick hacks for the upcoming demos
; The design is horrible to call the generator like this

; Example usage of the generator directly from the command line
; ruby marky_markov speak -d ../../markov_modeling/blogs -c 1 -p "It's hot today"

; Files and dictionaries being used are available here:
; https://github.com/opencog/test-datasets/releases/download/current/markov_modeling.tar.gz

;------------------------------------------------------------------------------

(use-modules (ice-9 popen) (rnrs io ports))
(load "states.scm")

;------------------------------------------------------------------------------

(define has-markov-setup #f)
(define markov-bin "")
(define markov-dict "")
(define pkd-relevant-words '())
(define blog-relevant-words '())

(define-public (markov-setup bin-dir dict-dir)
    (define (read-words word-list)
        (let* ((cmd (string-append "cat " dict-dir "/" word-list))
               (port (open-input-pipe cmd))
               (line (get-line port))
               (strong-words-start #f)
               (results '()))
            (while (not (eof-object? line))
                ; Ignore empty lines
                (if (= (string-length (string-trim line)) 0)
                    (set! line (get-line port))
                    (begin
                        ; There are WEAK and STRONG words, only gets STRONG ones
                        (if strong-words-start
                            (set! results (append results (list (string-trim line))))
                            (if (equal? "STRONG" (string-trim line))
                                (set! strong-words-start #t))
                        )
                        (set! line (get-line port))
                    )
                )
            )
            (close-pipe port)
            results
        )
    )

    (set! markov-bin (string-append bin-dir "/marky_markov"))
    (set! markov-dict dict-dir)
    (set! pkd-relevant-words (read-words "PKD_relevant_words.txt"))
    (set! blog-relevant-words (read-words "blog_relevant_words.txt"))
    (State random-sentence-generator default-state)
    (set! has-markov-setup #t)
)

(define (call-random-sentence-generator dict-node)
    (if (not (or (equal? markov-bin "") (equal? markov-dict "") (null? rsg-input)))
        (begin-thread
            (State random-sentence-generator process-started)
            (let* ((dict (cog-name dict-node))
                   (cmd (string-append "ruby " markov-bin " speak -d " markov-dict
                        "/" dict " -c 1 -p \"" rsg-input "\""))
                   (port (open-input-pipe cmd))
                   (line (get-line port)))

                (if (eof-object? line)
                    (State random-sentence-generated no-result)
                    (State random-sentence-generated
                        (List (map Word (string-split line #\ ))))
                )

                (State random-sentence-generator process-finished)

                (close-pipe port)
            )
        )
    )
)
