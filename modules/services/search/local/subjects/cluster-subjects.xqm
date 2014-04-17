xquery version "3.0";
(:
    Local subjects search module.
    Search local repository
:)


module namespace cluster-subjects="http://exist-db.org/xquery/biblio/services/search/local/subjects/cluster-subjects";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "../../../app.xqm";

declare namespace mads = "http://www.loc.gov/mads/v2";

(:
 <mads xmlns="http://www.loc.gov/mads/v2" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/mads/ http://cluster-schemas.uni-hd.de/madsCluster.xsd" ID="UUID-0003cac6-c455-5478-af3b-e98c776bedbd">
        <authority lang="eng" script="Latn">
            <topic authority="AAT" lang="eng" script="Latn">air quality</topic>
        </authority>
:)
declare  function cluster-subjects:searchSubjects($query as xs:string) {
    let $results :=  collection($app:local-subjects-repositories-collection)/madsCollection/mads:mads[ ngram:contains(.//mads:topic, $query)]
    return (
        count($results),
        for $result in $results
            let $relatedTerms := for $related in $result//mads:related return $related//mads:topic/text() || "(" || data($related//mads:topic/@authority) || ")"
            let $relatedTerms := string-join($relatedTerms, " ")
            return
                element term {
                        attribute uuid {data($result/@ID)},
                        attribute type {'subject'},
                        attribute value {$result/mads:authority/mads:topic/text()},
                        attribute authority {'local'},
                        if($relatedTerms) then (
                            attribute relatedTerms {normalize-space($relatedTerms)}
                        ) else ()
                    }
        )
};