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

declare %private function persons:extractEarliestDate($bio as xs:string) {
    if(contains($bio, '-'))
    then (
        let $temp := substring-before($bio, '-')
        return
            if(contains($temp, '('))
            then (
                    substring-after($temp, '(')
            ) else ( $temp )                                
    ) else ( $bio )
};

declare %private function persons:extractLatestDate($bio as xs:string) {
   if(contains($bio, '-'))
    then (
        let $temp := substring-after($bio, '-')
        return
            if(contains($temp, ')'))
            then (
                    substring-after($temp, ')')
            ) else ( $temp )
    ) else ( '' )
};
declare %private function persons:searchNameLocal($query as xs:string) {
    let $persons :=  doc($app:local-persons-repositories)//tei:listPerson/tei:person[ngram:contains(tei:persName, $query)]
    return
        for $person in $persons
            let $persName := if (exists($person/tei:persName[@type eq "preferred"])) then ($person/tei:persName[@type eq "preferred"]) else ($person/tei:persName[1])
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
            let $viafID := if( exists($person/tei:persName/@ref[contains(., 'http://viaf.org/viaf/')]) ) then (substring-after($person/tei:persName/@ref[contains(., 'http://viaf.org/viaf/')], "http://viaf.org/viaf/")) else ("")
            let $viafCluster := collection($app:local-viaf-xml-repositories)//ns2:VIAFCluster[ns2:viafID eq $viafID]
            let $mainHeadingElement := viaf-utils:getBestMatch($viafCluster//ns2:mainHeadingEl)
            let $sources := viaf-utils:getSources($mainHeadingElement)
            let $bio := if($mainHeadingElement) then ( $mainHeadingElement/ns2:datafield/ns2:subfield[@code eq 'd']) else ('')
            let $earliestDate := persons:extractEarliestDate($bio)
            let $latestDate := persons:extractLatestDate($bio)
            return
                <name name="{$name}" internalID="{$viafID}" bio="{$bio}" uuid="{data($person/@xml:id)}" resource="local" type="person" sources="{$sources}" latestDate="{$latestDate}" earliestDate="{$earliestDate}"/>
};

(: TODO: Test getty :)
declare  function persons:searchNameULAN($query as xs:string) {
   let $results :=  collection($app:local-getty-ulan-repositories)//vp:Subject[ ngram:contains(.//vp:Term_Text, $query)][ vp:Record_Type eq 'Person' ]
   return
      for $result in $results
            let $person := if ( exists($result//vp:Preferred_Term) ) then ( $result//vp:Preferred_Term[1] ) else ( $result//vp:Non-Preferred_Term[1] )
            let $subjectID := data( $result/@Subject_ID )
            let $persName := $person/vp:Term_Text[1]/text()
            let $bio := if ( exists($result//vp:Preferred_Biography) ) then ( $result//vp:Preferred_Biography[1] ) else ( $result//vp:Non-Preferred_Biography[1] )
            let $bioText := $bio//vp:Biography_Text[1]
            let $earliestDate := persons:extractEarliestDate($bioText)
            let $latestDate := persons:extractLatestDate($bioText)
            return 
                <name name="{$persName}" internalID="{$subjectID}" bio="{$bioText}" uuid="" resource="ulan" type="person" sources="jpg" latestDate="{$latestDate}" earliestDate="{$earliestDate}"/>
                
};

declare %private function persons:searchNameVIAF($query as xs:string, $local-viaf-ids as item()*) {
    let $persons :=  collection($app:local-viaf-xml-repositories)//ns2:VIAFCluster[ns2:nameType eq 'Personal'
                                                                        and ns2:mainHeadings/ns2:mainHeadingEl/ns2:datafield[ngram:contains(ns2:subfield, $query) and ns2:subfield/@code eq 'a']]
    return
        for $person in $persons
        let $mainHeadingElement := viaf-utils:getBestMatch($person//ns2:mainHeadingEl)
        let $nameTemp := normalize-space($mainHeadingElement/ns2:datafield/ns2:subfield[@code eq 'a'])
        let $name := if(ends-with($nameTemp, ',')) then ( substring($nameTemp, 1, string-length($nameTemp) -1 ) ) else ($nameTemp)
        let $sources := viaf-utils:getSources($mainHeadingElement)
        let $bio := $mainHeadingElement/ns2:datafield/ns2:subfield[@code eq 'd']
        let $earliestDate := persons:extractEarliestDate($bio)
        let $latestDate := persons:extractLatestDate($bio)
        return
            if (index-of($local-viaf-ids, $person/ns2:viafID) > 0)
            then ()
            else (
                <name name="{$name}" internalID="{$person/ns2:viafID}" bio="{$bio}" uuid="" resource="viaf" type="person" sources="{$sources}" latestDate="{$latestDate}" earliestDate="{$earliestDate}"/> 
            )
};

declare %private function persons:filterResults($results) {
    <viaf1/>
};


declare %private function persons:processResults($query as xs:string) {
    <viaf2/>
};

declare function persons:searchName($query as xs:string) {
    let $local-persons := persons:searchNameLocal($query)
    (: VIAF contains getty :)
    (: let $ulan-persons := persons:searchNameULAN($query) :)
    let $viaf-persons := persons:searchNameVIAF($query, data($local-persons//@viafID))
    return 
        ($local-persons, $viaf-persons)
};