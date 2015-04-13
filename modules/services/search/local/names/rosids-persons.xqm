xquery version "3.0";

module namespace rosids-persons="http://github.com/hra-team/rosids-services/services/search/local/names/rosids-persons";

import module namespace app="http://github.com/hra-team/rosids-shared/config/app" at "/apps/rosids-shared/modules/ziziphus/config/app.xqm";
import module namespace viaf-utils="http://github.com/hra-team/rosids-services/services/search/utils/viaf-utils" at "../../utils/viaf-utils.xqm";
import module namespace rosids-converter="http://github.com/hra-team/rosids-services/services/search/utils/rosids-converter" at "../../utils/rosids-converter.xqm";

(: TEI namesspace :)
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: VIAF Terms :)
declare namespace ns2= "http://viaf.org/viaf/terms#";


declare function rosids-persons:searchNames($collection as xs:string, $query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer) as item()* {
    let $persons :=  collection($collection)//tei:listPerson/tei:person[ngram:contains(tei:persName, $query)]
    (: TODO: enable User/Group-collection support for persons :)
    let $persons-users := collection($app:users-repositories-collection)//tei:listPerson/tei:person[ngram:contains(tei:persName, $query)]
    let $persons-combined := ($persons, $persons-users)
    let $sorted-persons :=
        for $item in $persons-combined
        order by upper-case(string(if (exists($item/tei:persName[@type = "preferred"])) then ($item/tei:persName[@type = "preferred"]) else ($item/tei:persName[1])))
        return $item
    let $countPersons := count($sorted-persons)
    return map {
        "total" := $countPersons,
        "results" :=
            if($startRecord = 1 or $countPersons > $startRecord)
            then (
                for $person in subsequence($sorted-persons, $startRecord, $page_limit)
                return 
                    rosids-converter:tei-person-2-rosids($person)
                (:
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
                (: let $viafCluster := if($viafID) then ( collection($app:global-viaf-xml-repositories)//ns2:VIAFCluster[ns2:viafID = $viafID] ) else ():)
                let $viafCluster := if($viafID) then ( rosids-id-retrieve-viaf:retrieve($viafID) ) else ()
                let $mainHeadingElement := if($viafID) then (  viaf-utils:getBestMatch($viafCluster//ns2:mainHeadingEl) ) else ()
                let $sources := if($viafID) then (  'viaf ' || viaf-utils:getSources($mainHeadingElement) ) else ()
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
                                    attribute earliestDate {viaf-utils:extractEarliestDate($bio)},
                                    attribute latestDate {viaf-utils:extractLatestDate($bio)}
                                ) else ()
                            ) else ()
                        }
                :)
            ) else ( () )
        }
};