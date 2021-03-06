xquery version "3.0";
(:
    Local organisations search module.
    Search local repository and local VIAF mirror
:)

module namespace organisations="http://exist-db.org/xquery/biblio/services/search/local/organisations";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "../../app.xqm";
import module namespace viaf-utils="http://exist-db.org/xquery/biblio/services/search/local/viaf-utils" at "viaf-utils.xqm";

(: TEI namesspace :)
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: VIAF Terms :)
declare namespace ns2= "http://viaf.org/viaf/terms#"; 

declare %private function organisations:searchNameLocal($query as xs:string) {
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

declare %private function organisations:searchNameVIAF($query as xs:string, $local-viaf-ids as item()*) {
    let $organisations :=  collection($app:local-viaf-xml-repositories)//ns2:VIAFCluster[ns2:nameType = 'Corporate'
                                                                        and ns2:mainHeadings/ns2:mainHeadingEl/ns2:datafield[ngram:contains(ns2:subfield, $query) and ns2:subfield/@code = 'a']]
    return
        for $organisation in $organisations
        let $mainHeadingElement := viaf-utils:getBestMatch($organisation//ns2:mainHeadingEl)
        let $name := $mainHeadingElement/ns2:datafield/ns2:subfield[@code = 'a']
        let $bio := $mainHeadingElement/ns2:datafield/ns2:subfield[@code = 'd']
        let $earliestDate := viaf-utils:extractEarliestDate($bio)
        let $latestDate := viaf-utils:extractLatestDate($bio)
        let $sources := viaf-utils:getSources($mainHeadingElement)

        return
            if (index-of($local-viaf-ids, $organisation/ns2:viafID) > 0)
            then ()
            else (
                <name name="{$name}" internalID="{$organisation/ns2:viafID}" bio="{$bio}" earliestDate="{$earliestDate}" latestDate="{$latestDate}" uuid="" resource="viaf" type="corporate" sources="{$sources}" hint=""/> 
            )
};

declare function organisations:searchName($query as xs:string, $startRecord, $maximumRecords) {
    let $local-organisations := organisations:searchNameLocal($query)
    let $viaf-organisations := organisations:searchNameVIAF($query, data($local-organisations//@viafID))
    return 
        ($local-organisations, $viaf-organisations)
};

