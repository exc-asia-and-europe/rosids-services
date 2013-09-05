xquery version "3.0";
(:
    Local persons search module.
    Search local repository and local VIAF mirror
:)

module namespace persons="http://exist-db.org/xquery/biblio/services/search/local/persons";

declare %private% function persons:searchNameLocal($query as xs:string)
    <local/>
};

declare %private% function persons:searchNameVIAF($query as xs:string) {
    <viaf/>
}

declare function persons:searchName($query as xs:string)
    <names>
        {persons:searchNameLocal($query), persons:searchNameVIAF($query)}
    </names>
};