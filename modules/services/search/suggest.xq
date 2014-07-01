xquery version "3.0";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "../app.xqm";
import module namespace rosids-persons="http://exist-db.org/xquery/biblio/services/search/local/names/rosids-persons" at "local/names/rosids-persons.xqm";
import module namespace rosids-organisations="http://exist-db.org/xquery/biblio/services/search/local/names/rosids-organisations" at "local/names/rosids-organisations.xqm";

import module namespace local-viaf="http://exist-db.org/xquery/biblio/services/search/local/names/local-viaf" at "local/names/local-viaf.xqm";
import module namespace remote-viaf="http://exist-db.org/xquery/biblio/services/search/remote/names/remote-viaf" at "remote/names/remote-viaf.xqm";

import module namespace rosids-subjects="http://exist-db.org/xquery/biblio/services/search/local/subjects/rosids-subjects" at "local/subjects/rosids-subjects.xqm";
import module namespace local-aat="http://exist-db.org/xquery/biblio/services/search/local/subjects/local-aat" at "local/subjects/local-aat.xqm";

declare option exist:serialize "method=json media-type=text/javascript";

declare %private function local:getCollection($type as xs:string, $collection as xs:string) {
    if($collection eq '')
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

declare function local:suggestNames($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string) as item()* {
    let $persons := rosids-persons:searchNames($collection, $query, $startRecord, $page_limit) 
    let $log := util:log("INFO", "suggestNames: Count persons: " || count(subsequence($persons, 2))) 
    
    let $oStartRecord := $startRecord - $persons[1]
    let $oStartRecord := if( $oStartRecord < 1 ) then ( 1 ) else ( $oStartRecord )
    let $oPage_limit := $page_limit - count(subsequence($persons, 2))
    let $log := util:log("INFO", "suggestNames: oStartRecord: " || $oStartRecord || " oPage_limit: " || $oPage_limit)
    let $organisations := rosids-organisations:searchNames($collection, $query, $oStartRecord, $oPage_limit)
    let $log := util:log("INFO", "suggestNames: Count organisations: " || count(subsequence($organisations, 2))) 
    
    let $vStartRecord := $startRecord - ( $persons[1] + $organisations[1] )
    let $vStartRecord := if( $vStartRecord < 1 ) then ( 1 ) else ( $vStartRecord )
    let $vPage_limit := $page_limit - ( count(subsequence($persons, 2)) + count(subsequence($organisations, 2)) )
    let $log := util:log("INFO", "suggestNames: vStartRecord: " || $vStartRecord || " vPage_limit: " || $vPage_limit)    
    (: let $viaf := local-viaf:searchNames($query, $vStartRecord, $vPage_limit, (data(subsequence($persons, 2)//@internalID), data(subsequence($organisations, 2)//@internalID))) :)
    let $viaf := remote-viaf:searchNames($query, $vStartRecord, $vPage_limit, (data(subsequence($persons, 2)//@internalID), data(subsequence($organisations, 2)//@internalID)))
    let $log := util:log("INFO", "suggestNames: Count viaf: " || count(subsequence($viaf, 2)))
    return 
        <result>
            <total>{ $persons[1] + $organisations[1] + $viaf[1]}</total>
            { ( subsequence($persons, 2), subsequence($organisations, 2), subsequence($viaf, 2) ) }
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
(: TODO TODO :)
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

(: TODO TODO :)
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

declare function local:suggestSubjects($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string) as item()* {
    let $subjects := rosids-subjects:searchSubjects($collection, $query, $startRecord, $page_limit)
    let $log := util:log("INFO", "suggestSubjects: Count subjects: " || count(subsequence($subjects, 2)))
    let $log := util:log("INFO", "suggestSubjects: subjects in local repo: " || $subjects[1])
    let $aStartRecord := $startRecord - $subjects[1]
    let $aStartRecord := if( $aStartRecord < 1 ) then ( 1 ) else ( $aStartRecord )
    let $aPage_limit := $page_limit - count(subsequence($subjects, 2))
    let $log := util:log("INFO", "suggestSubjects: startRecord: " || $startRecord || " page_limit: " || $page_limit)
    let $log := util:log("INFO", "suggestSubjects: aStartRecord: " || $aStartRecord || " aPage_limit: " || $aPage_limit)
    let $aat := local-aat:searchSubjects($query, $aStartRecord, $aPage_limit)
    let $log := util:log("INFO", "suggestSubjects: Count aat: " || count(subsequence($aat, 2)))

    return 
        <result>
            <total>{ $subjects[1] + $aat[1]}</total>
            {( subsequence($subjects, 2), subsequence($aat, 2)) }
        </result>
};


let $query := replace(request:get-parameter("query", "marx"), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
let $type := replace(request:get-parameter("type", "names"), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
let $page_limit := xs:integer(replace(request:get-parameter("page_limit", "10"), "[^0-9 ]", "")) 
let $startRecord := (xs:integer(replace(request:get-parameter("page", "2"), "[^0-9 ]", "")) * $page_limit) - ($page_limit -1)
let $collection := replace(request:get-parameter("collection", ""), "[^0-9a-zA-ZäöüßÄÖÜ\-,. ]", "")
let $collection := local:getCollection($type, $collection)
let $log := util:log("INFO", "suggestNames: collection: " || $collection) 
    
let $cors := response:set-header("Access-Control-Allow-Origin", "*")

return
    switch ($type)
        case "names"
            return local:suggestNames($query, $startRecord, $page_limit, $collection)
        case "local"
            (: Search name in local repos :)
            return local:suggestLocalNames($query, $startRecord, $page_limit, $collection)
        case "subjects"
            return local:suggestSubjects($query, $startRecord, $page_limit, $collection)
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
