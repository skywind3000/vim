(global-set-key [M-left] 'windmove-left)
(global-set-key [M-right] 'windmove-right)
(global-set-key [M-up] 'windmove-up)
(global-set-key [M-down] 'windmove-down)

(global-set-key [f5] 'gud-run)
(global-set-key [S-f5] 'gud-cont)
(global-set-key [f6] 'gud-jump)
(global-set-key [S-f6] 'gud-print)
(global-set-key [f7] 'gud-step)
(global-set-key [f8] 'gud-next)
(global-set-key [S-f7] 'gud-stepi)
(global-set-key [S-f8] 'gud-nexti)
(global-set-key [f9] 'gud-break)
(global-set-key [S-f9] 'gud-remove)
(global-set-key [f10] 'gud-until)
(global-set-key [S-f10] 'gud-finish)

(global-set-key [f4] 'gud-up)
(global-set-key [S-f4] 'gud-down)


(setq gdb-many-windows t)


(require 'xt-mouse)
(xterm-mouse-mode)
(require 'mouse)
(xterm-mouse-mode t)
(defun track-mouse (e))

(setq mouse-wheel-follow-mouse 't)

(defvar alternating-scroll-down-next t)
(defvar alternating-scroll-up-next t)

(defun alternating-scroll-down-line ()
  (interactive "@")
    (when alternating-scroll-down-next
      (scroll-down-line))
    (setq alternating-scroll-down-next (not alternating-scroll-down-next)))

(defun alternating-scroll-up-line ()
  (interactive "@")
    (when alternating-scroll-up-next
      (scroll-up-line))
    (setq alternating-scroll-up-next (not alternating-scroll-up-next)))

(global-set-key (kbd "<mouse-4>") 'alternating-scroll-down-line)
(global-set-key (kbd "<mouse-5>") 'alternating-scroll-up-line)



