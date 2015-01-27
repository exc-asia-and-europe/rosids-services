xquery version "3.0";

import module namespace app="http://www.betterform.de/projects/shared/config/app" at "/apps/cluster-shared/modules/ziziphus/config/app.xqm";
import module namespace rosids-persons="http://exist-db.org/xquery/biblio/services/search/local/names/rosids-persons" at "local/names/rosids-persons.xqm";
import module namespace rosids-organisations="http://exist-db.org/xquery/biblio/services/search/local/names/rosids-organisations" at "local/names/rosids-organisations.xqm";
import module namespace rosids-id="http://exist-db.org/xquery/biblio/services/search/local/id/rosids-id" at "local/id/rosids-id.xqm";

import module namespace local-viaf="http://exist-db.org/xquery/biblio/services/search/local/names/local-viaf" at "local/names/local-viaf.xqm";
import module namespace remote-viaf="http://exist-db.org/xquery/biblio/services/search/remote/names/remote-viaf" at "remote/names/remote-viaf.xqm";

import module namespace rosids-subjects-query="http://exist-db.org/xquery/biblio/services/search/local/subjects/rosids-subjects-query" at "local/subjects/rosids-suggest-subjects.xqm";

import module namespace local-aat="http://exist-db.org/xquery/biblio/services/search/local/aat/local-aat" at "local/aat/local-aat.xqm";

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
            case "worktypes"
            case "styleperiods"
            case "techniques"
            case "materials"
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
            case "materials"
                return ( $app:global-materials-repositories-collection , $app:global-getty-aat-repositories )
            case "styleperiods"
                return ( $app:global-styleperiods-repositories-collection , $app:global-getty-aat-repositories )
            case "techniques"
                return ( $app:global-techniques-repositories-collection , $app:global-getty-aat-repositories )
            case "worktypes"
                return ( $app:global-worktypes-repositories-collection , $app:global-getty-aat-repositories )
            default 
                return $app:global-persons-repositories-collection
    ) else (
        $collection
    )
};

declare function local:suggestNames($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string, $exact_mode as xs:string) as item()* {
    (: let $persons := rosids-persons:searchNames($collection, $query, $startRecord, $page_limit) :)
    let $persons := rosids-persons:searchNames($app:global-persons-repositories-collection, $query, $startRecord, $page_limit) 
    let $log := util:log("INFO", "suggestNames: Count persons: " || count(map:get($persons, "results"))) 
    
    let $oStartRecord := $startRecord - map:get($persons, "total")
    let $oStartRecord := if( $oStartRecord < 1 ) then ( 1 ) else ( $oStartRecord )
    let $oPage_limit := $page_limit - count(map:get($persons, "results"))
    let $log := util:log("INFO", "suggestNames: oStartRecord: " || $oStartRecord || " oPage_limit: " || $oPage_limit)
    (: let $organisations := rosids-organisations:searchNames($collection, $query, $oStartRecord, $oPage_limit) :)
    let $organisations := rosids-organisations:searchNames($app:global-organisations-repositories-collection, $query, $oStartRecord, $oPage_limit)
    let $log := util:log("INFO", "suggestNames: Count organisations: " || count( map:get($organisations, "results"))) 
    
    let $vpStartRecord := $startRecord - ( map:get($persons, "total") + map:get($organisations, "total") )
    let $vpStartRecord := if( $vpStartRecord < 1 ) then ( 1 ) else ( $vpStartRecord )
    let $vpPage_limit := $page_limit - ( count(map:get($persons, "results")) + count( map:get($organisations, "results")) )
    let $log := util:log("INFO", "suggestNames: vStartRecord: " || $vpStartRecord || " vPage_limit: " || $vpPage_limit)    
    (: let $viaf := local-viaf:searchNames($query, $vStartRecord, $vPage_limit, (data(subsequence($persons, 2)//@id), data(subsequence($organisations, 2)//@id))) :)
    (: let $viaf :=local-viaf:searchNames($query, $vStartRecord, $vPage_limit, (data(map:get($persons, "results")//@id), data( map:get($organisations, "results")//@id)))  :)
    let $pviaf := remote-viaf:searchNames1('persons', $query, $vpStartRecord, $vpPage_limit, (data(map:get($persons, "results")//@id), data( map:get($organisations, "results")//@id)), $exact_mode)
    let $log := util:log("INFO", "suggestNames: Count pviaf: " || count( map:get($pviaf, "results") ))
    
    
    
    return 
        if($exact_mode eq 'true')
        then (
            <result>
                <total>{ map:get($persons, "total") + map:get($organisations, "total") + map:get($pviaf, "total")}</total>
                { ( map:get($persons, "results"),  map:get($organisations, "results"), map:get($pviaf, "results")) }
            </result>
        ) else (
            let $voStartRecord := $startRecord - ( map:get($persons, "total") + map:get($organisations, "total") + map:get($pviaf, "total") )
            let $voStartRecord := if( $voStartRecord < 1 ) then ( 1 ) else ( $voStartRecord )
            let $voPage_limit := $page_limit - ( count(map:get($persons, "results")) + count(map:get($organisations, "results")) + count(map:get($pviaf, "results")) )
            let $oviaf := remote-viaf:searchNames1('organisations', $query, $voStartRecord, $voPage_limit, (data(map:get($persons, "results")//@id), data( map:get($organisations, "results")//@id)), $exact_mode)
            let $log := util:log("INFO", "suggestNames: Count oviaf: " || count( map:get($oviaf, "results") ))
            return
                <result>
                    <total>{ map:get($persons, "total") + map:get($organisations, "total") + map:get($pviaf, "total") + map:get($oviaf, "total")}</total>
                    { ( map:get($persons, "results"),  map:get($organisations, "results"), map:get($pviaf, "results"), map:get($oviaf, "results") ) }
                </result>
        )
};


 
declare function local:suggestLocalNames($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string) as item()* {
    let $persons := rosids-persons:searchNames($collection, $query, $startRecord, $page_limit) 
    let $log := util:log("INFO", "suggestLocalNames: Count persons: " || count(map:get($persons, "results"))) 
    
    let $oStartRecord := $startRecord - map:get($persons, "total")
    let $oStartRecord := if( $oStartRecord < 1 ) then ( 1 ) else ( $oStartRecord )
    let $oPage_limit := $page_limit - count(map:get($persons, "results"))
    let $log := util:log("INFO", "suggestLocalNames: oStartRecord: " || $oStartRecord || " oPage_limit: " || $oPage_limit)
    let $organisations := rosids-organisations:searchNames($collection, $query, $oStartRecord, $oPage_limit)
    let $log := util:log("INFO", "suggestLocalNames: Count organisations: " || count(map:get($organisations, "results"))) 
    
    return 
        <result>
            <total>{ map:get($persons, "total") +  map:get($organisations, "total")}</total>
            { ( map:get($persons, "results"), map:get($organisations, "results") ) }
        </result>
};
(: TODO TODO :)
  
 (: map:get($map, "total") map:get($map, "results") :)
  
declare function local:suggestPersons($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string, $exact_mode as xs:string) as item()* {
    let $persons := rosids-persons:searchNames($collection, $query, $startRecord, $page_limit) 
    let $log := util:log("INFO", "suggestPersons: Count persons: " || count(map:get($persons, "results"))) 
    
    let $vStartRecord := $startRecord - map:get($persons, "total")
    let $vStartRecord := if( $vStartRecord < 1 ) then ( 1 ) else ( $vStartRecord )
    let $vPage_limit := $page_limit - count(map:get($persons, "results"))
    let $log := util:log("INFO", "suggestPersons: vStartRecord: " || $vStartRecord || " vPage_limit: " || $vPage_limit)
    (: let $viaf-persons := local-viaf:searchPersonsNames($query, $vStartRecord, $vPage_limit, data(map:get($persons, "results")//@id)) :)
    let $viaf-persons := remote-viaf:searchNames1('persons', $query, $vStartRecord, $vPage_limit, data(map:get($persons, "results")//@id), $exact_mode)
    let $log := util:log("INFO", "suggestPersons: Count viaf-persons: " || count(map:get($persons, "results"))) 
    
    return 
        <result>
            <total>{ map:get($persons, "total") + map:get($viaf-persons, "total")}</total>
            { ( map:get($persons, "results"), map:get($viaf-persons, "results") ) }
        </result>
};

declare function local:suggestLocalPersons($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string) as item()* {
    let $persons := rosids-persons:searchNames($collection, $query, $startRecord, $page_limit) 
    let $log := util:log("INFO", "suggestLocalPersons: Count persons: " || count(map:get($persons, "results"))) 
    

    return 
        <result>
            <total>{ map:get($persons, "total")}</total>
            { ( map:get($persons, "results") ) }
        </result>
};

(: TODO TODO :)
 
declare function local:suggestOrganisations($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string, $exact_mode as xs:string) as item()* {
    let $organisations := rosids-organisations:searchNames($collection, $query, $startRecord, $page_limit)
    let $log := util:log("INFO", "suggestOrganisations: Count organisations: " || count(map:get($organisations, "results"))) 
    
    let $vStartRecord := $startRecord - map:get($organisations, "total")
    let $vStartRecord := if( $vStartRecord < 1 ) then ( 1 ) else ( $vStartRecord )
    let $vPage_limit := $page_limit - count(map:get($organisations, "results"))
    let $log := util:log("INFO", "suggestOrganisations: vStartRecord: " || $vStartRecord || " vPage_limit: " || $vPage_limit)
    (: let $viaf-organisations := local-viaf:searchOrganisationsNames($query, $vStartRecord, $vPage_limit, data(map:get($organisations, "results")//@id)) :)
    let $viaf-organisations := remote-viaf:searchNames1('organisations', $query, $vStartRecord, $vPage_limit, data(map:get($organisations, "results")//@id), $exact_mode)
    
    let $log := util:log("INFO", "suggestOrganisations: Count viaf-organisations: " || count(map:get($viaf-organisations, "results"))) 
    
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
    let $log := util:log("INFO", "suggestLocalOrganisations: Count organisations: " || count(map:get($organisations, "results"))) 
    
     return 
        <result>
            <total>{map:get($organisations, "total")}</total>
            { ( map:get($organisations, "results")) }
        </result>
};

declare function local:suggestAAT($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $type as xs:string) as item()* {
    let $subjects := local-aat:searchSubjects($query, $startRecord, $page_limit, $type)
    return 
        <result>
            <total>{map:get($subjects, "total")}</total>
            { ( map:get($subjects, "results")) }
        </result>
};

let $query := request:get-parameter("query", "Marx")
let $type := replace(request:get-parameter("type", "names"), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
let $page_limit := xs:integer(replace(request:get-parameter("page_limit", "100"), "[^0-9 ]", "")) 
let $startRecord := (xs:integer(replace(request:get-parameter("page", "1"), "[^0-9 ]", "")) * $page_limit) - ($page_limit -1)
let $collections := replace(request:get-parameter("collections", "default"), "[^0-9a-zA-ZäöüßÄÖÜ\-/,. ]", "")
let $exact_mode := replace(request:get-parameter("exact_mode", "false"), "[^a-z]", "")
let $collection := local:getCollection($type, $collections)

    
let $cors := response:set-header("Access-Control-Allow-Origin", "*")

let $collections := local:getCollections($type, $collections)
let $log := if($app:debug) then ( util:log("INFO", "suggest: Collections: ||" || $query ||"||") ) else ()
let $log := if($app:debug) then ( util:log("INFO", "suggest: collections: " || string-join($collections, ':')) ) else ()
return
    if(starts-with($query, 'uuid-' ) or string(number($query)) != 'NaN' )
    then (
        rosids-id:id($query, $type)
    ) else (
        switch ($type)
            case "names"
                return local:suggestNames($query, $startRecord, $page_limit, $collection, $exact_mode)
            case "local"
                (: Search name in local repos :)
                return local:suggestLocalNames($query, $startRecord, $page_limit, $collection)
            
            case "persons"
                return local:suggestPersons($query, $startRecord, $page_limit, $collection, $exact_mode)
            case "local-persons"
                return local:suggestLocalPersons($query, $startRecord, $page_limit, $collection)
            case "organisations"
                return local:suggestOrganisations($query, $startRecord, $page_limit, $collection, $exact_mode)
            case "local-organisations"
                return local:suggestLocalOrganisations($query, $startRecord, $page_limit, $collection)
            case "worktypes"
            case "styleperiods"
            case "techniques"
            case "materials"
            case "subjects"
                return rosids-subjects-query:suggestCustomSubjects($query, $startRecord, $page_limit, $collections, $type)
            default 
                return 
                    <result><total>0</total></result>
    )




