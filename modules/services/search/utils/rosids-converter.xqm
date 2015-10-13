xquery version "3.0";

(:
    Convert various xml-elements, like tei:person, into rosids-term-elements
    Auhtor: zwobit
:)

module namespace rosids-converter="http://github.com/hra-team/rosids-services/services/search/utils/rosids-converter";

(: IMPORTS :)
import module namespace app="http://github.com/hra-team/rosids-shared/config/app" at "/apps/rosids-shared/modules/ziziphus/config/app.xqm";
import module namespace viaf-utils="http://github.com/hra-team/rosids-services/services/search/utils/viaf-utils" at "/apps/rosids-services/modules/services/search/utils/viaf-utils.xqm";
import module namespace local-getty="http://github.com/hra-team/rosids-services/services/search/local/subjects/local-getty" at "/apps/rosids-services/modules/services/search/local/subjects/local-getty.xqm";
import module namespace rosids-id-retrieve-viaf="http://github.com/hra-team/rosids-services/services/retrieve/viaf/rosids-id-retrieve-viaf" at "/apps/rosids-services/modules/services/retrieve/remote/viaf/id.xqm";
import module namespace rosids-id="http://github.com/hra-team/rosids-services/services/search/local/id/rosids-id" at "/apps/rosids-services/modules/services/search/local/id/rosids-id.xqm";

(: NAMESPACES :)
declare namespace ns2= "http://viaf.org/viaf/terms#";
declare namespace vp = "http://localhost/namespace";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace mads = "http://www.loc.gov/mads/v2";

declare function rosids-converter:tei-person-2-rosids($person) {
    let $persName := if (exists($person/tei:persName[@type = "preferred"])) then ($person/tei:persName[@type = "preferred"]) else ($person/tei:persName[1])
    let $name := if (exists($persName/tei:forename) and exists($persName/tei:surname))
                 then ( normalize-space( $persName/tei:surname/text() || ", " || $persName/tei:forename/text() ) )
                 else (
                     if ( exists($persName/tei:surname) )
                     then ( normalize-space( $persName/tei:surname/text() ))
                     else (
                         if ( exists($persName/tei:forename) )
                            then ( normalize-space( $persName/tei:forename/text() ))
                            else ( $persName/text() )
                     )
                 )
    let $viafID := if( exists($person/tei:persName/@ref[contains(., 'http://viaf.org/viaf/')]) ) then (substring-after($person/tei:persName/@ref[contains(., 'http://viaf.org/viaf/')], "http://viaf.org/viaf/")) else ()
    let $viafCluster :=
        if($viafID)
        then (
            (: collection($app:global-viaf-xml-repositories)//ns2:VIAFCluster[ns2:viafID = $viafID] :)
            rosids-id-retrieve-viaf:retrieve($viafID)
        ) else (
            ()
        )
    let $mainHeadingElement := if($viafID) then (  viaf-utils:getBestMatch($viafCluster) ) else ()
    let $sources := if($viafID) then (  'viaf ' || viaf-utils:getSources($mainHeadingElement) ) else ( '' )
    let $bio := if($viafID) then ( if($mainHeadingElement) then ( $mainHeadingElement/ns2:datafield/ns2:subfield[@code = 'd']) else () ) else ()
    return
        element term {
                attribute uuid {data($person/@xml:id)},
                attribute type {'personal'},
                attribute value {$name},
                attribute authority {'local'},
                attribute source {'EXC'},
                attribute icon {'local'},
                if($viafID) then (
                    attribute id {$viafID},
                    attribute sources {$sources},
                    if($bio) then (
                        attribute bio {$bio},
                        attribute earliestDate {viaf-utils:extractEarliestDate($bio[1])},
                        attribute latestDate {viaf-utils:extractLatestDate($bio[1])}
                    ) else (),
                    element mainHeadings {
                        for $data in $viafCluster/*:mainHeadings/*:data
                        let $sources := string-join($data/*:sources/*:s, ' ')
                        return
                            <term sources="{$sources}" value="{$data/*:text/text()}"/>
            }
                ) else ()
            }
};

declare function rosids-converter:tei-org-2-rosids($organisation) {
    let $viafID :=
        if( exists($organisation/tei:orgName/@ref[contains(., 'http://viaf.org/viaf/')]) )
        then (substring-after($organisation/tei:orgName/@ref[contains(., 'http://viaf.org/viaf/')], "http://viaf.org/viaf/")
        ) else (
            ()
        )
    let $name := if ( exists($organisation/tei:orgName[@type = "preferred"]) ) then ( $organisation/tei:orgName[@type = "preferred"] ) else ( $organisation/tei:orgName[1] )
    let $viafCluster := if($viafID) then ( collection($app:global-viaf-xml-repositories)//ns2:VIAFCluster[ns2:viafID = $viafID] ) else ()
    let $mainHeadingElement := if($viafID) then ( viaf-utils:getBestMatch($viafCluster//ns2:mainHeadingEl) ) else ()
    let $sources := if($viafID) then ( 'viaf ' || viaf-utils:getSources($mainHeadingElement) ) else ( '' )

    return
        element term {
                attribute uuid {data($organisation/@xml:id)},
                attribute type {'corporate'},
                attribute value {$name},
                attribute authority {'local'},
                attribute source {'EXC'},
                attribute icon {'local'},
                if($viafID) then (
                    attribute id {$viafID},
                    attribute sources {$sources}
                ) else ()
            }
};

declare function rosids-converter:mads-2-rosids($mads, $type) {
    rosids-converter:mads-2-rosids($mads, $type, $app:global-subjects-repositories-configuration)
};

declare %private function rosids-converter:getGettySubject($query as xs:string, $type) {
     switch ($type)
            case "worktypes"
            case "styleperiods"
            case "techniques"
            case "materials"
            case "subjects"
                return
                    let $terms := collection($app:global-getty-aat-repositories)//vp:Subject[range:eq(@Subject_ID,  xs:string($query))]
                    return rosids-id:filter-getty( $terms, $type)
            case "geographic"
            case "locations"
                return
                    let $terms := collection($app:global-getty-tgn-repositories)//vp:Subject[range:eq(@Subject_ID,  xs:string($query))]
                    return rosids-id:filter-getty( $terms, $type)
            default
                return ()
};


declare function rosids-converter:mads-2-rosids($mads, $type, $config) {
(:
    let $related-terms := for $related in $mads//mads:related return $related//mads:topic/text() || "(" || data($related//mads:topic/@authority) || ")"
    let $related-terms := string-join($relatedTerms, " ")
:)
    let $related-terms := rosids-converter:mads-releated-terms($mads)
    let $valueURI := $mads//mads:related/mads:topic[@valueURI]
    let $aatID := if( $valueURI[@authorityURI = 'https://kjc-fs1.kjc.uni-heidelberg.de/AATService/api/get.xml/'] )
        then ( data($valueURI[@authorityURI = 'https://kjc-fs1.kjc.uni-heidelberg.de/AATService/api/get.xml/']/@valueURI) ) else ()
    let $gettySubject :=  if($aatID)
        then ( rosids-converter:getGettySubject($aatID, $type)[1] ) else (())
    let $authority := substring-after(util:collection-name($gettySubject), '/global/externalmirrors/getty/')
    let $authority := if(contains($authority, '/xml')) then ( substring-before($authority, '/xml') ) else ($authority)
    let $related-terms :=
            rosids-converter:get-aat-terms($gettySubject , $authority)
    let $notes := rosids-converter:get-getty-descriptive-Notes($gettySubject, $authority)
    return
        element term {
                attribute uuid {data($mads/@ID)},
                attribute type {$type},
                attribute value {$mads/mads:authority/mads:topic/text()},
                attribute authority {$config//@authority},
                attribute source {$config//@source},
                attribute icon {$config//@icon},
                if($aatID) then (
                    attribute id {$aatID},
                    attribute sources {'aat'}
                ) else (),
                if($related-terms) then (
                    $related-terms
                ) else (),
                if($notes) then (
                    $notes
                ) else ()
            }
};


declare %private function rosids-converter:mads-releated-terms($mads) {
    for $related in $mads//mads:related
        return
            element relatedTerm {
                attribute value { $related//mads:topic/text() },
                attribute authority { data($related//mads:topic/@authority) },
                attribute languages { data($related/@lang)},
                attribute qualifiers { '' }
            }
};


declare function rosids-converter:VIAFCluster-2-rosids($VIAFCluster) {
    let $mainHeadingElement := viaf-utils:getBestMatch($VIAFCluster)
    let $nameTemp := ($mainHeadingElement/*:datafield/*:subfield[@code = 'a'])[1]
    let $nameTemp := normalize-space($nameTemp)
    let $name := if(ends-with($nameTemp, ',')) then ( substring($nameTemp, 1, string-length($nameTemp) -1 ) ) else ($nameTemp)
    let $sources := viaf-utils:getSources($mainHeadingElement)
    let $bio := ($mainHeadingElement/*:datafield/*:subfield[@code = 'd'])[1]
    let $relatedTerms := string-join(subsequence($VIAFCluster//*:mainHeadings//*:data/*:text, 1, 6), ' ')
    return
        element term {
            attribute id {$VIAFCluster/*:viafID},
            attribute type {lower-case($VIAFCluster/*:nameType)},
            attribute value {$name},
            attribute authority {'viaf'},
            attribute sources {$sources},
            attribute source {'viaf'},
            attribute icon {'viaf'},
            if($bio) then (
                attribute bio {viaf-utils:extractBio($bio)},
                attribute earliestDate {viaf-utils:extractEarliestDate($bio[1])},
                attribute latestDate {viaf-utils:extractLatestDate($bio[1])}
            ) else (),
            if ($relatedTerms) then (
                attribute relatedTerms { $relatedTerms }
            ) else (),
            element mainHeadings {
                for $data in $VIAFCluster/*:mainHeadings/*:data
                let $sources := string-join($data/*:sources/*:s, ' ')
                let $log := util:log("INFO", "VIAFCluster-2-rosids: " || $data/*:text/text() || " : " || $sources)
                return
                    <term sources="{$sources}" value="{$data/*:text/text()}"/>
            }
        }
};

(:
    declare function rosids-converter:getty-aat-2-rosids($Subject, $type, $authority) {
        let $pterm := $Subject/vp:Terms/vp:Preferred_Term[1]/vp:Term_Text[1]
        let $qualifier := $Subject/vp:Terms/vp:Preferred_Term[1]/vp:Term_Languages//vp:Term_Language[vp:Preferred eq 'Preferred'][1]/vp:Qualifier
        let $qterm := if($qualifier) then $pterm || ' (' || $qualifier || ')' else $pterm
        let $SubjectText := $pterm/vp:Term_Text[1]/text()
        let $sid := $Subject/@Subject_ID
        let $relatedTerms := "AAT " || $sid || ": " || local-getty:get-related-Terms($Subject)
        return
            element term {
                attribute id {$sid},
                attribute type {$type},
                attribute value {$qterm},
                attribute authority {$authority},
                attribute source {'getty'},
                attribute icon {'getty'},
                if($relatedTerms) then (
                    attribute relatedTerms { $relatedTerms }
                ) else ()
            }
    };
:)

(: NEU NEU NEU :)
declare function rosids-converter:getty-aat-2-rosids($subject, $type, $authority) {
    let $pterm := $subject/vp:Terms/vp:Preferred_Term[1]/vp:Term_Text[1]
    let $qualifier := rosids-converter:get-getty-qualifier($subject, $authority)
    let $languages := $subject/vp:Terms/vp:Preferred_Term[1]/vp:Term_Languages/vp:Term_Language/vp:Language
    let $languages := $subject/vp:Term_Languages/vp:Term_Language/vp:Language
    let $languages :=
        for $lang in $languages
        return
            if(contains($lang, '/'))
            then (
                substring-after($lang/vp:Term_Languages/vp:Term_Language/vp:Language, "/")
            ) else (
                $lang
            )
    let $sid := $subject/@Subject_ID
    let $real_type :=
         switch ($type)
            case "geographic"
            case "locations"
                return 'geographic'
            default
                return $type
    let $notes := rosids-converter:get-getty-descriptive-Notes($subject, $authority)
    let $related-terms := rosids-converter:get-getty-related-terms($subject, $authority)
    let $hierarchy := rosids-converter:get-getty-hierarchy($subject, $authority)
    return
        element term {
            attribute id {$sid},
            attribute type {$real_type},
            attribute value {$pterm},
            if($qualifier) then ( attribute qualifiers {$qualifier} ) else (),
            if($languages) then ( attribute languages {string-join($languages, ', ')} ) else (),
            attribute authority {$authority},
            attribute source {'getty'},
            attribute sources {'getty'},
            attribute icon {'getty'},
            $notes,
            $related-terms,
            $hierarchy
        }
};

declare function rosids-converter:get-aat-terms($subject, $authority) {
    (
        for $term in ( $subject/vp:Terms/vp:Preferred_Term, $subject/vp:Terms/vp:Non-Preferred_Term )
        return
            element relatedTerm {
                attribute value {$term/vp:Term_Text[1]},
                attribute authority {$authority},
                attribute qualifiers {string-join($term/vp:Term_Languages/vp:Term_Language/vp:Qualifier, ', ')},
                if($term/vp:Term_Languages/vp:Term_Language/vp:Language)
                then (
                    let $languages := $term/vp:Term_Languages/vp:Term_Language/vp:Language
                    let $languages := for $lang in $languages return if(contains($lang, '/')) then substring-after($lang/vp:Term_Languages/vp:Term_Language/vp:Language, "/") else $lang
                    return
                        attribute languages {string-join($languages, ', ')}
                ) else ()
            }
        ,rosids-converter:get-getty-related-terms($subject, $authority)
    )
};

declare %private function rosids-converter:get-getty-qualifier($subject, $authority) {
    if($authority = 'aat')
    then (
        $subject/vp:Terms/vp:Preferred_Term[1]/vp:Term_Languages//vp:Term_Language[vp:Preferred eq 'Preferred'][1]/vp:Qualifier
    ) else (
        substring-after($subject/vp:Place_Types/vp:Preferred_Place_Type[1]/vp:Place_Type_ID, '/')
    )
};

declare %private function rosids-converter:get-getty-hierarchy($subject, $authority) {
    if($authority = 'tgn')
    then (
        for $hierarchy in $subject/vp:Hierarchy
        let $values := tokenize($hierarchy , '\|')
        let $trimed := for $i in $values return normalize-space($i)
        let $value := string-join(reverse($trimed), ', ')
        return
            element hierarchy{
                attribute value {$value}
            }
    ) else ()

};

declare %private function rosids-converter:get-getty-descriptive-Notes($subject, $authority) {
    for $note in ( $subject/vp:Descriptive_Notes/vp:Descriptive_Note[vp:Note_Language = 'English'], $subject/vp:Descriptive_Notes/vp:Descriptive_Note[vp:Note_Language = 'German'])
    return
        element descriptiveNote{
            attribute value {$note/vp:Note_Text},
            attribute languages {$note/vp:Note_Language}
        }
};

declare %private function rosids-converter:get-getty-related-terms($subject, $authority) {
    for $term in $subject/vp:Terms/vp:Non-Preferred_Term
    return
        element relatedTerm {
            attribute value {$term/vp:Term_Text[1]},
            attribute authority {$authority},
            attribute qualifiers {string-join($term/vp:Term_Languages/vp:Term_Language/vp:Qualifier, ', ')},
            if($term/vp:Term_Languages/vp:Term_Language/vp:Language)
            then (
                let $languages := $term/vp:Term_Languages/vp:Term_Language/vp:Language
                let $languages := for $lang in $languages return if(contains($lang, '/')) then substring-after($lang/vp:Term_Languages/vp:Term_Language/vp:Language, "/") else $lang
                return
                    attribute languages {string-join($languages, ', ')}
            ) else ()
        }
};