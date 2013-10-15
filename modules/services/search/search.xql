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

declare  %private function local:searchNames($query as xs:string) {
    let $persons := persons:searchName($query)
    let $organisations := organisations:searchName($query)
    let $result := 
        if(empty($persons))
        then( 
            if ( empty($organisations) )
            then (
                <result>
                    <name>
                        <name>Not found</name>
                        <value>Not found</value>
                        <bio/>
                        <resource/>
                        <uuid/>
                        <viafID/>
                        <hint>create/request new record</hint>
                    </name>
                </result>
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

let $names := request:get-parameter-names()[1]
let $names := if ($names eq "base") then ("subjects") else ($names)
let $query := replace(request:get-parameter($names, "luf"), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
let $log := util:log("INFO", request:get-parameter-names()[1])
return
    switch ($names)
       case "subjects" return typeahead:jquery-typeahead(subjects:searchSubject($query))       
       case "persons" return json:xml-to-json(typeahead:jquery-typeahead(persons:searchName($query)))
       case "organisations" return json:xml-to-json(typeahead:jquery-typeahead(organisations:searchName($query)))
       case "names" return local:searchNames($query)
       default return 
                    <results>{typeahead:jquery-typeahead-default()}</results>
   