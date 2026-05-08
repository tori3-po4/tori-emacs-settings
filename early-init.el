;;; early-init.el --- 起動前の最小限設定 -*- lexical-binding: t; -*-

;; 起動中は GC をほぼ無効化し、init.el 評価中の GC ストールを抑える。
;; emacs-startup-hook で常用値 (16MB / 0.1) に戻すので runtime のフットプリントは増えない。
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; init.el 側で (require 'package) と (package-initialize) を明示的に呼ぶため、
;; Emacs 27+ の自動パッケージ初期化を抑止して二重実行を防ぐ。
(setq package-enable-at-startup nil)

;; 起動高速化:フレームの暗黙リサイズ抑止 / フォントキャッシュ過剰圧縮の回避
(setq frame-inhibit-implied-resize t)
(setq inhibit-compacting-font-caches t)

;; 起動完了後に常用 GC 値へ戻す。
;; これにより、タイピング・スクロール時の GC 起因の小さなフリーズが大幅に減る。
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024)
                  gc-cons-percentage 0.1)))

;;; early-init.el ends here
