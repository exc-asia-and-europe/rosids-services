xquery version "3.0";
(:
    Local persons search module.
    Search local repository and local VIAF mirror
:)

module namespace persons="http://exist-db.org/xquery/biblio/services/search/local/persons";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "../../app.xqm";

(: TEI namesspace :)
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare %private function persons:searchNameLocal($query as xs:string) {
    let $results :=  doc($app:local-persons-repositories)//tei:listPerson/tei:person[ngram:contains(tei:persName, $query)]
    return
        for $result in $results
            let $persName := if (exists($result/tei:persName[@type eq "preferred"])) then ($result/tei:persName[@type eq "preferred"]) else ($result/tei:persName[1])
            return 
                if (exists($persName/tei:forename) or exists($persName/tei:surname))
                then (
                    let $person := $persName/tei:forename/text() || " " || $persName/tei:surname
                    return
                        <suggestions value="{$person}" data="{$person}" bio="" resource="local"/>
                ) else (
                    let $person := $persName/text()
                    return
                      <suggestions value="{$person}" data="{$person}" bio="" resource="local"/>
                ) 
};

declare %private function persons:searchNameVIAF($query as xs:string) {
    <viaf/>
};

declare function persons:searchName($query as xs:string) {
    (persons:searchNameLocal($query), persons:searchNameVIAF($query))
};