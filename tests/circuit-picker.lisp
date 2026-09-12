;;;; Seletor visual de sinais: filtros, paginação e aplicação segura.
(in-package #:asterion-tests)

(defun teste-seletor-visual-sinais ()
  (preparar)
  (let* ((w (asterion-assembly:new-game :difficulty :peaceful))
         (sensor (place-building w :circuit-sensor 20 0))
         (combinador (place-building w :arithmetic-combinator 21 0))
         (decisor (place-building w :decider-combinator 22 0))
         (asterion-assembly::*tela-ui* :playing)
         (asterion-assembly::*modo-circuito* t)
         (asterion-assembly::*predio-circuito-selecionado* sensor)
         (asterion-assembly::*pausa-antes-seletor* nil))
    (unwind-protect
         (progn
           (verificar (asterion-assembly::abrir-seletor-sinal sensor :output))
           (verificar (eq asterion-assembly::*tela-ui* :circuit-signals))
           (verificar (paused-p))
           (verificar (> (length asterion-assembly::*opcoes-seletor-sinal*) 70))
           (dolist (categoria '(:item :fluid :virtual))
             (asterion-assembly::filtrar-seletor-sinal categoria)
             (verificar (plusp (length (asterion-assembly::sinais-filtrados-seletor))))
             (verificar (every (lambda (s) (and (consp s) (eq (first s) categoria)))
                               (asterion-assembly::sinais-filtrados-seletor))))
           (asterion-assembly::filtrar-seletor-sinal :special)
           (verificar (zerop (length (asterion-assembly::sinais-filtrados-seletor))))
           (asterion-assembly::fechar-seletor-sinal)
           (verificar (eq asterion-assembly::*tela-ui* :playing))
           (verificar (not (paused-p)))

           ;; O combinador expõe os sinais especiais somente nos campos válidos.
           (asterion-assembly::abrir-seletor-sinal decisor :left)
           (verificar (find :anything asterion-assembly::*opcoes-seletor-sinal*))
           (verificar (find :everything asterion-assembly::*opcoes-seletor-sinal*))
           (asterion-assembly::filtrar-seletor-sinal :special)
           (verificar (= 3 (length (asterion-assembly::sinais-filtrados-seletor))))
           (setf asterion-assembly::*indice-seletor-sinal*
                 (position :anything (asterion-assembly::sinais-filtrados-seletor)))
           (asterion-assembly::aplicar-sinal-escolhido w)
           (verificar (eq :anything
                          (circuit-condition-left
                           (circuit-device-config-condition
                            (asterion-assembly::configuracao-circuito-padrao decisor)))))

           ;; O aritmético aceita EACH como entrada sem oferecer especiais inválidos.
           (asterion-assembly::abrir-seletor-sinal combinador :input)
           (asterion-assembly::filtrar-seletor-sinal :special)
           (verificar (= 1 (length (asterion-assembly::sinais-filtrados-seletor))))
           (verificar (eq :each (aref (asterion-assembly::sinais-filtrados-seletor) 0)))
           (asterion-assembly::aplicar-sinal-escolhido w)
           (verificar (eq :each
                          (circuit-device-config-input-signal
                           (asterion-assembly::configuracao-circuito-padrao combinador))))

           ;; Seleção de um item pelo mesmo caminho usado por mouse/gamepad.
           (asterion-assembly::abrir-seletor-sinal sensor :output)
           (asterion-assembly::filtrar-seletor-sinal :item)
           (setf asterion-assembly::*indice-seletor-sinal*
                 (position '(:item :iron-ore) (asterion-assembly::sinais-filtrados-seletor) :test #'equal))
           (asterion-assembly::entrada-seletor-sinal w :controller-down '(0))
           (verificar (equal '(:item :iron-ore)
                             (circuit-device-config-output-signal
                              (asterion-assembly::configuracao-circuito-padrao sensor))))

           ;; A opção nil troca comparação por sinal de volta para constante.
           (asterion-assembly::abrir-seletor-sinal decisor :right)
           (verificar (null (aref asterion-assembly::*opcoes-seletor-sinal* 0)))
           (setf asterion-assembly::*indice-seletor-sinal* 0)
           (asterion-assembly::aplicar-sinal-escolhido w)
           (verificar (null (circuit-condition-right
                            (circuit-device-config-condition
                             (asterion-assembly::configuracao-circuito-padrao decisor)))))

           ;; Remover o alvo enquanto o modal está aberto não grava configuração.
           (asterion-assembly::abrir-seletor-sinal sensor :output)
           (remove-building w (building-id sensor))
           (asterion-assembly::aplicar-sinal-escolhido w)
           (verificar (eq asterion-assembly::*tela-ui* :circuit-signals))
           (verificar (plusp (length asterion-assembly::*mensagem-menu*))))
      (when (eq asterion-assembly::*tela-ui* :circuit-signals)
        (asterion-assembly::fechar-seletor-sinal))
      (when (paused-p) (toggle-pause)))))
