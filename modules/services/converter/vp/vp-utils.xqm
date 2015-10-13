xquery version "3.0";
(:
    Converter and utils for vp nodes (Getty)
    Auhtor: zwobit
:)

module namespace vp-utils="http://github.com/hra-team/rosids-services/services/converter/vp/vp-utils";


(: Namespace :)
declare namespace vp = "http://localhost/namespace";


(:
    ### Utility functions ###
 :)
declare %private function vp-utils:extract_language($language) {
    if(contains($language, "/"))
    then (
        substring-after($language, "/")
    ) else (
        $language
    )
};

declare function vp-utils:getTermLanguages($termLanguages as element() ) as xs:string {
    let $extract_language := local:extract_language(?)
    let $languages := for-each($termLanguages/Term_Language/Language, $extract_language)
    return
        string-join($languages, ', ')
};

(: Get Descriptive_Notes for subject :)
declare function vp-utils:getDescriptiveNotes( $subject as element() ) as item()* {
    for $descriptiveNote in
        ( $subject/vp:Descriptive_Notes/vp:Descriptive_Note[vp:Note_Language = 'English'], $subject/vp:Descriptive_Notes/vp:Descriptive_Note[vp:Note_Language = 'German'])
    return
        element descriptiveNote{
            attribute value {$descriptiveNote/vp:Note_Text},
            attribute languages {$descriptiveNote/vp:Note_Language}
        }
};

(: Get Non-Preferred_Terms for subject :)
declare function vp-utils:getNonPreferredTerms( $subject as element() ) as element()* {
    for $nonPreferredTerm in $subject/vp:Terms/vp:Non-Preferred_Term
    return
        element nonPreferredTerms {
            attribute value {$nonPreferredTerm/vp:Term_Text[1]},
            attribute qualifiers {string-join($nonPreferredTerm/vp:Term_Languages/vp:Term_Language/vp:Qualifier, ', ')},
            if ($nonPreferredTerm/vp:Term_Languages)
            then (
                attribute languages {vp-utils:getTermLanguages($nonPreferredTerm/vp:Term_Languages)}
            ) else ()
        }
};

(: Get first Preferred_Term for subject :)
declare function vp-utils:getPreferredTerm( $subject as element() ) as attribute()* {
    let $preferredTerm := $subject/vp:Terms/vp:Preferred_Term[1]
    let $termText   := $preferredTerm/vp:Term_Text[1]
    let $qualifier  := $preferredTerm/vp:Term_Languages//vp:Term_Language[vp:Preferred = 'Preferred'][1]/vp:Qualifier
    let $languages  := vp-utils:getTermLanguages($preferredTerm/vp:Term_Languages)
    return
    (
        attribute value {$termText},
        if($qualifier) then ( attribute qualifiers {$qualifier} ) else (),
        if($languages) then ( attribute languages {$languages} ) else ()
    )
};

(: Get Hierarchy for subject :)
declare function vp-utils:getHierarchy( $subject as element() ) as item()* {
    for $hierarchy in $subject/vp:Hierarchy
    let $values := tokenize($hierarchy , '\|')
    let $trimmed := for $i in $values return normalize-space($i)
    let $value := string-join(reverse($trimed), ', ')
    return
        element hierarchy{
            attribute value {$value}
        }
    ) else ()

};

(:
 : ### Converter ###
 :)
