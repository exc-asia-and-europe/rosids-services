xquery version "3.0";
(:
    Local persons search module.
    Search local repository and local VIAF mirror
:)

(: TODO:
        - rename dates to bio
        - integrate getty
:)

module namespace persons="http://exist-db.org/xquery/biblio/services/search/local/persons";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "../../app.xqm";
import module namespace viaf-utils="http://exist-db.org/xquery/biblio/services/search/local/viaf-utils" at "viaf-utils.xqm";

(: TEI namesspace :)
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: VIAF Terms :)
declare namespace ns2= "http://viaf.org/viaf/terms#";

(: Getty namespace :)
declare namespace vp = "http://localhost/namespace"; 

declare %private function local:is-value-in-sequence ( $value as xs:anyAtomicType? , $seq as xs:anyAtomicType* ) as xs:boolean {
   $value = $seq
};
 
declare function persons:searchNameLocal($query as xs:string, $startRecord, $maximumRecords) as item()* {
    let $persons :=  doc($app:local-persons-repositories)//tei:listPerson/tei:person[ngram:contains(tei:persName, $query)]
    let $totalLocalPersons := count($persons)
    return
        if($startRecord = 1 or $totalLocalPersons > $startRecord)
        then (
                $totalLocalPersons,
                for $person in subsequence($persons, $startRecord, $startRecord + $maximumRecords)
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
                let $internalID := if( exists($person/tei:persName/@ref[contains(., 'http://viaf.org/viaf/')]) ) then (substring-after($person/tei:persName/@ref[contains(., 'http://viaf.org/viaf/')], "http://viaf.org/viaf/")) else ("xxx")
                let $viafCluster := collection($app:local-viaf-xml-repositories)//ns2:VIAFCluster[ns2:viafID = $internalID]
                let $mainHeadingElement := viaf-utils:getBestMatch($viafCluster//ns2:mainHeadingEl)
                let $sources := viaf-utils:getSources($mainHeadingElement)
                let $bio := if($mainHeadingElement) then ( $mainHeadingElement/ns2:datafield/ns2:subfield[@code = 'd']) else ('')
                let $earliestDate := viaf-utils:extractEarliestDate($bio)
                let $latestDate := viaf-utils:extractLatestDate($bio)
                return
                    <name name="{$name}" internalID="{$internalID}" bio="{$bio}" uuid="{data($person/@xml:id)}" resource="local" type="personal" sources="{$sources}" latestDate="{$latestDate}" earliestDate="{$earliestDate}"/>
            )
        else ( ($totalLocalPersons, () ) )    
        
        
};

(: TODO: Test getty :)
declare  function persons:searchNameULAN($query as xs:string) {
   let $results :=  collection($app:local-getty-ulan-repositories)//vp:Subject[ ngram:contains(.//vp:Term_Text, $query)][ vp:Record_Type = 'Person' ]
   return
      for $result in $results
            let $person := if ( exists($result//vp:Preferred_Term) ) then ( $result//vp:Preferred_Term[1] ) else ( $result//vp:Non-Preferred_Term[1] )
            let $subjectID := data( $result/@Subject_ID )
            let $persName := $person/vp:Term_Text[1]/text()
            let $bio := if ( exists($result//vp:Preferred_Biography) ) then ( $result//vp:Preferred_Biography[1] ) else ( $result//vp:Non-Preferred_Biography[1] )
            let $bioText := $bio//vp:Biography_Text[1]
            let $earliestDate := viaf-utils:extractEarliestDate($bioText)
            let $latestDate := viaf-utils:extractLatestDate($bioText)
            return 
                <name name="{$persName}" internalID="{$subjectID}" bio="{$bioText}" uuid="" resource="ulan" type="personal" sources="jpg" latestDate="{$latestDate}" earliestDate="{$earliestDate}"/>
                
};

declare function persons:searchNameVIAF($query as xs:string, $local-viaf-ids as item()*, $startRecord, $maximumRecords) as item()* {
        let $persons :=  collection($app:local-viaf-xml-repositories)//ns2:mainHeadings/ns2:mainHeadingEl/ns2:datafield[ngram:contains(ns2:subfield, $query)]/ancestor::ns2:VIAFCluster
        let $filteredPersons := $persons[not(local:is-value-in-sequence(ns2:viafID,$local-viaf-ids))]
        let $totalVIAFPersons := count($filteredPersons)
        let $subPersons := subsequence($filteredPersons , $startRecord, $startRecord + $maximumRecords)
        return
            (
              $totalVIAFPersons,  
                for $person in $subPersons
                return
                    let $mainHeadingElement := viaf-utils:getBestMatch($person//ns2:mainHeadingEl)
                    let $nameTemp := normalize-space($mainHeadingElement/ns2:datafield/ns2:subfield[@code = 'a'])
                    let $name := if(ends-with($nameTemp, ',')) then ( substring($nameTemp, 1, string-length($nameTemp) -1 ) ) else ($nameTemp)
                    let $sources := viaf-utils:getSources($mainHeadingElement)
                    let $bio := $mainHeadingElement/ns2:datafield/ns2:subfield[@code = 'd']
                    let $earliestDate := viaf-utils:extractEarliestDate($bio)
                    let $latestDate := viaf-utils:extractLatestDate($bio)
                    return
                    <name name="{$name}" internalID="{$person/ns2:viafID}" bio="{$bio}" uuid="" resource="viaf" type="personal" sources="{$sources}" latestDate="{$latestDate}" earliestDate="{$earliestDate}"/> 
            )
};

declare %private function persons:filterResults($results) {
    <viaf1/>
};


declare %private function persons:processResults($query as xs:string) {
    <viaf2/>
};

declare function persons:searchName($query as xs:string, $startRecord, $maximumRecords ) as item()* {
    let $local-persons := persons:searchNameLocal($query, $startRecord, $maximumRecords)
    let $totalLocalPersons := $local-persons[1]
    let $localPersons := count(subsequence($local-persons, 2)/name)
    let $maximumVIAFRecords := $maximumRecords - $localPersons
    let $startVIAFRecords := $startRecord - ($totalLocalPersons + $localPersons)
    let $log := util:log("INFO", "Vstart " || $startVIAFRecords || " Vmax " || $maximumVIAFRecords || " tLPersons " || $totalLocalPersons || " Lpersons " || $localPersons)
    let $viaf-persons := if($maximumVIAFRecords > 0) then (persons:searchNameVIAF($query, data(subsequence($local-persons, 2)//@internalID), $startVIAFRecords, $maximumVIAFRecords)) else ( (0, ()) )
    (: let $personsAllCount := $local-persons[1] + $viaf-persons[1] :)
    
    return
        <data>
            <total>{$viaf-persons[1]}</total>
            <names>
                {subsequence($local-persons, 2), subsequence($viaf-persons, 2)}
            </names>
        </data>
};