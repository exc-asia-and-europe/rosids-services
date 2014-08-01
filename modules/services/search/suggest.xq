xquery version "3.0";

import module namespace app="http://www.betterform.de/projects/shared/config/app" at "/apps/cluster-shared/modules/ziziphus/config/app.xqm";
import module namespace rosids-persons="http://exist-db.org/xquery/biblio/services/search/local/names/rosids-persons" at "local/names/rosids-persons.xqm";
import module namespace rosids-organisations="http://exist-db.org/xquery/biblio/services/search/local/names/rosids-organisations" at "local/names/rosids-organisations.xqm";

import module namespace local-viaf="http://exist-db.org/xquery/biblio/services/search/local/names/local-viaf" at "local/names/local-viaf.xqm";
import module namespace remote-viaf="http://exist-db.org/xquery/biblio/services/search/remote/names/remote-viaf" at "remote/names/remote-viaf.xqm";

import module namespace rosids-subjects-query="http://exist-db.org/xquery/biblio/services/search/local/subjects/rosids-subjects-query" at "local/subjects/rosids-suggest-subjects.xqm";

import module namespace local-aat-worktype="http://exist-db.org/xquery/biblio/services/search/local/worktype/local-aat-worktype" at "local/worktype/local-aat-worktype.xqm";

declare option exist:serialize "method=json media-type=text/javascript";

declare %private function local:getCollection($type as xs:string, $collection as xs:string) {
    if($collection eq '' or $collection eq 'default')
    then(
        switch ($type)
            case "organisations"
                return $app:global-organisations-repositories-collection
            case "persons"
                return $app:global-persons-repositories-collection
            case "subjects"
                return $app:global-subjects-repositories-collection
            default 
                return $app:global-persons-repositories-collection
    ) else (
        $collection
    )
};

declare %private function local:getCollections($type as xs:string, $collection as xs:string*) {
    if($collection eq '' or $collection eq 'default')
    then(
        switch ($type)
            case "organisations"
                return $app:global-organisations-repositories-collection
            case "persons"
                return $app:global-persons-repositories-collection
            case "subjects"
                return ( $app:global-subjects-repositories-collection , $app:global-getty-aat-repositories )
            default 
                return $app:global-persons-repositories-collection
    ) else (
        $collection
    )
};

declare function local:suggestNames($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string) as item()* {
    let $persons := rosids-persons:searchNames($collection, $query, $startRecord, $page_limit) 
    let $log := util:log("INFO", "suggestNames: Count persons: " || count(map:get($persons, "results"))) 
    
    let $oStartRecord := $startRecord - map:get($persons, "total")
    let $oStartRecord := if( $oStartRecord < 1 ) then ( 1 ) else ( $oStartRecord )
    let $oPage_limit := $page_limit - count(map:get($persons, "results"))
    let $log := util:log("INFO", "suggestNames: oStartRecord: " || $oStartRecord || " oPage_limit: " || $oPage_limit)
    let $organisations := rosids-organisations:searchNames($collection, $query, $oStartRecord, $oPage_limit)
    let $log := util:log("INFO", "suggestNames: Count organisations: " || count( map:get($organisations, "results"))) 
    
    let $vStartRecord := $startRecord - ( map:get($persons, "total") + map:get($organisations, "total") )
    let $vStartRecord := if( $vStartRecord < 1 ) then ( 1 ) else ( $vStartRecord )
    let $vPage_limit := $page_limit - ( count(map:get($persons, "results")) + count( map:get($organisations, "results")) )
    let $log := util:log("INFO", "suggestNames: vStartRecord: " || $vStartRecord || " vPage_limit: " || $vPage_limit)    
    (: let $viaf := local-viaf:searchNames($query, $vStartRecord, $vPage_limit, (data(subsequence($persons, 2)//@internalID), data(subsequence($organisations, 2)//@internalID))) :)
    let $viaf := local-viaf:searchNames($query, $vStartRecord, $vPage_limit, (data(map:get($persons, "results")//@internalID), data( map:get($organisations, "results")//@internalID)))
    let $log := util:log("INFO", "suggestNames: Count viaf: " || count( map:get($viaf, "results") ))
    return 
        <result>
            <total>{ map:get($persons, "total") + map:get($organisations, "total") + map:get($viaf, "total")}</total>
            { ( map:get($persons, "results"),  map:get($organisations, "results"), map:get($viaf, "results") ) }
        </result>
};


 
declare function local:suggestLocalNames($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string) as item()* {
    let $persons := rosids-persons:searchNames($collection, $query, $startRecord, $page_limit) 
    let $log := util:log("INFO", "suggestNames: Count persons: " || count(map:get($persons, "results"))) 
    
    let $oStartRecord := $startRecord - map:get($persons, "total")
    let $oStartRecord := if( $oStartRecord < 1 ) then ( 1 ) else ( $oStartRecord )
    let $oPage_limit := $page_limit - count(map:get($persons, "results"))
    let $log := util:log("INFO", "suggestNames: oStartRecord: " || $oStartRecord || " oPage_limit: " || $oPage_limit)
    let $organisations := rosids-organisations:searchNames($collection, $query, $oStartRecord, $oPage_limit)
    let $log := util:log("INFO", "suggestNames: Count organisations: " || count(map:get($organisations, "results"))) 
    
    return 
        <result>
            <total>{ map:get($persons, "total") +  map:get($organisations, "total")}</total>
            { ( map:get($persons, "results"), map:get($organisations, "results") ) }
        </result>
};
(: TODO TODO :)
  
 (: map:get($map, "total") map:get($map, "results") :)

  
declare function local:suggestPersons($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string) as item()* {
    let $persons := rosids-persons:searchNames($collection, $query, $startRecord, $page_limit) 
    let $log := util:log("INFO", "suggestNames: Count persons: " || count(map:get($persons, "results"))) 
    
    let $vStartRecord := $startRecord - map:get($persons, "total")
    let $vStartRecord := if( $vStartRecord < 1 ) then ( 1 ) else ( $vStartRecord )
    let $vPage_limit := $page_limit - count(map:get($persons, "results"))
    let $log := util:log("INFO", "suggestNames: vStartRecord: " || $vStartRecord || " vPage_limit: " || $vPage_limit)
    let $viaf-persons := local-viaf:searchPersonsNames($query, $vStartRecord, $vPage_limit, data(map:get($persons, "results")//@internalID))
    let $log := util:log("INFO", "suggestNames: Count viaf-persons: " || count(map:get($persons, "results"))) 
    
    return 
        <result>
            <total>{ map:get($persons, "total") + map:get($viaf-persons, "total")}</total>
            { ( map:get($persons, "results"), map:get($viaf-persons, "results") ) }
        </result>
};


  
declare function local:suggestLocalPersons($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string) as item()* {
    let $persons := rosids-persons:searchNames($collection, $query, $startRecord, $page_limit) 
    let $log := util:log("INFO", "suggestNames: Count persons: " || count(map:get($persons, "results"))) 
    

    return 
        <result>
            <total>{ map:get($persons, "total")}</total>
            { ( map:get($persons, "results") ) }
        </result>
};

(: TODO TODO :)
 
declare function local:suggestOrganisations($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string) as item()* {
    let $organisations := rosids-organisations:searchNames($collection, $query, $startRecord, $page_limit)
    let $log := util:log("INFO", "suggestNames: Count organisations: " || count(map:get($organisations, "results"))) 
    
    let $vStartRecord := $startRecord - map:get($organisations, "total")
    let $vStartRecord := if( $vStartRecord < 1 ) then ( 1 ) else ( $vStartRecord )
    let $vPage_limit := $page_limit - count(map:get($organisations, "results"))
    let $log := util:log("INFO", "suggestNames: vStartRecord: " || $vStartRecord || " vPage_limit: " || $vPage_limit)
    let $viaf-organisations := local-viaf:searchOrganisationsNames($query, $vStartRecord, $vPage_limit, data(map:get($organisations, "results")//@internalID))
    let $log := util:log("INFO", "suggestNames: Count viaf-organisations: " || count(map:get($viaf-organisations, "results"))) 
    
    return 
        <result>
            <total>{ map:get($organisations, "total") + map:get($viaf-organisations, "total")}</total>
            { ( map:get($organisations, "results"), map:get($viaf-organisations, "results") ) }
        </result>    
};

  (:
    map:get($persons, "total")
    map:get($persons, "results")
    map:get($organisations, "total")
    map:get($organisations, "results")
    map:get($viaf, "total")
    map:get($viaf, "results")
    map:get($viaf-organisations, "total")
    map:get($viaf-organisations, "results")
 
 :)
 
declare function local:suggestLocalOrganisations($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string) as item()* {
    let $organisations := rosids-organisations:searchNames($collection, $query, $startRecord, $page_limit)
    let $log := util:log("INFO", "suggestNames: Count organisations: " || count(map:get($organisations, "results"))) 
    
     return 
        <result>
            <total>{map:get($organisations, "total")}</total>
            { ( map:get($organisations, "results")) }
        </result>
};

declare function local:suggestWorktypes($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer) as item()* {
    let $worktypes := local-aat-worktype:searchWorktype($query, $startRecord, $page_limit)
    return 
        <result>
            <total>{map:get($worktypes, "total")}</total>
            { ( map:get($worktypes, "results")) }
        </result>
};

let $query := replace(request:get-parameter("query", "oil"), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
let $type := replace(request:get-parameter("type", "worktypes"), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
let $page_limit := xs:integer(replace(request:get-parameter("page_limit", "30"), "[^0-9 ]", "")) 
let $startRecord := (xs:integer(replace(request:get-parameter("page", "1"), "[^0-9 ]", "")) * $page_limit) - ($page_limit -1)
let $collections := replace(request:get-parameter("collections", ""), "[^0-9a-zA-ZäöüßÄÖÜ\-/,. ]", "default")
let $collection := local:getCollection($type, $collections)

    
let $cors := response:set-header("Access-Control-Allow-Origin", "*")

let $collections := local:getCollections($type, $collections)
let $log := util:log("INFO", "suggest: collections: " || string-join($collections, ':'))
return
    switch ($type)
        case "test"
            return rosids-subjects-query:suggestCustomSubjects($query, $startRecord, $page_limit, $collections)
        case "names"
            return local:suggestNames($query, $startRecord, $page_limit, $collection)
        case "local"
            (: Search name in local repos :)
            return local:suggestLocalNames($query, $startRecord, $page_limit, $collection)
        case "subjects"
            (: return rosids-subjects-query:suggestSubjects($query, $startRecord, $page_limit, $collection) :)
            return rosids-subjects-query:suggestCustomSubjects($query, $startRecord, $page_limit, $collections)
        case "persons"
            return local:suggestPersons($query, $startRecord, $page_limit, $collection)
        case "local-persons"
            return local:suggestLocalPersons($query, $startRecord, $page_limit, $collection)
        case "organisations"
            return local:suggestOrganisations($query, $startRecord, $page_limit, $collection)
        case "local-organisations"
            return local:suggestLocalOrganisations($query, $startRecord, $page_limit, $collection)
        case "worktypes"
            return local:suggestWorktypes($query, $startRecord, $page_limit)
        default 
            return 
                <result><total>0</total></result>
