xquery version "3.0";

import module namespace persons="http://exist-db.org/xquery/biblio/services/search/local/persons" at "local/persons.xqm";
import module namespace organisations="http://exist-db.org/xquery/biblio/services/search/local/organisations" at "local/organisations.xqm";
import module namespace subjects="http://exist-db.org/xquery/biblio/services/search/local/subjects" at "local/subjects.xqm";
import module namespace typeahead="http://exist-db.org/xquery/biblio/services/search/autocomplete/typeahead" at "autocomplete/typeahead.xqm";
import module namespace json="http://www.json.org";

(:
    Entry point for searches in cluster vocabs.
:)

declare option exist:serialize "method=json media-type=text/javascript";

declare  %private function local:searchNames($query as xs:string, $startRecord, $maximumRecords) {
    let $persons := persons:searchName($query, $startRecord, $maximumRecords)
    let $countPersons := count($persons/names/name)
    let $organisations := if($countPersons >= $maximumRecords) then (()) else ( organisations:searchName($query, $startRecord, $maximumRecords) )
    let $result := 
        if(empty($persons))
        then( 
            if ( empty($organisations) )
            then (
               <results>{typeahead:jquery-typeahead-default()}</results>
            ) else ( typeahead:jquery-typeahead($organisations) )
        ) else (
            if( empty($organisations) )
            then (
                typeahead:jquery-typeahead($persons)
            ) else (
                typeahead:jquery-typeahead( ($persons, $organisations ) )
            )
        )
    return
        $result
};

let $query := replace(request:get-parameter("query", "arx"), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
let $type := replace(request:get-parameter("type", "names"), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
let $maximumRecords := xs:integer(replace(request:get-parameter("page_limit", "10"), "[^0-9 ]", ""))
let $startRecord := (xs:integer(replace(request:get-parameter("page", "1"), "[^0-9 ]", "")) * $maximumRecords) - $maximumRecords
let $log := util:log("INFO", request:get-parameter-names()[1])
return
    switch ($type)
       case "subjects" return typeahead:jquery-typeahead(subjects:searchSubject($query))       
       case "persons" return json:xml-to-json(typeahead:jquery-typeahead(persons:searchName($query, $startRecord, $maximumRecords)))
       case "organisations" return json:xml-to-json(typeahead:jquery-typeahead(organisations:searchName($query)))
       case "names" return local:searchNames($query, $startRecord, $maximumRecords)
       default return 
                    <results>{typeahead:jquery-typeahead-default()}</results>
   