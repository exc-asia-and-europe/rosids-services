xquery version "3.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";

declare variable $target external;

(: cleanup and reindex :)
 xmldb:remove($target || "/repositories"),
 xmldb:remove($target || "/xconfs"),
 xmldb:reindex("/db")