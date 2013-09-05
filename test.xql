xquery version "3.0";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "modules/services/app.xqm";

(: TEI namesspace :)
declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $results := doc($app:local-persons-repositories)
    return ( $results, <path> {"/db" || $app:local-persons-repositories} </path>)