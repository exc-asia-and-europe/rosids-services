xquery version "3.0";
(:
    Remote VIAF persons search module.
:)

module namespace viaf-persons="http://exist-db.org/xquery/biblio/services/search/remote/viaf/viaf-persons";

(: VIAF Terms :)
declare namespace ns2= "http://viaf.org/viaf/terms#"; 

declare function viaf-persons:searchVIAFRepository($query as xs:string) {
    <viaf-remote/>
}