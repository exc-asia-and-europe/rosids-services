xquery version "3.0";

module namespace names="http://exist-db.org/xquery/biblio/services/search/local/names";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "../../app.xqm";
import module namespace viaf-utils="http://exist-db.org/xquery/biblio/services/search/local/viaf-utils" at "viaf-utils.xqm";

(: TEI namesspace :)
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: VIAF Terms :)
declare namespace ns2= "http://viaf.org/viaf/terms#";

declare %private function local:is-value-in-sequence ( $value as xs:anyAtomicType? , $seq as xs:anyAtomicType* ) as xs:boolean {
   $value = $seq
};

declare function names:searchPersonsLocal($query as xs:string, $startRecord, $maximumRecords) as item()* {
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

declare function names:searchOrganisations($query as xs:string, $startRecord, $maximumRecords, $local-viaf-ids as item()* ) as item()* {
    let $organisations := names:searchOrganisationsLocal($query, $startRecord, $maximumOrganisations)
    let $totalOrganisations := $organisations[1]
    
    let $countPersons := count(subsequence($persons, 2)/name)
    let $countOrganisations := count(subsequence($organisations, 2)/name)
    return ""
};

declare %private function names:searchOrganisationsLocal($query as xs:string, $startRecord, $maximumRecords) {
    let $organisations :=  doc($app:local-organisations-repositories)//tei:listOrg/tei:org[ngram:contains(tei:orgName, $query)]
    return
        for $organisation in $organisations
            let $viafID := if( exists($organisation/tei:orgName/@ref[contains(., 'http://viaf.org/viaf/')]) )
                           then (substring-after($organisation/tei:orgName/@ref[contains(., 'http://viaf.org/viaf/')], "http://viaf.org/viaf/"))
                           else ("")
            let $name := if ( exists($organisation/tei:orgName[@type = "preferred"]) ) then ( $organisation/tei:orgName[@type = "preferred"] ) else ( $organisation/tei:orgName[1] )
            let $viafCluster := collection($app:local-viaf-xml-repositories)//ns2:VIAFCluster[ns2:viafID = $viafID]
            let $mainHeadingElement := viaf-utils:getBestMatch($viafCluster//ns2:mainHeadingEl)
            let $sources := viaf-utils:getSources($mainHeadingElement)
            return
                <name name="{$name}" internalID="{$viafID}" bio="" earliestDate="" latestDate="" uuid="{data($organisation/@xml:id)}" resource="local" type="corporate" sources="{$sources}" hint=""/>
};

declare function names:searchNameVIAF($query as xs:string, $local-viaf-ids as item()*, $startRecord, $maximumRecords) as item()* {
        let $terms :=  collection($app:local-viaf-xml-repositories)//ns2:mainHeadings/ns2:mainHeadingEl/ns2:datafield[ngram:contains(ns2:subfield, $query)]/ancestor::ns2:VIAFCluster
        let $filteredTerms := $terms[not(local:is-value-in-sequence(ns2:viafID,$local-viaf-ids))]
        let $totalVIAFTerms := count($filteredTerms)
        let $subTerms := subsequence($filteredTerms , $startRecord, $startRecord + $maximumRecords)
        return
            (
              $totalVIAFTerms,  
                for $term in $subTerms
                return
                    let $mainHeadingElement := viaf-utils:getBestMatch($term//ns2:mainHeadingEl)
                    let $nameTemp := normalize-space($mainHeadingElement/ns2:datafield/ns2:subfield[@code = 'a'])
                    let $name := if(ends-with($nameTemp, ',')) then ( substring($nameTemp, 1, string-length($nameTemp) -1 ) ) else ($nameTemp)
                    let $sources := viaf-utils:getSources($mainHeadingElement)
                    let $bio := $mainHeadingElement/ns2:datafield/ns2:subfield[@code = 'd']
                    let $earliestDate := viaf-utils:extractEarliestDate($bio)
                    let $latestDate := viaf-utils:extractLatestDate($bio)
                    let $type := lower-case($term/ns2:nameType)
                    return
                    <name name="{$name}" internalID="{$person/ns2:viafID}" bio="{$bio}" uuid="" resource="viaf" type="{$type}" sources="{$sources}" latestDate="{$latestDate}" earliestDate="{$earliestDate}"/> 
            )
};

declare function names:searchName($query as xs:string, $startRecord, $maximumRecords ) as item()* {
    let $persons := names:searchPersonsLocal($query, $startRecord, $maximumRecords)
    let $totalPersons := $persons[1]
    let $countPersons := count(subsequence($persons, 2)/name)
    let $maximumOrganisations := $maximumRecords - ($totalPersons - $startRecord)
    let $startRecordOrganisations := $startRecord - $totalPersons
    let $organisationsAndVIAFTerms := if($maximumRecords +  $startRecord < $totalPersons ) then ( () ) else ( names:searchOrganisations($query, $startRecordOrganisations, $maximumOrganisations, data(subsequence($local-persons, 2)//@internalID) ) )
    (:
    let $maximumOrganisations := $maximumRecords - $countPersons
    let $startOrganisations := if($startRecord < ($totalPersons) then ($startRecord) else () + $countPersons)
    let $organisations := names:searchOrganisationsLocal($query, $startRecord, $maximumOrganisations)
    let $totalOrganisations := $organisations[1]
    
    let $countPersons := count(subsequence($persons, 2)/name)
    let $countOrganisations := count(subsequence($organisations, 2)/name)
    
    let $maximumVIAFRecords := $maximumRecords - $localPersons
    let $startVIAFRecords := $startRecord - ($totalLocalPersons + $localPersons)
    let $log := util:log("INFO", "Vstart " || $startVIAFRecords || " Vmax " || $maximumVIAFRecords || " tLPersons " || $totalLocalPersons || " Lpersons " || $localPersons)
    let $viaf-termns := if($maximumVIAFRecords > 0) then (names:searchNameVIAF($query, data(subsequence($local-persons, 2)//@internalID), $startVIAFRecords, $maximumVIAFRecords)) else ( (0, ()) )
    :)
    return
        <data>
            <total>{$viaf-persons[1]}</total>
            <names>
                {subsequence($local-persons, 2), subsequence($organisationsAndVIAFTerms, 2)}
            </names>
        </data>
};