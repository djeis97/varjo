(in-package :vari.cl)
(in-readtable fn:fn-reader)

;;------------------------------------------------------------
;; Geometry

;; points
;; line-strip
;; triangle-strip

(def-metadata-kind output-primitive (:binds-to :scope)
  kind
  max-vertices)

;;------------------------------------------------------------
;; Tessellation Control

(def-metadata-kind output-patch (:binds-to :scope)
  vertices)

;;------------------------------------------------------------
;; Tessellation Evaluation

(def-metadata-kind tessellate-to (:binds-to :scope)
  primitive
  spacing
  order)

;;------------------------------------------------------------
;; Compute

(def-metadata-kind local-size (:binds-to :scope)
  x
  y
  z)

;;------------------------------------------------------------
;; emit

(v-defspecial emit-data (&optional (form '(values)))
  :args-valid t
  :return
  (let ((new-env (fresh-environment
                  env :multi-val-base *emit-var-name-base*)))
    ;; we create an environment with the signal to let any 'values' forms
    ;; down the tree know they will be caught and what their name prefix should
    ;; be.
    ;; If you make changes here, look at #'emit to see if it needs
    ;; similar changes
    (vbind (code-obj final-env) (compile-form form new-env)
      ;; emit-set can be nil when there was no 'values' form within emit-data
      (if (emit-set code-obj)
          (let ((ast (ast-node! 'emit-data
                                (node-tree code-obj)
                                (make-type-set)
                                env env)))
            (values (copy-compiled code-obj
                                   :type-set (make-type-set)
                                   :node-tree ast)
                    final-env))
          (let* ((qualifiers (extract-value-qualifiers code-obj))
                 (parsed (mapcar #'parse-qualifier qualifiers)))
            (%values-for-emit (list code-obj)
                              (list qualifiers)
                              (list parsed)
                              final-env))))))

;;------------------------------------------------------------

(v-defmacro emit ((&key point-size) position &rest data)
  `(progn
     ,@(when point-size `((setf gl-point-size ,point-size)))
     (setf gl-position ,position)
     ,@(when data `((emit-data (values ,@data))))
     (emit-vertex)))
