xquery version "3.0";
(:
    Local organisations search module.
    Search local repository and local VIAF mirror
:)

module namespace organisations="http://exist-db.org/xquery/biblio/services/search/local/organisations";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "../../app.xqm";

(: TEI namesspace :)
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare %private function organisations:searchNameLocal($query as xs:string) {
    let $results :=  doc($app:local-organisations-repositories)//tei:listOrg/tei:org[ngram:contains(tei:orgName, $query)]
    return
        for $result in $results
            let $orgName := if ( exists($result/tei:orgName[@type eq "preferred"]) ) then ( $result/tei:orgName[@type eq "preferred"] ) else ( $result/tei:orgName[1] )
            return 
                <suggestions value="{$orgName}" data="{$orgName}" bio="" resource="local"/>
};

declare %private function organisations:searchNameVIAF($query as xs:string) {
    <viaf/>
};

declare function organisations:searchName($query as xs:string) {
    <names>
        {organisations:searchNameLocal($query), organisations:searchNameVIAF($query)}
    </names>
};