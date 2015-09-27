;;
;; March 21 2015, Christian Hopps <chopps@gmail.com>
;;
;; Copyright (c) 2015 by Christian E. Hopps
;; All rights reserved.
;;
;;; Commentary:
;;
;; Functions supporting fetching, caching and opening the IETF
;; document referenced by the text at the point.
;;
;;; Code:

;; Suggested binding: C-c i o
;; (global-set-key (kbd "C-c i o") 'ietf-docs-open-at-point)

(require 'thingatpt)

(defgroup  ietf-docs nil
   "Customizable variables for ietf-docs functions")

(defcustom ietf-docs-cache-directory (expand-file-name "~/ietf-docs-cache")
  "Local directory to store downloaded IETF documents. Created if necessary."
  :type 'directory
  :group 'ietf-docs)

(defcustom ietf-docs-draft-url-directory "http://tools.ietf.org/id/"
  "The base URL to fetch IETF drafts from."
  :type 'string
  :group 'ietf-docs)

(defcustom ietf-docs-rfc-url-directory "http://tools.ietf.org/rfc/"
  "The base URL to fetch IETF RFCs from."
  :type 'string
  :group 'ietf-docs)

;; RFC-3999
;; RFC 1222
;; rfc 1029  
;; RFC5999 
;; RFC 4999
;; draft-ietf-isis-01.txt  
;; draft-ietf-isis-03.xml  
;; draft-ietf-isis-02

;--------------------------------------------------
; Define a thing-at-point for draft and RFC names.
;--------------------------------------------------

(defvar ietf-draft-or-rfc-regexp "\\(\\(RFC\\|rfc\\)\\(-\\| \\)?[0-9]+\\)\\|\\(draft-[-[:alnum:]]+\\(.txt\\|.html\\|.xml\\)?\\)")

(put 'ietf-docs-name 'bounds-of-thing-at-point 'thing-at-point-bounds-of-ietf-name-at-point)
(defun thing-at-point-bounds-of-ietf-name-at-point ()
  (if (thing-at-point-looking-at ietf-draft-or-rfc-regexp)
      (let ((beginning (match-beginning 0))
            (end (match-end 0))))
    (cons beginning end)))

(put 'ietf-docs-name 'thing-at-point 'thing-at-point-ietf-name-at-point)
(defun thing-at-point-ietf-name-at-point ()
  "Return the ietf document name around or before point."
  (let ((name ""))
    (if (thing-at-point-looking-at ietf-draft-or-rfc-regexp)
        (progn
          (setq name (buffer-substring-no-properties (match-beginning 0)
                                                     (match-end 0)))
          (if (string-match "\\(?:RFC\\|rfc\\)\\(?:[ ]+\\|-\\)?\\([0-9]+\\)" name)
              (setq name (concat "rfc" (match-string 1 name))))
          (if (string-match "draft-\\([-[:alnum:]]+\\)\\(?:.txt\\|.html\\|.xml\\)" name)
              (setq name (concat "draft-" (match-string 1 name))))
          name))))

(put 'ietf-docs-name 'end-op
     (function (lambda ()
		 (let ((bounds (thing-at-point-bounds-of-ietf-name-at-point)))
		   (if bounds
		       (goto-char (cdr bounds))
		     (error "No IETF document name here"))))))

(put 'ietf-docs-name 'beginning-op
     (function (lambda ()
		 (let ((bounds (thing-at-point-bounds-of-ietf-name-at-point)))
		   (if bounds
		       (goto-char (car bounds))
		     (error "No IETF document name here"))))))

(global-set-key (kbd "C-c i t") 'get-thing-at-pt)

(defun ietf-docs-starts-with (string prefix)
  "Return t if STRING starts with prefix."
  (let* ((l (length prefix)))
    (string= (substring string 0 l) prefix)))

(defun ietf-docs-at-point ()
  (interactive)
  (concat (file-name-sans-extension (file-name-base (thing-at-point 'ietf-docs-name))) ".txt"))

(defun ietf-docs-normalize-filename (filename)
  (concat (file-name-sans-extension (downcase filename)) ".txt"))

(defun ietf-docs-fetch-to-cache (filename &optional reload)
  (let* ((pathname (concat ietf-docs-cache-directory (downcase filename)))
         url)
    (if (and (file-exists-p pathname) (not reload))
        (message "Cached path %s" pathname)
      (setq filename (downcase filename))
      (make-directory ietf-docs-cache-directory t)
      (if (ietf-docs-starts-with filename "rfc")
          (setq url (concat ietf-docs-rfc-url-directory filename))
        (setq url (concat ietf-docs-draft-url-directory filename)))
      (message url)
      (url-copy-file url pathname t)
      (message "Downloading %s to %s" url pathname)
      pathname)
    pathname))

(defun ietf-docs-at-point-fetch-to-cache (&optional reload)
  (interactive "P")
  (ietf-docs-fetch-to-cache (ietf-docs-at-point) reload))

(defun ietf-docs-open-at-point (&optional reload)
  "Open the IETF internet-draft or RFC indicated by the point. Reload
  the cache if C-u prefix is specified"
  (interactive "P")
  (let ((pathname (ietf-docs-at-point-fetch-to-cache reload)))
    (find-file pathname)))

(provide 'ietf-docs)
;;; ietf-docs.el ends here