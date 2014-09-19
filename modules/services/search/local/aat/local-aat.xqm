xquery version "3.0";

(:
    Local aat search module.
    Search local repository
:)


module namespace local-aat="http://exist-db.org/xquery/biblio/services/search/local/aat/local-aat";

import module namespace app="http://www.betterform.de/projects/shared/config/app" at "/apps/cluster-shared/modules/ziziphus/config/app.xqm";

declare namespace mads = "http://www.loc.gov/mads/v2";

(: Getty namespace :)
declare namespace vp = "http://localhost/namespace"; 

declare %private function local-aat:search($query as xs:string, $factes as xs:string) {
    for $facet in fn:tokenize($factes, ",")
        return 
            collection($app:global-getty-aat-repositories)//vp:Subject[starts-with(vp:Facet_Code, $facet)]/vp:Terms/vp:Preferred_Term[ ngram:contains(vp:Term_Text, $query)]/ancestor::vp:Subject
};

declare function local-aat:searchSubject($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $type as xs:string) {
    let $facets := map:get($app:aat-facets, $type) 
    let $log := if($app:debug) then ( util:log("INFO", "local-aat:searchSubject: QUERY: " || $query) ) else ()
    (: let $subjects :=  collection($app:global-getty-aat-repositories)//vp:Subject[starts-with(vp:Facet_Code, $facet)]/vp:Terms/vp:Preferred_Term[ ngram:contains(vp:Term_Text, $query)]/ancestor::vp:Subject :)
    let $subjects := local-aat:search($query, $facets)
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
                    let $pterm := $subject/vp:Terms/vp:Preferred_Term[1]/vp:Term_Text[1]
                    let $qualifier := $subject/vp:Terms/vp:Preferred_Term[1]/vp:Term_Languages//vp:Term_Language[vp:Preferred eq 'Preferred'][1]/vp:Qualifier
                    let $qterm := if($qualifier) then $pterm || ' (' || $qualifier || ')' else $pterm
                    let $subjectText := $pterm/vp:Term_Text[1]/text()
                    (: let $relatedTerms := normalize-space(string-join($subject/vp:Terms//vp:Term_Text, "; ")) :)
                    (: let $relatedTerms := if($qualifier) then $pterm || ' (' || $qualifier || '), ' || normalize-space($relatedTerms) else normalize-space($relatedTerms) :)
                    let $sid := $subject/@Subject_ID
                    let $relatedTerms := "AAT " || $sid || ": " || local-aat:get-related-Terms($subject)
                    return
                        element term {
                            attribute id {$sid},
                            attribute type {$type},
                            attribute value {$qterm},
                            attribute authority {'aat'},
                            attribute source {'getty'},
                            attribute icon {'getty'},
                            if($relatedTerms) then (
                                attribute relatedTerms { $relatedTerms }
                            ) else ()
                        }
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