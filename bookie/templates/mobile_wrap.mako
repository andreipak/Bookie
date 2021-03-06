<html>
    <head>
        <meta http-equiv="X-UA-Compatible" content="IE=8" />
        <title>Bookie: ${self.title()}</title>
        <meta name="viewport" content="width=device-width, minimum-scale=1, maximum-scale=1">
        <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />

        <link rel="stylesheet" href="http://code.jquery.com/mobile/1.0b1/jquery.mobile-1.0b1.min.css" />
        <link rel="apple-touch-icon" href="/static/images/logo.128.png" />

        <script src="http://code.jquery.com/jquery-1.6.1.min.js"></script>
        <script type="text/javascript">
            // prepare for the great bookie js files
            var logger = {}
            logger.log = function(msg) {
                console.log(msg);
            };

            var bookie_opts = {
                'bookie': typeof(bookie) !== 'undefined' ? bookie : {},
                'jquery': $,
                'console_log': logger
            }
        </script>

        % if hasattr(self, 'header'):
            ${self.header()}
        % endif

        <script type="text/javascript" charset="utf-8">
            <%
                app_url = request.route_url('home').rstrip('/')
                app_url = app_url + "/" + username
            %>
            APP_URL = '${app_url}';
        </script>
    </head>

    <body class="ui-mobile-viewport">
        ${next.body()}
    </body>

    <script type="text/javascript" src="/static/js/bookie.api.js"></script>
    <script type="text/javascript" src="/static/js/mobile.js"></script>
    <script type="text/javascript">

        $(document).bind("mobileinit", function() {
            // do not do form submissions via ajax by default. We catch and
            // override them to handle things manually
            $.mobile.ajaxFormsEnabled = false;
            bookie.init();
        });

        $(document).bind("ready", function() {
            if (!bookie.initialized) {
                bookie.pc.manual(bookie.pages.home);
            }
        });

    </script>
    <!--<script src="http://code.jquery.com/mobile/latest/jquery.mobile.js"></script>-->
    <script src="http://code.jquery.com/mobile/1.0b1/jquery.mobile-1.0b1.js"></script>
    <script src="http://ajax.aspnetcdn.com/ajax/jquery.templates/beta1/jquery.tmpl.min.js"></script>
</html>
