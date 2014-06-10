xquery version "3.0";

module namespace service-utils="http://exist-db.org/xquery/biblio/services/search/service-utils";

declare function service-utils:chars( $arg as xs:string? ) as xs:string* {
   for $ch in string-to-codepoints($arg)
    return codepoints-to-string($ch)
 };

declare function service-utils:genSubQueries($query as xs:string, $matchedQuery as xs:string, $queries as xs:string*) as xs:string* {
    (: let $log := util:log("INFO", "Q:" || $query || " M: " || $matchedQuery) :)
    let $result := if (string-length($query) < 3) 
                    then ($query)
                    else (
                        if (string-length($matchedQuery) = 0 )
                        then ( service-utils:genSubQueries($query, substring($query, 1, 3), (substring($query, 1, 3) )) )
                        else (
                            if( string-length($query) - string-length($matchedQuery) > 3 )
                            then (
                                let $next := substring( substring-after($query, $matchedQuery), 1, 3)
                                return
                                    service-utils:genSubQueries($query, concat($matchedQuery, $next), ($queries, $next ) ) 
                            )
                            else (
                                let $next := substring($query, string-length($query) - 2)
                                return ($queries, $next )
                            )
                        )
                    )
    return $result                   
};