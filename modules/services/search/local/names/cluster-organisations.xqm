xquery version "3.0";
(:
    Local organisations search module.
    Search local repository and local VIAF mirror
:)

module namespace cluster-organisations="http://exist-db.org/xquery/biblio/services/search/local/names/cluster-organisations";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "../../../app.xqm";
import module namespace viaf-utils="http://exist-db.org/xquery/biblio/services/search/local/viaf-utils" at "../viaf-utils.xqm";

(: TEI namesspace :)
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: VIAF Terms :)
declare namespace ns2= "http://viaf.org/viaf/terms#"; 

declare function cluster-organisations:searchNames($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer) as item()*{
    let $organisations :=  doc($app:local-organisations-repositories)//tei:listOrg/tei:org[ngram:contains(tei:orgName, $query)]
    let $countOrganisations := count($organisations)
    return
        (
            $countOrganisations,
            if($startRecord = 1 or $countOrganisations > $startRecord)
            then (
                for $organisation in subsequence($organisations, $startRecord, $page_limit)
                    let $viafID := if( exists($organisation/tei:orgName/@ref[contains(., 'http://viaf.org/viaf/')]) )
                                   then (substring-after($organisation/tei:orgName/@ref[contains(., 'http://viaf.org/viaf/')], "http://viaf.org/viaf/"))
                                   else ()
                    let $name := if ( exists($organisation/tei:orgName[@type = "preferred"]) ) then ( $organisation/tei:orgName[@type = "preferred"] ) else ( $organisation/tei:orgName[1] )
                    let $viafCluster := if($viafID) then ( collection($app:local-viaf-xml-repositories)//ns2:VIAFCluster[ns2:viafID = $viafID] ) else ()
                    let $mainHeadingElement := if($viafID) then ( viaf-utils:getBestMatch($viafCluster//ns2:mainHeadingEl) ) else () 
                    let $sources := if($viafID) then ( viaf-utils:getSources($mainHeadingElement) ) else () 

                    return
                        element term {
                                attribute uuid {data($organisation/@xml:id)},
                                attribute type {'corporate'},
                                attribute value {$name},
                                attribute authority {'local'},
                                if($viafID) then (
                                    attribute id {$viafID},
                                    attribute sources {$sources}
                                ) else ()
                            }
            ) else ( () )
        )
};

