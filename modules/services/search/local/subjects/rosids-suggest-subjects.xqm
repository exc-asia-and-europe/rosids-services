xquery version "3.0";

module namespace rosids-subjects-query="http://exist-db.org/xquery/biblio/services/search/local/subjects/rosids-subjects-query";

import module namespace app="http://www.betterform.de/projects/shared/config/app" at "/apps/cluster-shared/modules/ziziphus/config/app.xqm";

import module namespace rosids-subjects="http://exist-db.org/xquery/biblio/services/search/local/subjects/rosids-subjects" at "rosids-subjects.xqm";
import module namespace local-aat="http://exist-db.org/xquery/biblio/services/search/local/subjects/local-aat" at "local-aat.xqm";

declare option exist:serialize "method=json media-type=text/javascript";


(: Custom Repositories Query START:)
declare function rosids-subjects-query:suggestCustomSubjects($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collections as xs:string*) as item()* {
    let $log := if($app:debug) then ( util:log("INFO", "suggestCustomsSubjectsQuery: Collections: " || string-join($collections, ' ')) ) else ()
    let $results := rosids-subjects-query:suggestCustomsSubjectsQuery($query, $startRecord, $page_limit, $collections)
    let $total := sum(for $map in $results return map:get($map, "total"))
    let $terms := ( for $map in $results return map:get($map, "results") )
    return  <result>
                <total>{$total}</total>
                { $terms }
            </result>
};

declare function rosids-subjects-query:suggestCustomsSubjectsQuery($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collections as xs:string*) as item()* {
    let $log := if($app:debug) then ( util:log("INFO", "suggestCustomsSubjectsQuery: Collection: " || $collections[1]) ) else ()
    let $result := if(contains($collections[1], 'getty')) then ( local-aat:searchSubjects($query, $startRecord, $page_limit) ) else ( rosids-subjects:searchSubjects($collections[1], $query, $startRecord, $page_limit) )
    let $nStartRecord := $startRecord - map:get($result, "total")
    let $nStartRecord := if( $nStartRecord < 1 ) then ( 1 ) else ( $nStartRecord )
    let $nPage_limit := $page_limit - count(map:get($result, "results"))
    let $log := if($app:debug) then ( util:log("INFO", "suggestCustomsSubjectsQuery: nStartRecord: " || $nStartRecord || " nPage_limit: " || $nPage_limit) ) else ()
    return ( $result, 
                if($nPage_limit > 0 and count(subsequence($collections, 2)) > 0 )
                then ( rosids-subjects-query:suggestCustomsSubjectsQuery($query, $nStartRecord, $nPage_limit, subsequence($collections, 2)))
                else ( () )
            )
};

(: Custom Repositories Query END:)


(: Default Repositories EXC + AAT :)
(:
  map:get($aat, "total")
  map:get($aat, "results")
  :)
declare function rosids-subjects-query:suggestSubjects($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $collection as xs:string) as item()* {
    let $subjects := rosids-subjects:searchSubjects($collection, $query, $startRecord, $page_limit)
    let $log := if($app:debug)
    then (
         ( util:log("INFO", "suggestSubjects: Count subjects: " || count(map:get($subjects, "results"))), util:log("INFO", "suggestSubjects: subjects in local repo: " ||  map:get($subjects, "total")) )
    ) else ()
    let $aStartRecord := $startRecord -  map:get($subjects, "total")
    let $aStartRecord := if( $aStartRecord < 1 ) then ( 1 ) else ( $aStartRecord )
    let $aPage_limit := $page_limit - count(map:get($subjects, "results"))
    let $log := if($app:debug)
    then (
        ( util:log("INFO", "suggestSubjects: startRecord: " || $startRecord || " page_limit: " || $page_limit), util:log("INFO", "suggestSubjects: aStartRecord: " || $aStartRecord || " aPage_limit: " || $aPage_limit) )
    ) else ()
    let $aat := local-aat:searchSubjects($query, $aStartRecord, $aPage_limit)
    let $log := if($app:debug) then ( util:log("INFO", "suggestSubjects: Count aat: " || count(map:get($aat, "results"))) ) else ()

    return 
        <result>
            <total>{  map:get($subjects, "total") + map:get($aat, "total")}</total>
            {( map:get($subjects, "results"), map:get($aat, "results")) }
        </result>
};