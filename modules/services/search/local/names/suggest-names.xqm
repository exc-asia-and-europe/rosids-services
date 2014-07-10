xquery version "3.0";

module namespace rosids-names-query="http://exist-db.org/xquery/biblio/services/search/local/subjects/rosids-names-query";

import module namespace rosids-utils="http://exist-db.org/xquery/biblio/services/rosids/rosids-utils" at "../../utils/rosids-utils.xqm";

import module namespace rosids-persons="http://exist-db.org/xquery/biblio/services/search/local/names/rosids-persons" at "local/names/rosids-persons.xqm";
import module namespace rosids-organisations="http://exist-db.org/xquery/biblio/services/search/local/names/rosids-organisations" at "local/names/rosids-organisations.xqm";
import module namespace local-viaf="http://exist-db.org/xquery/biblio/services/search/local/names/local-viaf" at "local/names/local-viaf.xqm";
import module namespace remote-viaf="http://exist-db.org/xquery/biblio/services/search/remote/names/remote-viaf" at "remote/names/remote-viaf.xqm";


(: Custom Repositories Query START:)
declare function rosids-names-query:suggestCustomNames($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collections as xs:string*, $type as xs:string) as item()* {
    let $results := rosids-names-query:suggestCustomsNamesQuery($query, $startRecord, $page_limit, $collections, $type)
    let $total := sum(for $map in $results return map:get($map, "total"))
    let $terms := ( for $map in $results return map:get($map, "results") )
    return  <result>
                <total>{$total}</total>
                { $terms }
            </result>
};

declare function rosids-names-query:suggestCustomsNamesQuery($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collections as xs:string*, $type as xs:string) as item()* {
    let $log := if($app:debug) then ( util:log("INFO", "suggestCustomsNamesQuery: Collections: " || string-join($collections, ' ')) ) else ()
    let $result := rosids-subjects:searchNames($collections[1], $query, $startRecord, $page_limit)
    let $nStartRecord := $startRecord - map:get($result, "total")
    let $nStartRecord := if( $nStartRecord < 1 ) then ( 1 ) else ( $nStartRecord )
    let $nPage_limit := $page_limit - count(map:get($result, "results"))
    let $log := if($app:debug) then ( util:log("INFO", "suggestCustomsNamesQuery: nStartRecord: " || $nStartRecord || " nPage_limit: " || $nPage_limit) ) else ()
    return ( $result, 
                if($nPage_limit > 0 and count(subsequence($collections, 2)) > 0 )
                then ( rosids-names-query:suggestCustomsNamesQuery($query, $nStartRecord, $nPage_limit, subsequence($collections, 2)))
                else ( () )
            )
};

(: Custom Repositories Query END:)

declare function local:suggestNames($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string) as item()* {
    let $persons := rosids-persons:searchNames($collection, $query, $startRecord, $page_limit) 
    let $pTotal := count(map:get($persons, "total"))    
    let $pCount := count(map:get($persons, "results"))
    let $log := util:log("INFO", "suggestNames: Count persons: " || $pCount) 
    
    let $oStartRecord := $startRecord - $pTotal
    let $oStartRecord := if( $oStartRecord < 1 ) then ( 1 ) else ( $oStartRecord )
    let $oPage_limit := $page_limit - $pCount
    let $log := util:log("INFO", "suggestNames: oStartRecord: " || $oStartRecord || " oPage_limit: " || $oPage_limit)
    let $organisations := rosids-organisations:searchNames($collection, $query, $oStartRecord, $oPage_limit)
    let $oTotal := count(map:get($organisations, "total"))        
    let $oCount := count(map:get($organisations, "results"))
    let $log := util:log("INFO", "suggestNames: Count organisations: " || $oCount)) 
    
    let $vStartRecord := $startRecord - ( $pTotal + $oTotal )
    let $vStartRecord := if( $vStartRecord < 1 ) then ( 1 ) else ( $vStartRecord )
    let $vPage_limit := $page_limit - ( $pCount + $oCount )
    let $log := util:log("INFO", "suggestNames: vStartRecord: " || $vStartRecord || " vPage_limit: " || $vPage_limit)    
    (: let $viaf := local-viaf:searchNames($query, $vStartRecord, $vPage_limit, (data(map:get($persons, "results")//@internalID), data(map:get($organisations, "results")//@internalID))) :)
    let $viaf := remote-viaf:searchNames($query, $vStartRecord, $vPage_limit, (data(map:get($persons, "results")//@internalID), data(map:get($organisations, "results")//@internalID)))
    let $log := util:log("INFO", "suggestNames: Count viaf: " || count(map:get($viaf, "results")))
    return 
        <result>
            <total>{ $pTotal + $oTotal + map:get($viaf, "total") }</total>
            { ( map:get($persons, "results"), map:get($organisations, "results"), map:get($viaf, "results") ) }
        </result>
};

declare function local:suggestLocalNames($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string) as item()* {
    let $persons := rosids-persons:searchNames($collection, $query, $startRecord, $page_limit) 
    let $log := util:log("INFO", "suggestNames: Count persons: " || count(subsequence($persons, 2))) 
    
    let $oStartRecord := $startRecord - $persons[1]
    let $oStartRecord := if( $oStartRecord < 1 ) then ( 1 ) else ( $oStartRecord )
    let $oPage_limit := $page_limit - count(subsequence($persons, 2))
    let $log := util:log("INFO", "suggestNames: oStartRecord: " || $oStartRecord || " oPage_limit: " || $oPage_limit)
    let $organisations := rosids-organisations:searchNames($collection, $query, $oStartRecord, $oPage_limit)
    let $log := util:log("INFO", "suggestNames: Count organisations: " || count(subsequence($organisations, 2))) 
    
    return 
        <result>
            <total>{ $persons[1] + $organisations[1]}</total>
            { ( subsequence($persons, 2), subsequence($organisations, 2) ) }
        </result>
};

declare function local:suggestPersons($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string) as item()* {
    let $persons := rosids-persons:searchNames($collection, $query, $startRecord, $page_limit) 
    let $log := util:log("INFO", "suggestNames: Count persons: " || count(subsequence($persons, 2))) 
    
    let $vStartRecord := $startRecord - $persons[1]
    let $vStartRecord := if( $vStartRecord < 1 ) then ( 1 ) else ( $vStartRecord )
    let $vPage_limit := $page_limit - count(subsequence($persons, 2))
    let $log := util:log("INFO", "suggestNames: vStartRecord: " || $vStartRecord || " vPage_limit: " || $vPage_limit)
    let $viaf-persons := local-viaf:searchPersonsNames($query, $vStartRecord, $vPage_limit, data(subsequence($persons, 2)//@internalID))
    let $log := util:log("INFO", "suggestNames: Count viaf-persons: " || count(subsequence($viaf-persons, 2))) 
    
    return 
        <result>
            <total>{ $persons[1] + $viaf-persons[1]}</total>
            { ( subsequence($persons, 2), subsequence($viaf-persons, 2) ) }
        </result>
};

declare function local:suggestLocalPersons($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string) as item()* {
    let $persons := rosids-persons:searchNames($collection, $query, $startRecord, $page_limit) 
    let $log := util:log("INFO", "suggestNames: Count persons: " || count(subsequence($persons, 2))) 
    return 
        <result>
            <total>{ $persons[1]}</total>
            { ( subsequence($persons, 2) ) }
        </result>
};

declare function local:suggestOrganisations($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string) as item()* {
    let $organisations := rosids-organisations:searchNames($collection, $query, $startRecord, $page_limit)
    let $log := util:log("INFO", "suggestNames: Count organisations: " || count(subsequence($organisations, 2))) 
    
    let $vStartRecord := $startRecord - $organisations[1]
    let $vStartRecord := if( $vStartRecord < 1 ) then ( 1 ) else ( $vStartRecord )
    let $vPage_limit := $page_limit - count(subsequence($organisations, 2))
    let $log := util:log("INFO", "suggestNames: vStartRecord: " || $vStartRecord || " vPage_limit: " || $vPage_limit)
    let $viaf-organisations := local-viaf:searchOrganisationsNames($query, $vStartRecord, $vPage_limit, data(subsequence($organisations, 2)//@internalID))
    let $log := util:log("INFO", "suggestNames: Count viaf-organisations: " || count(subsequence($viaf-organisations, 2))) 
    
    return 
        <result>
            <total>{ $organisations[1] + $viaf-organisations[1]}</total>
            { ( subsequence($organisations, 2), subsequence($viaf-organisations, 2) ) }
        </result>    
};

declare function local:suggestLocalOrganisations($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string) as item()* {
    let $organisations := rosids-organisations:searchNames($collection, $query, $startRecord, $page_limit)
    let $log := util:log("INFO", "suggestNames: Count organisations: " || count(subsequence($organisations, 2))) 
    
     return 
        <result>
            <total>{$organisations[1]}</total>
            { ( subsequence($organisations, 2)) }
        </result>
};

declare function local:suggestNames($query, $type, $page_limit, $startRecord)
let $query := replace(request:get-parameter("query", "air"), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
let $type := replace(request:get-parameter("type", "test"), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
let $page_limit := xs:integer(replace(request:get-parameter("page_limit", "30"), "[^0-9 ]", "")) 
let $startRecord := (xs:integer(replace(request:get-parameter("page", "1"), "[^0-9 ]", "")) * $page_limit) - ($page_limit -1)
let $collection := replace(request:get-parameter("collection", ""), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
let $collection := rosids-utils:getCollection($type, $collection)
let $log := util:log("INFO", "suggestNames: collection: " || $collection) 
    
let $cors := response:set-header("Access-Control-Allow-Origin", "*")

let $collections := ("/db/resources/services/repositories/global/subjects/", "/db/resources/services/repositories/users/dba/subjects/", "/db/resources/services/repositories/groups/dba/subjects/") 
return
    switch ($type)
        case "names"
            return local:suggestNames($query, $startRecord, $page_limit, $collection)
        case "local"
            (: Search name in local repos :)
            return local:suggestLocalNames($query, $startRecord, $page_limit, $collection)
        case "persons"
            return local:suggestPersons($query, $startRecord, $page_limit, $collection)
        case "local-persons"
            return local:suggestLocalPersons($query, $startRecord, $page_limit, $collection)
        case "organisations"
            return local:suggestOrganisations($query, $startRecord, $page_limit, $collection)
        case "local-organisations"
            return local:suggestLocalOrganisations($query, $startRecord, $page_limit, $collection)
        default 
            return 
                <result><total>0</total></result>
