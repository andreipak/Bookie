Bookie
========
:Main Site: https://bmark.us
:Docs: http://docs.bmark.us
:Mailing List: https://groups.google.com/forum/?hl=en#!forum/bookie_bookmarks
:Twitter: http://twitter.com/BoookieBmarks

Bookie will one day be a self-hosted bookmark web-service similar to
Delicious.

Check out the main site for documentation on features, how to get started
installing, and where we're heading from here.

You can check out the Trello board to see what stuff is in the works atm and
what the status of your favorite pet feature is:

https://trello.com/board/bookie/4f18c1ac96c79ec27105f228

Quick Start
-----------
If you're on Ubuntu, you should be able to get started with:

::

    $ sudo apt-get install build-essential libxslt1-dev libxml2-dev python-dev git python-virtualenv
    $ git clone git@github.com:mitechie/Bookie.git && cd Bookie && make install && make run
    $ google-chrome (or other browser) http://127.0.0.1:6543
