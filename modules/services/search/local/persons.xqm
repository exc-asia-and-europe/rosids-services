xquery version "3.0";
(:
    Local persons search module.
    Search local repository and local VIAF mirror
:)

module namespace persons="http://exist-db.org/xquery/biblio/services/search/local/persons";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "../../app.xqm";
import module namespace viaf-utils="http://exist-db.org/xquery/biblio/services/search/local/viaf-utils" at "viaf-utils.xqm";

(: TEI namesspace :)
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: VIAF Terms :)
declare namespace ns2= "http://viaf.org/viaf/terms#"; 

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
            let $viafCluster := doc($app:local-viaf-repositories)//ns2:VIAFCluster[ns2:viafID eq $viafID]
            let $mainHeadingElement := viaf-utils:getBestMatch($viafCluster//ns2:mainHeadingEl)
            let $dates := $mainHeadingElement/ns2:datafield/ns2:subfield[@code eq 'd']
            return
                <name name="{$name}" viafID="{$viafID}" dates="{$dates}" uuid="{data($person/@xml:id)}" resource="local" type="person"/>
};

declare %private function persons:searchNameVIAF($query as xs:string, $local-viaf-ids as item()*) {
    let $persons :=  doc($app:local-viaf-repositories)//ns2:VIAFCluster[ns2:nameType eq 'Personal'
                                                                        and ns2:mainHeadings/ns2:mainHeadingEl/ns2:datafield[ngram:contains(ns2:subfield, $query) and ns2:subfield/@code eq 'a']]
    return
        for $person in $persons
        let $mainHeadingElement := viaf-utils:getBestMatch($person//ns2:mainHeadingEl)
        let $name := $mainHeadingElement/ns2:datafield/ns2:subfield[@code eq 'a']
        let $dates := $mainHeadingElement/ns2:datafield/ns2:subfield[@code eq 'd']
        return
            if (index-of($local-viaf-ids, $person/ns2:viafID) > 0)
            then ()
            else (
                <name name="{$name}" viafID="{$person/ns2:viafID}" dates="{$dates}" uuid="" resource="viaf" type="person"/> 
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
    let $viaf-persons := persons:searchNameVIAF($query, data($local-persons//@viafID))
    return 
        ($local-persons, $viaf-persons)
};