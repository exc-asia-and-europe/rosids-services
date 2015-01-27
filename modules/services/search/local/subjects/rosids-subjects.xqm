xquery version "3.0";
(:
    Local subjects search module.
    Search local repository
:)

module namespace rosids-subjects="http://exist-db.org/xquery/biblio/services/search/local/subjects/rosids-subjects";

import module namespace app="http://www.betterform.de/projects/shared/config/app" at "/apps/cluster-shared/modules/ziziphus/config/app.xqm";
import module namespace rosids-converter="http://exist-db.org/xquery/biblio/services/rosids/rosids-converter" at "/apps/rosids-services/modules/services/search/utils/rosids-converter.xqm";

declare namespace mads = "http://www.loc.gov/mads/v2";

(:
 <mads xmlns="http://www.loc.gov/mads/v2" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/mads/ http://cluster-schemas.uni-hd.de/madsCluster.xsd" ID="UUID-0003cac6-c455-5478-af3b-e98c776bedbd">
        <authority lang="eng" script="Latn">
            <topic authority="AAT" lang="eng" script="Latn">air quality</topic>
        </authority>
:)

declare %private function rosids-subjects:load-configuration($type) {
    let $config := switch ($type)
        case "worktypes"
            return $app:global-worktypes-repositories-configuration
        case "styleperiods"
            return $app:global-styleperiods-repositories-configuration
        case "techniques"
            return $app:global-techniques-repositories-configuration
        case "materials"
            return $app:global-materials-repositories-configuration
        case "subjects"
            return $app:global-subjects-repositories-configuration
        default
            return $app:global-default-repositories-configuration
            
    return $config
};

declare  function rosids-subjects:searchSubjects($collection as xs:string, $query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $type as xs:string) {
    let $log := if($app:debug) then ( util:log("INFO", "rosids-subject: collection: " || $collection) ) else ()
    let $log := if($app:debug) then ( util:log("INFO", "rosids-subject: query: " || $query) ) else ()
    let $config :=   if( doc-available($collection || $app:repositories-configuration) )
                            then ( doc($collection || $app:repositories-configuration) )
                            else if (contains($collection, 'global')) then ( rosids-subjects:load-configuration($type) ) else ( $app:global-default-repositories-configuration )
    let $results := collection($collection)//mads:mads[ ngram:contains(.//mads:topic, $query)]
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
                    return
                        rosids-converter:mads-2-rosids($result, $type)
            ) else ( () )
    }
};