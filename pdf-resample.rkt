#! /usr/bin/env racket
#lang racket/base

(provide pdf-length resample-pdf)

(require racket/system)
(require racket/file)
(require racket/port)
(require srfi/13)
(require racket/date)

(define RESOLUTION
  (make-parameter
   "150"))
(define DEPTH
  (make-parameter
   "2"))
(define RGB-COLORSPACE
  (make-parameter #t))
(define BW
  (make-parameter #t))

(define CONVERT
  (make-parameter
   "/usr/local/bin/convert"))
(define EXIFTOOL
  (make-parameter
   "/usr/local/bin/exiftool"))
(define DELETE-TMP
  (make-parameter #t))

(define (convert-args-pre)
  `("-density"
    ,(RESOLUTION)))

(define (convert-args)
  (cond
    [(BW)
     `("-monochrome")]
    [(RGB-COLORSPACE)
     `("-depth" ,(DEPTH) "-colorspace" "RGB")]
    [else
     `("-depth" ,(DEPTH) "-colorspace" "Gray")]))


(define (pdf-length filename)
  (let* ([output 
          (with-output-to-string
            (lambda ()
              (system* (EXIFTOOL) filename)))]
         [match
             (regexp-match
              #rx"Page Count +: +([0-9]+)" 
              output)])
    (if (and match (string? (cadr match)))
        (string->number (cadr match))
        0)))


(define (generate-output-img-from-tmp filepath)
  (string-append-immutable
   (path->string filepath)
   "-%05d.png"))


(define (generate-list-of-imgs-from-tmp filepath len)
  (let ([prefix (path->string filepath)])
    ;; (: iter (-> (Listof String) Number (Listof String)))
    (let loop ([acc '()]
               [i len])
      (if (< i 1)
          acc
          (loop (cons 
                 (string-append-immutable
                  prefix
                  "-"
                  (string-pad
                   (number->string (- i 1))
                   5
                   #\0)
                  ".png")
                 acc)
                (- i 1))))))
  

(define (resample-pdf filename-in filename-out)
  (let* ([plen (pdf-length filename-in)]
         [tmpfile
          (make-temporary-file
           "tmp-resample-~a"
           #f
           (current-directory))]
         [tmpfileprefix (generate-output-img-from-tmp tmpfile)]
         [filelist (generate-list-of-imgs-from-tmp
                    tmpfile
                    plen)])
    (begin
      (delete-file tmpfile)
      (displayln (string-append "Processing "
                                (number->string plen)
                                " pages ...."))
      (and (apply
            system*
            `(,(CONVERT)
              ,@(convert-args-pre)
              ,filename-in
              ,@(convert-args)
              ,tmpfileprefix))
           (apply
            system*
            `(,(CONVERT)
              ,@filelist
              ,filename-out))
           (begin
             (when (DELETE-TMP)
               (map (lambda (x)
                      (delete-directory/files
                       (string->path x)))
                    filelist))
             #t)))))

(module+ main
  (require racket/cmdline)
  (define *help* (make-parameter #f))
  (command-line
   #:program "pdf-resample.rkt"
   #:usage-help
   "uses imagemagick to resample a given PDF <infile> into PDF <outfile>"
   ""
   #:help-labels
   ""
   "basic flags"
   #:once-each
   [("--preserve" "-p")
    "Preserve temporary files"
    (DELETE-TMP #f)]
   #:help-labels
   ""
   "customization arguments"
   #:once-each
   [("--resolution" "-r")
    num
    ("density of the resulting images"
     (string-append
      "default: "
      (RESOLUTION)))
    (RESOLUTION num)]
   [("--depth" "-d")
    num
    ("depth of the resulting images"
     (string-append
      "default: "
      (DEPTH)))
    (DEPTH num)]
   [("--exiftool" "-e")
    path
    ("path to `exiftool`"
     (string-append
      "default: "
      (EXIFTOOL)))
    (EXIFTOOL path)]
   [("--convert" "-c")
    path
    ("path to `convert`"
     (string-append
      "default: "
      (CONVERT)))
    (CONVERT path)]
   #:help-labels
   ""
   "color-control options"
   #:once-any
   [("--rgb")
    "RGB colorspace (default)"
    (RGB-COLORSPACE #t)]
   [("--bw")
    "Black and white (overrides depth setting)"
    (BW #t)]
   [("--gray")
    "Gray colorspace"
    (RGB-COLORSPACE #f)]
   #:help-labels ""
   #:ps ""
   "This tool is useful for the following:"
   "* proper redaction of text PDFs"
   "* changing the filesize of over-sized image PDFs"
   ""
   "Remember to increase the resolution (to 200 or higher) for OCR."
   #:args (infile outfile)
   (begin
     (displayln (string-append "re-sample:\n"
                               "Starting at "
                               (parameterize
                                   ([date-display-format 'iso-8601])
                                 (date->string (current-date) #t))
                               "\n"
                               "  From: `"
                               infile
                               "`\n"
                               "  To:   `"
                               outfile
                               "`"))
     (if (resample-pdf infile outfile)
         (displayln "re-sample: Success.")
         (displayln "re-sample: Failure."))
     (displayln (string-append "Complete at "
                               (parameterize
                                   ([date-display-format 'iso-8601])
                                 (date->string (current-date) #t)))))))
 
