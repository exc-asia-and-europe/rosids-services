xquery version "3.0";
(:
    Search repositories for id
:)

module namespace rosids-id="http://github.com/hra-team/rosids-services/services/search/local/id/rosids-id";

import module namespace app="http://github.com/hra-team/rosids-shared/config/app" at "/apps/rosids-shared/modules/ziziphus/config/app.xqm";

import module namespace rosids-converter="http://github.com/hra-team/rosids-services/services/search/utils/rosids-converter" at "/apps/rosids-services/modules/services/search/utils/rosids-converter.xqm";
import module namespace rosids-id-retrieve-viaf="http://github.com/hra-team/rosids-services/services/retrieve/viaf/rosids-id-retrieve-viaf" at "/apps/rosids-services/modules/services/retrieve/remote/viaf/id.xqm";

declare namespace ns2= "http://viaf.org/viaf/terms#";
declare namespace vp = "http://localhost/namespace";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace mads = "http://www.loc.gov/mads/v2";

declare namespace functx = "http://www.functx.com";

declare function functx:distinct-deep($nodes as node()*) as node()* {
    for $seq in (1 to count($nodes))
    return $nodes[$seq][not(functx:is-node-in-sequence-deep-equal(.,$nodes[position() < $seq]))]
};

declare function functx:is-node-in-sequence-deep-equal( $node as node()? , $seq as node()* )  as xs:boolean {
   some $nodeInSeq in $seq satisfies deep-equal($nodeInSeq,$node)
};

declare function rosids-id:id($query as xs:string, $type as xs:string) {
    let $log := util:log("INFO", "rosids-id:id" || $query || $type)
    let $result :=
        if(starts-with($query, 'uuid-'))
        then (
            rosids-id:id-cluster($query, $type)
        ) else (
            rosids-id:id-mirrors($query, $type)
        )
    return
        if( map:get($result, "total") != 0 )
        then (
            <result>
                <total>{ map:get($result, "total") }</total>
                { map:get($result, "results") }
            </result>
        ) else (
            <result><total>0</total></result>
        )
};

declare %private function rosids-id:id-cluster($query as xs:string, $type as xs:string) {
    let $terms := collection($app:repositories-collection)//id($query)
    return
        map {
            "total" := count($terms),
            "results" :=
                for $term in $terms
                return
                    switch (local-name($term))
                        case "person"
                            return rosids-converter:tei-person-2-rosids($term)
                        case "org"
                            return rosids-converter:tei-org-2-rosids($term)
                        case "mads"
                            return rosids-converter:mads-2-rosids($term, $type)
                        default
                            return ()
        }
};

declare %private function rosids-id:id-mirrors($query as xs:string, $type as xs:string) {
    let $results :=
        switch ($type)
            case "names"
            case "persons"
            case "organisations"
                return rosids-id:id-viaf($query)
            case "worktypes"
            case "styleperiods"
            case "techniques"
            case "materials"
            case "subjects"
            case "geographic"
            case "locations"
                return rosids-id:id-getty($query, $type)
            default
                return ()
    return
        if($results)
        then (
            map {
            "total" := count($results),
            "results" := $results


        }
        ) else (
            map {
            "total" := 0,
            "results" := ()
            }
        )
};

declare %private function rosids-id:id-viaf($query as xs:string) {
    let $terms :=  collection($app:global-viaf-xml-repositories)//ns2:VIAFCluster[ns2:viafID = $query]
    return
    if($terms)
    then (
        for $term in $terms
            return
                rosids-converter:VIAFCluster-2-rosids($term)
    ) else (
        let $remote := rosids-id-retrieve-viaf:retrieve($query)
        return
            if($remote)
            then (
                rosids-converter:VIAFCluster-2-rosids($remote)
            ) else ( () )
    )
};

declare function rosids-id:filter-getty($terms, $type) {
    switch ($type)
            case "worktypes"
            case "styleperiods"
            case "techniques"
            case "materials"
                return

                    let $facets := fn:tokenize(map:get($app:aat-facets, $type), ",")

                    let $filtered-terms :=
                        for $term in $terms
                        return
                            for $facet in $facets
                            return
                                if($term[starts-with(vp:Facet_Code, $facet)])
                                then (
                                    $term
                                ) else ()
                    return $filtered-terms
            case "subjects"
            case "geographic"
            case "locations"
                return $terms
            default
                return ()
};

declare %private function rosids-id:id-getty($query as xs:string, $type as xs:string) {
    let $terms := ( collection($app:global-getty-aat-repositories)//vp:Subject[@Subject_ID = $query], collection($app:global-getty-tgn-repositories)//vp:Subject[@Subject_ID = $query] )
    let $filtered_terms := rosids-id:filter-getty( $terms, $type)
    return
        if($filtered_terms)
        then (
            for $term in $filtered_terms
                let $authority := substring-after(util:collection-name($term), '/global/externalmirrors/getty/')
                let $authority := if(contains($authority, '/xml')) then ( substring-before($authority, '/xml') ) else ($authority)
                return
                    rosids-converter:getty-aat-2-rosids($term, $type, $authority)
        ) else ( () )
};


declare function rosids-id:id-getty-related-terms($query as xs:string, $type as xs:string) {
    let $terms := ( collection($app:global-getty-aat-repositories)//vp:Subject[range:eq(@Subject_ID, $query)], collection($app:global-getty-tgn-repositories)//vp:Subject[range:eq(@Subject_ID, $query)] )
    let $filtered_terms := rosids-id:filter-getty($terms , $type)

    return
        if($filtered_terms)
        then (
            for $term in $filtered_terms
                let $authority := substring-after(util:collection-name($term), '/global/externalmirrors/getty/')
                let $authority := if(contains($authority, '/xml')) then ( substring-before($authority, '/xml') ) else ($authority)
                return rosids-converter:get-aat-terms($term , $authority)
        ) else ()
};