"""Test the fulltext implementation"""
import logging
import os
import transaction
import urllib

from nose.tools import ok_
from pyramid import testing
from unittest import TestCase

from bookie.lib.readable import ReadContent
from bookie.lib.readable import ReadUrl

from bookie.models import DBSession
from bookie.models import Bmark
from bookie.models import Hashed
from bookie.models import Tag
from bookie.models import Readable
from bookie.models import bmarks_tags


LOG = logging.getLogger(__file__)
API_KEY = None


class TestReadable(TestCase):
    """Test that our fulltext classes function"""

    def test_url_content(self):
        """Test that we set the correct status"""

        url = 'http://lococast.net/archives/475'
        read = ReadUrl.parse(url)

        ok_(read.status == 200, "The status is 200" + str(read.status))
        ok_(not read.is_image(), "The content is not an image")
        ok_(read.content is not None, "Content should not be none")
        ok_('Lococast' in read.content,
                "The word Lococast is in the content: " + str(read.content))

    def test_404_url(self):
        """Test that we get the proper errors in a missing url"""
        url = 'http://lococast.net/archives/001'
        read = ReadUrl.parse(url)

        ok_(read.status == 404, "The status is 404: " + str(read.status))
        ok_(not read.is_image(), "The content is not an image")
        ok_(read.content is None, "Content should be none")

    def test_given_content(self):
        """Test that we can parse out given html content ahead of time"""

        file_path = os.path.dirname(__file__)
        html_content = open(os.path.join(file_path, 'readable_sample.html'))

        read = ReadContent.parse(html_content)

        ok_(read.status == 1, "The status is 1: " + str(read.status))
        ok_(not read.is_image(), "The content is not an image")
        ok_(read.content is not None, "Content should not be none")
        ok_('Bookie' in read.content,
                u"The word Bookie is in the content: " + unicode(read.content))

    def test_non_net_url(self):
        """I might be bookmarking something internal bookie can't access"""
        test_url = "http://r2"
        read = ReadUrl.parse(test_url)

        ok_(read.status == 901, "The status is 901: " + str(read.status))
        ok_(not read.is_image(), "The content is not an image")
        ok_(read.content is None,
            "Content should be none: " + str(read.content))

    def test_image_url(self):
        """Verify we don't store, but just tag an image url"""
        img_url = 'http://www.ndftz.com/nickelanddime.png'
        read = ReadUrl.parse(img_url)

        ok_(read.status == 200, "The status is 200: " + str(read.status))
        ok_(read.content is None, "Content should be none: ")

    def test_nonworking_url(self):
        """Testing some urls we know we had issues with initially"""
        urls = {'CouchSurfing': ('http://allthatiswrong.wordpress.com/2010/01'
                                 '/24/a-criticism-of-couchsurfing-and-review-o'
                                 'f-alternatives/#problems'),
                 'Electronic': ('https://www.fbo.gov/index?s=opportunity&mode='
                                'form&tab=core&id=dd11f27254c796f80f2aadcbe415'
                                '8407'),
                 'Will Fuqua': 'http://twitter.com/#!/wafuqua',
        }

        for key, url in urls.iteritems():
            LOG.debug(url)
            read = ReadUrl.parse(url)
            LOG.debug(read)

            ok_(read.status == 200, "The status is 200: " + str(read.status))
            ok_(read.content is not None, "Content should not be none: ")


class TestReadableFulltext(TestCase):
    """Test that our fulltext index function"""

    def setUp(self):
        """Setup Tests"""
        from pyramid.paster import get_app
        from bookie.tests import BOOKIE_TEST_INI
        app = get_app(BOOKIE_TEST_INI, 'main')
        from webtest import TestApp
        self.testapp = TestApp(app)
        testing.setUp()
        global API_KEY
        if API_KEY is None:
            res = DBSession.execute(
                "SELECT api_key FROM users WHERE username = 'admin'").\
                fetchone()
            API_KEY = res['api_key']

    def tearDown(self):
        """Tear down each test"""
        testing.tearDown()
        session = DBSession()
        Bmark.query.delete()
        Tag.query.delete()
        Readable.query.delete()
        Hashed.query.delete()
        session.execute(bmarks_tags.delete())
        session.flush()
        transaction.commit()

    def _get_good_request(self):
        """Return the basics for a good add bookmark request"""
        session = DBSession()
        prms = {
                'url': u'http://google.com',
                'description': u'This is my google desc',
                'extended': u'And some extended notes about it in full form',
                'tags': u'python search',
                'api_key': API_KEY,
                'content': 'bmark content is the best kind of content man',
        }

        req_params = urllib.urlencode(prms)
        res = self.testapp.post('/api/v1/admin/bmark',
                               params=req_params)
        session.flush()
        transaction.commit()
        return res

    def test_sqlite_save(self):
        """Verify that if we store a bookmark we get the fulltext storage"""
        # first let's add a bookmark we can search on
        self._get_good_request()

        search_res = self.testapp.get(
            '/api/v1/admin/bmarks/search/bmark?search_content=True')

        ok_(search_res.status == '200 OK',
            "Status is 200: " + search_res.status)
        ok_('python' in search_res.body,
            "We should find the python tag in the results: " + search_res.body)

    def test_restlike_search(self):
        """Verify that our search still works in a restful url method"""
        # first let's add a bookmark we can search on
        self._get_good_request()

        search_res = self.testapp.get(
            '/api/v1/admin/bmarks/search/bmark?search_content=True')

        ok_(search_res.status == '200 OK',
            "Status is 200: " + search_res.status)
        ok_('python' in search_res.body,
            "We should find the python tag in the results: " + search_res.body)
