xquery version "3.0";
(:
    Local subjects search module.
    Search local repository
:)

module namespace subjects="http://exist-db.org/xquery/biblio/services/search/local/subjects";

declare function subjects:searchLocalRepository($query as xs:string)
    <local/>
};