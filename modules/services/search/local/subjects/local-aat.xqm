xquery version "3.0";
(:
    Local subjects search module.
    Search local repository
:)


module namespace local-aat="http://exist-db.org/xquery/biblio/services/search/local/subjects/local-aat";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "../../app.xqm";

declare namespace mads = "http://www.loc.gov/mads/v2";

(: Getty namespace :)
declare namespace vp = "http://localhost/namespace"; 

declare function local-aat:searchSubjects($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer) {
    (:    let $terms :=  collection($app:local-getty-aat-repositories)//vp:Subject/vp:Terms/*[ngram:contains(vp:Term_Text, $query)]/ancestor::vp:Subject :)
    let $subjects :=  collection($app:local-getty-aat-repositories)//vp:Subject/vp:Terms/vp:Preferred_Term[ ngram:contains(vp:Term_Text, $query)]/ancestor::vp:Subject
    let $sorted-subjects :=
        for $item in $subjects
        order by upper-case(string($item/vp:Terms/vp:Preferred_Term[1]/vp:Term_Text[1]))
        return $item
    
    let $countSubjects := count($sorted-subjects)
    return
    (   
        $countSubjects,
        if($startRecord = 1 or $countSubjects > $startRecord)
        then (
            for $subject in subsequence($sorted-subjects, $startRecord, $page_limit)
                let $pterm := $subject/vp:Terms/vp:Preferred_Term[1]/vp:Term_Text[1]
                let $subjectText := $pterm/vp:Term_Text[1]/text()
                let $relatedTerms := string-join($subject/vp:Terms//vp:Term_Text, ", ")
                return
                    element term {
                        attribute id {$subject/@Subject_ID},
                        attribute type {'subject'},
                        attribute value {$subject/vp:Terms/vp:Preferred_Term[1]/vp:Term_Text[1]},
                        attribute authority {''},
                        attribute sources {'getty'},
                        if($relatedTerms) then (
                            attribute relatedTerms {normalize-space($relatedTerms)}
                        ) else ()
                    }
        ) else ( () )
    )
};
