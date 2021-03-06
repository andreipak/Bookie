from sqlalchemy import *
from migrate import *


def for_sqlite(engine):
    """Add the table structure for sqlite db"""
    sql = """CREATE VIRTUAL TABLE fulltext USING fts3(bid, description, extended, tag_string);"""
    engine.execute(sql)


def drop_sqlite(engine):
    """The downgrade method for sqlite"""
    sql = """DROP TABLE fulltext"""
    engine.execute(sql)


def for_mysql(engine):
    """Add the table structure for mysql db"""
    # add the fulltext index
    ft_index = """ALTER TABLE  `bmarks`
                      ADD FULLTEXT `fulltext`
                        (`description` , `extended`, `tag_str`);
    """
    engine.execute(ft_index)


def drop_mysql(engine):
    """The downgrade method for mysql"""
    engine.execute("ALTER TABLE bmarks DROP INDEX `fulltext`;")


def for_pgsql(engine):
    """Postgres we're going to start with the slowest, but easiest option"""
    idx_sql = [
        "CREATE INDEX desc_ftidx ON bmarks USING gin(to_tsvector('english', description));",
        "CREATE INDEX ext_ftidx ON bmarks USING gin(to_tsvector('english', extended));",
        "CREATE INDEX tag_ftidx ON bmarks USING gin(to_tsvector('english', tag_str));",
    ]

    for sql in idx_sql:
        engine.execute(sql)


def drop_pgsql(engine):
    """Postgres, drop the indexes in question"""
    engine.execute("ALTER TABLE bmarks DROP INDEX desc_ftidx;")
    engine.execute("ALTER TABLE bmarks DROP INDEX tag_ftidx;")


def upgrade(migrate_engine):
    """Right now this is sqlite specific

    Eventually we'll need to detect the db type based on the engine and call
    the correct method to add the right table structure.

    The idea is to allow searching on the desc, extended, tags (as words)

    I would like to do the url as well, but not sure how to tokenize it.
    e.g. engadget would come up with a search for gadget

    """

    # add the tag_str column for everyone, who cares
    meta = MetaData(migrate_engine)
    bmarks = Table('bmarks', meta, autoload=True)

    tag_str = Column('tag_str', UnicodeText())
    tag_str.create(bmarks)

    # now do some db specific modifications for how they support fulltext 
    if 'sqlite' in migrate_engine.dialect.driver.lower():
        for_sqlite(migrate_engine)

    elif 'mysql' in migrate_engine.dialect.driver.lower():
        for_mysql(migrate_engine)

    elif 'pg' in migrate_engine.dialect.driver.lower():
        # currently psycopg2
        for_pgsql(migrate_engine)


def downgrade(migrate_engine):
    """And destroy the tables created"""
    meta = MetaData(migrate_engine)
    bmarks = Table('bmarks', meta, autoload=True)
    tag_str = Column('tag_str', UnicodeText())

    bmarks.drop_column(tag_str)

    if 'sqlite' in migrate_engine.dialect.driver.lower():
        drop_sqlite(migrate_engine)

    elif 'mysql' in migrate_engine.dialect.driver.lower():
        drop_mysql(migrate_engine)

    elif 'pg' in migrate_engine.dialect.driver.lower():
        drop_pgsql(migrate_engine)
