xquery version "3.0";

import module namespace remote-viaf="http://exist-db.org/xquery/biblio/services/search/remote/names/remote-viaf" at "remote-viaf.xqm";

let $query := 'Marx'
let $startRecord := 1
let $page_limit := 10
let $local-viaf-ids := ()

return remote-viaf:searchNames($query, $startRecord, $page_limit, $local-viaf-ids)