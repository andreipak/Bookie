<%inherit file="/main_wrap.mako" />
<%def name="title()">Import Bookmarks</%def>
<%namespace file="../accounts/func.mako" import="account_nav"/>

${account_nav()}


<div class="yui3-g">
    <div class="yui3-u-3-4">



        <div class="block">
            <div class="head"></div>
            <div class="body">
                <div class="form">

                    <div class="heading">Import Bookmarks</div>
                    <form class="" action="${request.route_url('user_import',
                                                                username=request.user.username)}"
                        method="POST" enctype=multipart/form-data>
                        <fieldset>
                            <ul>
                                <li>
                                    <label for="import_file">Import File</label>
                                    <input type="file" name="import_file" id="import_file" />
                                </li>
                                <li>
                                    <label>&nbsp;</label>
                                    <input type="submit" name="upload" value="Upload" id="upload" class="button" />
                                </li>
                            </ul>
                        </fieldset>

                        % if error:
                            <div class="error">
                                % for err in error:
                                    ${err}
                                % endfor
                            </div>
                        % endif
                    </form>
                </div>
            </div>
            <div class="head"></div>
        </div>
    </div>
    <div class="yui3-u-1-4">
        <div class="note">
            <p>Use the <em>Import Bookmarks</em> tool to import your bookmarks from Delicious 
            or Google Bookmarks.</p>
            <p>You will need an html export file from either of these services.</p>
            <h2>Delicious</h2>
            <p>To get an html file from Delicious, click on <em>Settings</em> and then click on 
            the <em>Export / Backup Bookmarks</em> link under the <em>Bookmarks</em> heading.</p>
            <h2>Google Bookmarks</h2>
            <p>To get an html file from Google Bookmarks, click on <em>Export Bookmarks</em>
            under the <em>Tools</em> heading on the sidebar.</p>

            <p>Note that the import process might take a bit of time on large sets of bookmarks.</p>
        </div>
    </div>
</div>
