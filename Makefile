# Makefile to help automate tasks in bookie
WD := $(shell pwd)
PY := bin/python
PEP8 := bin/pep8
PIP := bin/pip -q
PIP_MIR = PIP_FIND_LINKS='http://mypipi http://simple.crate.io/'
MIGRATE := bin/migrate
NOSE := bin/nosetests
PASTER := bin/paster
GUNICORN := bin/gunicorn
S3 := s3cp.py --bucket files.bmark.us --public

BOOKIE_INI = bookie.ini
SAURL = $(shell grep sqlalchemy.url $(BOOKIE_INI) | cut -d "=" -f 2 | tr -d " ")
BOOKIE_JS = bookie/static/js/bookie
BOOKIE_CSS = bookie/static/css
JS_BUILD_PATH = bookie/static/js/build
JS_META_SCRIPT = $(PY) scripts/js/generate_meta.py
YUIGIT = git://github.com/yui/yui3.git
YUITAG = v3.5.0pr2

EXTENSION = $(WD)/extensions/
CHROME = /usr/bin/google-chrome
CHROME_BUILD = $(EXTENSION)/chrome_ext/lib
CHROME_EXT_PATH = $(EXTENSION)/chrome_ext
CHROME_KEY = /home/rharding/.ssh/chrome_ext.pem
CHROME_FILESERVE = /home/bmark.us/www/bookie_chrome.crx
CHROME_BUILD_FILE = $(EXTENSION)/chrome_ext.crx
CHROME_DEV_FILE = $(EXTENSION)/chrome_ext.zip

RESCSS = bookie/static/css/responsive.css
BASECSS = bookie/static/css/base.css

.PHONY: all
all: deps develop bookie.db db_up js chrome_css

.PHONY: clean
clean: clean_js clean_css

.PHONY: clean_all
clean_all: clean_venv clean_js clean_css clean_chrome

install: $(BOOKIE_INI) all first_bookmark

develop: lib/python*/site-packages/bookie.egg-link
lib/python*/site-packages/bookie.egg-link:
	$(PY) setup.py develop

$(BOOKIE_INI):
	cp sample.ini $(BOOKIE_INI)

# DATABASE
#
# Need a series of commands to handle migrations
bookie.db:
	$(MIGRATE) version_control --url=$(SAURL) --repository=migrations

.PHONY: db_up
db_up: bookie.db
	$(MIGRATE) upgrade --url=$(SAURL) --repository=migrations

# make db_down ver=10
.PHONY: db_down
db_down: bookie.db
	$(MIGRATE) downgrade --url=$(SAURL) --repository=migrations $(ver)

# make db_new desc="This is a new migration"
.PHONY: db_new
db_new: bookie.db
	$(MIGRATE) script --url=$(SAURL) --repository=migrations "$(desc)"

.PHONY: first_bookmark
first_bookmark:
	$(PY) scripts/admin/first_bookmark.py

# DOCS
#
# docs are built from sphinx locally. They're hosted remotely using
# readthedocs.org though, so we don't need anything to upload/push them.

.PHONY: docs
docs:
	cd docs && make html

.PHONY: docs_upload
docs_open: docs
	xdg-open docs/_build/html/index.html

# Generate ctags for the code in the project
.PHONY: tags
tags:
	ctags --tag-relative --python-kinds=-iv -Rf tags-py --sort=yes --exclude=.git --languages=python

# BOOTSTRAP
#
# I don't know that we'll be using this much longer. I want to get things into
# the Makefile and more repeatable with clean/all setups.

.PHONY: bootstrap
bootstrap:
	scripts/bootstrap/gen_bootstrap.py > scripts/bootstrap/bootstrap.py

.PHONY: bootstrap_upload
bootstrap_upload: bootstrap
	cd scripts/bootstrap && $(S3) bootstrap.py

# DEPS
#
# Install the packages we need.

.PHONY: deps
deps: venv
	@echo "\n\nSilently installing packages (this will take a while)..."
	$(PIP_MIR) $(PIP) install -r requirements.txt

# TESTS
#
# Tools for running python and javascript tests

.PHONY: test
test:
	$(NOSE) --with-id -x -s bookie/tests
builder_test:
	# we hard code the filename because we don't want to accidentally remove
	# the main bookie.db file. We're only cleaning tests.
	if [ -f test_bookie.db ]; then \
		rm test_bookie.db; \
	fi
	$(MIGRATE) version_control --url=$(SAURL) --repository=migrations
	$(MIGRATE) upgrade --url=$(SAURL) --repository=migrations
	$(NOSE) --with-coverage --cover-package=bookie --cover-erase --with-xunit bookie/tests

mysql_test:
	# call this with the overriding BOOKIE_INI setting
	# first we need to drop the db
	$(PIP_MIR) $(PIP) install pymysql
	mysql -u jenkins_bookie --password=bookie -e "DROP DATABASE jenkins_bookie;"
	mysql -u jenkins_bookie --password=bookie -e "CREATE DATABASE jenkins_bookie;"
	$(MIGRATE) version_control --url=$(SAURL) --repository=migrations
	$(MIGRATE) upgrade --url=$(SAURL) --repository=migrations
	BOOKIE_TEST_INI=test_mysql.ini $(NOSE) --with-coverage --cover-package=bookie --cover-erase --with-xunit bookie/tests

.PHONY: jstest
jstest: test_api test_model test_view test_indicator test_tagcontrol
.PHONY: jstest_index
jstest_index:
	xdg-open http://127.0.0.1:6543/tests/index
.PHONY: test_api
test_api:
	xdg-open http://127.0.0.1:6543/tests/test_api
.PHONY: test_model
test_model:
	xdg-open http://127.0.0.1:6543/tests/test_model
.PHONY: test_view
test_view:
	xdg-open http://127.0.0.1:6543/tests/test_view
.PHONY: test_indicator
test_indicator:
	xdg-open http://127.0.0.1:6543/tests/test_indicator
.PHONY: test_tagcontrol
test_tagcontrol:
	xdg-open http://127.0.0.1:6543/tests/test_tagcontrol

.PHONY: pep8
pep8:
	$(PEP8) bookie/ > pep8.out

# JAVASCRIPT
#
# Javascript tools for building out combo loader build directory, out meta.js,
# and syncing things over to the chrome extension directory.

.PHONY: js
js: $(JS_BUILD_PATH)/b/meta.js $(JS_BUILD_PATH)/y

.PHONY: clean_js
clean_js:
	rm -rf $(JS_BUILD_PATH)/*
	rm -rf /tmp/yui
	rm $(CHROME_BUILD)/y*.js
	rm -rf jsdoc

$(JS_BUILD_PATH)/b/meta.js: $(JS_BUILD_PATH)/b/y*-min.js
	$(JS_META_SCRIPT) -n YUI_MODULES -s $(JS_BUILD_PATH)/b/ \
		-o $(JS_BUILD_PATH)/b/meta.js \
		-x -min.js$
$(JS_BUILD_PATH)/b/y%-min.js: $(JS_BUILD_PATH)/b $(JS_BUILD_PATH)/b/y%.js
	scripts/js/jsmin_all.py $(JS_BUILD_PATH)/b
$(JS_BUILD_PATH)/b/y%.js: $(BOOKIE_JS)/y%.js
	cp $? $(JS_BUILD_PATH)/b/
	cp $? $(CHROME_BUILD)
$(JS_BUILD_PATH)/b:
	mkdir -p $(JS_BUILD_PATH)/b
$(JS_BUILD_PATH)/y:
	mkdir -p $(JS_BUILD_PATH)/y
	mkdir /tmp/yui
	git clone --depth 1 $(YUIGIT) /tmp/yui
	cd /tmp/yui && git checkout $(YUITAG)
	cp -r /tmp/yui/build/* $(JS_BUILD_PATH)/y
	rm -rf /tmp/yui

static_upload: js css
	cd $(WD)/$(JS_BUILD_PATH)/b && tar cf $(WD)/bookie_static.tar *.js
	cd $(WD)/$(BOOKIE_CSS) && tar uf $(WD)/bookie_static.tar base.css
	cd $(WD)/bookie/static/images && tar uf $(WD)/bookie_static.tar *
	gzip $(WD)/bookie_static.tar
	cd $(WD) && $(S3) bookie_static.tar.gz
	rm $(WD)/bookie_static.tar.gz

js_doc: js
	rm $(JS_BUILD_PATH)/b/meta.js $(JS_BUILD_PATH)/b/*-min.js
	yuidoc -T simple -o jsdoc $(JS_BUILD_PATH)/b/
	sed -i 's/&#x2F;/\//g' jsdoc/**/*.html
	sed -i 's/&amp;#x2F;/\//g' jsdoc/**/*.html
js_doc_upload: js_doc
	scp -r jsdoc/* jsdoc jsdoc.bmark.us:/home/bmark.us/jsdocs/

css:
	sass --update bookie/static/css:bookie/static/css
chrome_css: css
	cp $(BASECSS) $(CHROME_BUILD)
	wget "https://bmark.us/combo?y/cssreset/reset-min.css&y/cssfonts/cssfonts-min.css&y/cssgrids/cssgrids-min.css&y/cssbase/cssbase-min.css&y/widget-base/assets/skins/sam/widget-base.css&y/autocomplete-list/assets/skins/sam/autocomplete-list.css" -O $(CHROME_BUILD)/combo.css
clean_css:
	rm $(BOOKIE_CSS)/*.css
	rm $(CHROME_BUILD)/*.css

# CHROME
#
# Helpers for dealing with the Chrome extension such as building the
# extension, copying it up to files.bmark.us, and such.

.PHONY: chrome_ext
chrome: clean_chrome
	$(CHROME) --pack-extension=$(CHROME_EXT_PATH) --pack-extension-key=$(CHROME_KEY)
	cd $(CHROME_EXT_PATH) && zip -r $(CHROME_DEV_FILE) .

chrome_upload: chrome
	cd $(EXTENSION) && $(S3) chrome_ext.crx

.PHONY: clean_chrome
clean_chrome:
	if [ -f $(CHROME_BUILD_FILE)]; then \
		rm $(CHROME_BUILD_FILE); \
	fi
	if [ -f $(CHROME_DEV_FILE)]; then \
		rm $(CHROME_DEV_FILE); \
	fi


run: run_combo run_app
run_dev: run run_css autojsbuild
run_combo:
	$(GUNICORN) -p combo.pid combo:application &
run_css:
	sass --watch bookie/static/css:bookie/static/css &
run_app:
	$(PASTER) serve --reload --pid-file=paster.pid $(BOOKIE_INI) &
run_livereload:
	livereload
autojsbuild:
	$(PY) scripts/js/autojsbuild.py -w $(BOOKIE_JS) -b $(JS_BUILD_PATH)/b

stop: stop_combo stop_app
stop_dev: stop stop_css
stop_combo:
	kill -9 `cat combo.pid`
	rm combo.pid
stop_css:
	killall -9 sass
stop_app:
	kill -9 `cat paster.pid`
	rm paster.pid
stop_livereload:
	killall livereload


# INSTALL
#
# Crap to help us install and setup Bookie
# We need a virtualenv

venv: bin/python
bin/python:
	virtualenv .

.PHONY: clean_venv
clean_venv:
	rm -rf lib include local bin

.PHONY: clean clean_js $(JS_BUILD_PATH)/b/meta.js autojsbuild js_doc js_doc_upload\
	run run_dev run_combo run_css run_app run_livereload \
	stop stop_dev stop_app stop_css stop_combo stop_livereload \
	css chrome_css clean_css
