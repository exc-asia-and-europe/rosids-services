xquery version "3.0";

import module namespace persons="http://exist-db.org/xquery/biblio/services/search/local/persons" at "local/persons.xqm";
import module namespace organisations="http://exist-db.org/xquery/biblio/services/search/local/organisations" at "local/organisations.xqm";

(:
    Entry point for searches in cluster vocabs.
:)
declare option exist:serialize "method=json media-type=text/javascript";

declare function local:jquery-typeahead($results as item()*) {
    <result>
    {
        for $result in $results
        return
            <name>
                <name>{replace( data($result/@name), "&quot;", "'")}</name>
                <value>{replace( data($result/@name), "&quot;", "'")}</value>
                    
                </name>
            (: value="{data($result/@name)}" bio="{data($result/@dates)}" resource="{data($result/@resource)}" uuid="{data($result/@uuid)}" viafID="{data($result/@viafID)}"/>  :)
    }
    </result>
};


declare function local:jquery-ac($results as item()*) {
    for $result in $results
        return
            <suggestions value="{data($result/@name)}" data="{data($result/@name)}" bio="{data($result/@dates)}" resource="{data($result/@resource)}" uuid="{data($result/@uuid)}" viafID="{data($result/@viafID)}" sources="{data($result/@sources)}"/>
};


let $names := request:get-parameter-names()[1]
let $names := if ($names eq "base") then ("name") else ($names)
let $query := replace(request:get-parameter($names, "arx"), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
let $log := util:log("INFO", request:get-parameter-names()[1])
return
    <results>
        <query>{$query}</query>
        {
            switch ($names)
               case "persons" return local:jquery-ac(persons:searchName( $query))
               case "organisations" return local:jquery-ac(organisations:searchName($query))
               case "name" return local:jquery-ac((persons:searchName( $query), organisations:searchName($query)))
               default return ""
        }
    </results>
(:

let $names := request:get-parameter-names()[1]
let $names := if ($names eq "base") then ("name") else ($names)
let $query := replace(request:get-parameter($names, "arx"), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
let $log := util:log("INFO", request:get-parameter-names()[1])
return
    switch ($names)
       case "persons" return json:xml-to-json(local:jquery-typeahead(persons:searchName($query)))
       case "organisations" return json:xml-to-json(local:jquery-typeahead(organisations:searchName($query)))
       case "name"
        return 
           let $persons := persons:searchName($query)
           let $organisations := organisations:searchName($query)
           let $result := 
            if(empty($persons))
            then( 
                if ( empty($organisations) )
                then (
                    <name>
                        <name>Nothing found</name>
                        <value>Nothing found</value>
                    </name>
                ) else ( local:jquery-typeahead($organisations) )
            ) else (
                if( empty($organisations) )
                then (
                    local:jquery-typeahead($persons)
                ) else (
                    local:jquery-typeahead( ($persons, $organisations ) )
                )
            )
            return
                json:xml-to-json($result)
:)