xquery version "3.0";

import module namespace persons="http://exist-db.org/xquery/biblio/services/search/local/persons" at "local/persons.xqm";
import module namespace organisations="http://exist-db.org/xquery/biblio/services/search/local/organisations" at "local/organisations.xqm";

(:
    Entry point for searches in cluster vocabs.
:)
declare option exist:serialize "method=json media-type=text/javascript";

let $names := request:get-parameter-names()[1]
let $names := if ($names eq "base") then ("persons") else ($names)
let $query := replace(request:get-parameter($names, "arx"), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
return
    <results>
        <query>{$query}</query>
        {
            switch ($names)
               case "persons" return persons:searchName( $query)
               case "organisations" return organisations:searchName($query)
               case "name" return (persons:searchName( $query), organisations:searchName($query))
               default return ""
        }
    </results>