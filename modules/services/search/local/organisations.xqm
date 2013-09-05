xquery version "3.0";
(:
    Local organisations search module.
    Search local repository and local VIAF mirror
:)

module namespace organisations="http://exist-db.org/xquery/biblio/services/search/local/organisations";

declare %private% function organisations:searchNameLocal($query as xs:string)
    <local/>
};

declare %private% function organisations:searchNameVIAF($query as xs:string) {
    <viaf/>
}

declare function organisations:searchName($query as xs:string)
    <names>
        {organisations:searchNameLocal($query), organisations:searchNameVIAF($query)}
    </names>
};