if( BrowserDetect.browser == "Opera" )
        document.write( "<link rel=\"StyleSheet\" type=\"text/css\" href=\"stylesheets/ostyle.css\" />" );
else if( BrowserDetect.browser == "Firefox" )
        document.write( "<link rel=\"StyleSheet\" type=\"text/css\" href=\"stylesheets/fstyle.css\" />" );
else
        document.write( "<link rel=\"StyleSheet\" type=\"text/css\" href=\"stylesheets/istyle.css\" />" );