if( BrowserDetect.browser == "Opera" )
        document.write( "<link rel=\"StyleSheet\" type=\"text/css\" href=\"ostyle.css\" />" );
else if( BrowserDetect.browser == "Firefox" )
        document.write( "<link rel=\"StyleSheet\" type=\"text/css\" href=\"fstyle.css\" />" );
else
        document.write( "<link rel=\"StyleSheet\" type=\"text/css\" href=\"istyle.css\" />" );