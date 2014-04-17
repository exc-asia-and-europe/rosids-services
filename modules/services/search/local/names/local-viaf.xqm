xquery version "3.0";

module namespace local-viaf="http://exist-db.org/xquery/biblio/services/search/local/names/local-viaf";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "../../../app.xqm";
import module namespace viaf-utils="http://exist-db.org/xquery/biblio/services/search/local/viaf-utils" at "../viaf-utils.xqm";

(: VIAF Terms :)
declare namespace ns2= "http://viaf.org/viaf/terms#";

declare %private function local:is-value-in-sequence ( $value as xs:anyAtomicType? , $seq as xs:anyAtomicType* ) as xs:boolean {
   $value = $seq
};

declare function local-viaf:searchNames($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $local-viaf-ids  as item()*) as item()* {
    let $terms :=  collection($app:local-viaf-xml-repositories)//ns2:mainHeadings/ns2:mainHeadingEl/ns2:datafield[ngram:contains(ns2:subfield, $query)]/ancestor::ns2:VIAFCluster
    let $filteredTerms := $terms[not(local:is-value-in-sequence(ns2:viafID,$local-viaf-ids))]
    let $countTerms := count($filteredTerms)
    return
            (
                $countTerms,
                if($startRecord = 1 or $countTerms > $startRecord)
                then (
                    for $term in subsequence($filteredTerms, $startRecord, $page_limit)
                    return
                        let $mainHeadingElement := viaf-utils:getBestMatch($term//ns2:mainHeadingEl)
                        let $nameTemp := normalize-space($mainHeadingElement/ns2:datafield/ns2:subfield[@code = 'a'])
                        let $name := if(ends-with($nameTemp, ',')) then ( substring($nameTemp, 1, string-length($nameTemp) -1 ) ) else ($nameTemp)
                        let $sources := viaf-utils:getSources($mainHeadingElement)
                        let $bio := $mainHeadingElement/ns2:datafield/ns2:subfield[@code = 'd']
                        return
                            element term {
                                attribute id {$term/ns2:viafID},
                                attribute type {lower-case($term/ns2:nameType)},
                                attribute value {$name},
                                attribute authority {'viaf'},
                                attribute sources {$sources},
                                if($bio) then (
                                    attribute bio {$bio},
                                    attribute earliestDate {viaf-utils:extractEarliestDate($bio)},
                                    attribute latestDate {viaf-utils:extractLatestDate($bio)}
                                ) else ()
                            }
                ) else ( () )
            )
};


declare function local-viaf:searchPersonsNames($query as xs:string, $local-viaf-ids  as item()*) as item()* {
let $terms :=  collection($app:local-viaf-xml-repositories)//ns2:mainHeadings/ns2:mainHeadingEl/ns2:datafield[ngram:contains(ns2:subfield, $query)]/ancestor::ns2:VIAFCluster
    
    
    return 
        $terms
    
};


declare function local-viaf:searchOrganisationsNames($query as xs:string, $local-viaf-ids  as item()*) as item()* {
let $terms :=  collection($app:local-viaf-xml-repositories)//ns2:mainHeadings/ns2:mainHeadingEl/ns2:datafield[ngram:contains(ns2:subfield, $query)]/ancestor::ns2:VIAFCluster
    
    
    return 
        $terms
    
};