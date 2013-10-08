xquery version "3.0";

import module namespace persons="http://exist-db.org/xquery/biblio/services/search/local/persons" at "local/persons.xqm";
import module namespace organisations="http://exist-db.org/xquery/biblio/services/search/local/organisations" at "local/organisations.xqm";
import module namespace json="http://www.json.org";

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
                <bio>{data($result/@dates)}</bio>
                <resource>{data($result/@resource)}</resource>
                <uuid>{data($result/@uuid)}</uuid>
                <viafID>{data($result/@viafID)}</viafID>
                <hint/>
            </name>
    }
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
};

let $names := request:get-parameter-names()[1]
let $names := if ($names eq "base") then ("name") else ($names)
let $query := replace(request:get-parameter($names, "arx"), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
let $log := util:log("INFO", request:get-parameter-names()[1])
return
    switch ($names)
       case "persons" return json:xml-to-json(local:jquery-typeahead(persons:searchName($query)))
       case "organisations" return json:xml-to-json(local:jquery-typeahead(organisations:searchName($query)))
       case "names"
        return 
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
                $result
       default return 
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
   