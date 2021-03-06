=================
Installing Bookie
=================

The short version
==================
This assumes you're on Ubuntu or can figure out the difference between Ubuntu
and your distro for the following:

::

    $ sudo apt-get install build-essential libxslt1-dev libxml2-dev python-dev git python-virtualenv
    $ git clone https://mitechie@github.com/mitechie/Bookie.git && cd Bookie && make install
    # THIS WILL TAKE A WHILE, GET A COFFEE
    $ make run
    $ (YOUR BROWSER) http://127.0.0.1:6543/

Where to go from here
~~~~~~~~~~~~~~~~~~~~~~~

Getting your bookmarks into Bookie
-----------------------------------
Well, you might want to import a backup of your delicious bookmarks. You can do
that by vising the *Import* link in the footer of your site installation. Make
sure you know the API key that you've set in your bookie install's *.ini*
configuration file.

You can view your recent bookmarks at: http://127.0.0.1:6543/recent

Installing Extension
---------------------
You probably also want to install a `browser extension`_ to be able to store
new bookmarks going forward. Once you install the extension, you'll need to set
the options for it to work. See the `browser extension`_ docs for those
settings.

Hosting Bookie
---------------
You can setup Bookie to run in a variety of ways. Make sure to check out some
samples in the `hosting docs`_

More details than you can shake a stick at
===========================================

OS Packages
~~~~~~~~~~~~
There are some required packages that need to be installed so you can build bookie. These are:

- build-essential
- python-dev
- libxslt1-dev
- libxml2-dev
- git

::

    # install the required packages to build bookie
    $ sudo apt-get install build-essential libxslt1-dev libxml2-dev python-dev git


Note: right we we support three databases - mysql, postgres, and sqlite - and the database bindings need to be built into the virtualenv. Out of the box, Bookie will setup a Sqlite version for you to get started with.


MySQL & Postgresql Users
~~~~~~~~~~~~~~~~~~~~~~~~
If you're using Postgres or MySQL as your database for Bookie you'll also want
to grab the dev package for your db so that the Python drivers for them can
compile.

- libmysqlclient-dev
- postgresql-server-dev-8.4

::

    $ sudo apt-get install postgresql-server-dev-8.4
    - OR -
    $ sudo apt-get install libmysqlclient-dev

Then you'll need to update the database connection string in your `bookie.ini`
file. The database and user account need to exist in order for it to bootstrap
the database for you. Once you're ready run:

::

    $ make db_up

.. _`browser extension`: extensions.html
.. _`hosting docs`: hosting.html
