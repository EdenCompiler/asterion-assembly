SBCL ?= sbcl
QUICKLISP := $(HOME)/quicklisp/setup.lisp

.PHONY: run test playtest build-linux package-linux smoke-package clean

run:
	$(SBCL) --script run.lisp

test:
	$(SBCL) --noinform --non-interactive --load $(QUICKLISP) \
	  --eval '(pushnew (uiop:getcwd) asdf:*central-registry* :test #'\''equal)' \
	  --eval '(ql:quickload :asterion-assembly/tests :silent t)' \
	  --eval '(asterion-tests:run-all)'

playtest:
	xvfb-run -a -s '-screen 0 1280x720x24' bash tests/virtual-menu-playtest.sh
	xvfb-run -a -s '-screen 0 1280x720x24' bash tests/virtual-playtest.sh

build-linux:
	mkdir -p dist/linux
	ASTERION_OUTPUT=dist/linux/asterion-assembly $(SBCL) --script build.lisp

package-linux: build-linux
	bash scripts/package-linux.sh

smoke-package: package-linux
	xvfb-run -a -s '-screen 0 1280x720x24' bash tests/package-smoke.sh

clean:
	rm -rf dist build
