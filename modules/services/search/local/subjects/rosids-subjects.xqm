xquery version "3.0";
(:
    Local subjects search module.
    Search local repository
:)

module namespace rosids-subjects="http://exist-db.org/xquery/biblio/services/search/local/subjects/rosids-subjects";

import module namespace app="http://www.betterform.de/projects/shared/config/app" at "/apps/cluster-shared/modules/ziziphus/config/app.xqm";

declare namespace mads = "http://www.loc.gov/mads/v2";

(:
 <mads xmlns="http://www.loc.gov/mads/v2" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/mads/ http://cluster-schemas.uni-hd.de/madsCluster.xsd" ID="UUID-0003cac6-c455-5478-af3b-e98c776bedbd">
        <authority lang="eng" script="Latn">
            <topic authority="AAT" lang="eng" script="Latn">air quality</topic>
        </authority>
:)
declare  function rosids-subjects:searchSubjects($collection as xs:string, $query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer) {
    let $log := if($app:debug) then ( util:log("INFO", "rosids-subject: collection: " || $collection) ) else ()
    let $log := if($app:debug) then ( util:log("INFO", "rosids-subject: query: " || $query) ) else ()
    let $config :=   if( doc-available($collection || $app:repositories-configuration) )
                            then ( doc($collection || $app:repositories-configuration) )
                            else if (contains($collection, 'global') ) then ( $app:global-subjects-repositories-configuration ) else ( $app:global-default-repositories-configuration )
                            (:
                                then ( $app:global-subjects-repositories-configuration )
                                else ( $app:global-default-repositories-configuration ) :)
    let $results := collection($collection)/mads:madsCollection/mads:mads[ ngram:contains(.//mads:topic, $query)]
    let $sorted-results :=
        for $item in $results
        order by upper-case(string($item/mads:authority/mads:topic/text()))
        return $item

    let $countResults := count($sorted-results)
    return map {
        "total" := $countResults,
        "results" :=
            if($startRecord = 1 or $countResults > $startRecord)
            then (
                for $result in subsequence($sorted-results, $startRecord, $page_limit)
                    let $relatedTerms := for $related in $result//mads:related return $related//mads:topic/text() || "(" || data($related//mads:topic/@authority) || ")"
                    let $relatedTerms := string-join($relatedTerms, " ")
                    return
                        element term {
                                attribute uuid {data($result/@ID)},
                                attribute type {'subject'},
                                attribute value {$result/mads:authority/mads:topic/text()},
                                attribute authority {$config//@authority},
                                attribute source {$config//@source},
                                attribute icon {$config//@icon},
                                if($relatedTerms) then (
                                    attribute relatedTerms {normalize-space($relatedTerms)}
                                ) else ()
                            }
            ) else ( () )
    }
};