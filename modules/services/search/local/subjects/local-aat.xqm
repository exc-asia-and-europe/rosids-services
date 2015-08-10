xquery version "3.0";

(:
    Local aat search module.
    Search local repository
:)


module namespace local-aat="http://github.com/hra-team/rosids-services/services/search/local/subjects/local-aat";

import module namespace app="http://github.com/hra-team/rosids-shared/config/app" at "/apps/rosids-shared/modules/ziziphus/config/app.xqm";
import module namespace rosids-converter="http://github.com/hra-team/rosids-services/services/search/utils/rosids-converter" at "/apps/rosids-services/modules/services/search/utils/rosids-converter.xqm";

(: Getty namespace :)
declare namespace vp = "http://localhost/namespace"; 

declare %private function local-aat:search($query as xs:string, $type as xs:string) {
    if($type ne 'subjects') 
    then (
        let $facets := map:get($app:aat-facets, $type) 
        for $facet in fn:tokenize($facets, ",")
        return 
            collection($app:global-getty-aat-repositories)//vp:Subject[starts-with(vp:Facet_Code, $facet)]/vp:Terms/vp:Preferred_Term[ ngram:contains(vp:Term_Text, $query)]/ancestor::vp:Subject
    ) else (
        collection($app:global-getty-aat-repositories)//vp:Subject/vp:Terms/vp:Preferred_Term[ ngram:contains(vp:Term_Text, $query)]/ancestor::vp:Subject
    )
};



declare function local-aat:searchSubjects($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $type as xs:string) {
    let $log := if($app:debug) then ( util:log("INFO", "local-aat:searchSubject: QUERY: " || $query) ) else ()
    let $subjects := local-aat:search($query, $type)
    let $sorted-subjects :=
        for $item in $subjects
        order by upper-case(string($item/vp:Terms/vp:Preferred_Term[1]/vp:Term_Text[1]))
        return $item
    let $countSubjects := count($sorted-subjects)
    return map {
        "total" := $countSubjects,
        "results" :=
            if($startRecord = 1 or $countSubjects > $startRecord)
            then (
                for $subject in subsequence($sorted-subjects, $startRecord, $page_limit)
                let $authority := substring-after(util:collection-name($subject), '/global/externalmirrors/getty/')
                let $authority := if(contains($authority, '/xml')) then ( substring-before($authority, '/xml') ) else ($authority)
                return 
                    rosids-converter:getty-aat-2-rosids($subject, $type, $authority)
            ) else ( () )
    }
};

declare function local-aat:get-related-Terms($subject) {
    let $relatedTerms := 
        for $relatedTerm in $subject/vp:Terms/vp:Non-Preferred_Term
            let $text := $relatedTerm/vp:Term_Text
            let $qualifier := $relatedTerm/vp:Term_Languages/vp:Term_Language[vp:Qualifier][1]/vp:Qualifier
        return
            if($qualifier) then $text || ' (' || $qualifier || ')' else $text
    return 
        normalize-space(string-join($relatedTerms, "; "))
};