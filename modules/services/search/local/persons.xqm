xquery version "3.0";
(:
    Local persons search module.
    Search local repository and local VIAF mirror
:)

module namespace persons="http://exist-db.org/xquery/biblio/services/search/local/persons";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "../../app.xqm";

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
            return
                <person name="{$name}" viafID="{$viafID}" uuid="{$person/@id}" resource="local"/>
        
        
        
        (:
        let $persName := if (exists($result/tei:persName[@type eq "preferred"])) then ($result/tei:persName[@type eq "preferred"]) else ($result/tei:persName[1])
            return 
                if (exists($persName/tei:forename) or exists($persName/tei:surname))
                then (
                    let $person := 
                    return
                        <suggestions value="{$person}" data="{$person}" bio="" resource="local"/>
                ) else (
                    let $person := $persName/text()
                    return
                      <suggestions value="{$person}" data="{$person}" bio="" resource="local"/>
                )
        :)
};

declare %private function persons:searchNameVIAF($query as xs:string) {
    let $persons :=  doc($app:local-viaf-repositories)//ns2:VIAFCluster[ns2:nameType eq 'Personal' and ns2:mainHeadings/ns2:mainHeadingEl/ns2:datafield[ngram:contains(ns2:subfield, "arx") and ns2:subfield/@code eq 'a']]
    return
        for $person in $persons
        let $name := $person//ns2:mainHeadingEl[1]/ns2:datafield/ns2:subfield[@code eq 'a']
        return 
            <person name="{$name}" viafID="{$person/ns2:viafID}" uuid="" resource="viaf"/> 
    
};

declare %private function persons:filterResults($results) {
    <viaf1/>
};


declare %private function persons:processResults($query as xs:string) {
    (: <suggestions value="{$person}" data="{$person}" bio="" resource="local"/> :)
    <viaf2/>
};

declare function persons:searchName($query as xs:string) {
    (persons:searchNameLocal($query), persons:searchNameVIAF($query))
};