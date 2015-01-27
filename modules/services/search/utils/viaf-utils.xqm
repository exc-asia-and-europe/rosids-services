xquery version "3.0";
(:
    Utilities for local viaf searches.
:)

module namespace viaf-utils="http://exist-db.org/xquery/biblio/services/search/utils/viaf-utils";

import module namespace app="http://www.betterform.de/projects/shared/config/app" at "/apps/cluster-shared/modules/ziziphus/config/app.xqm";


declare function viaf-utils:extractBio($bio as xs:string?) {
    if(matches($bio, '\([0-9]{4}\s:'))
    then (
        substring-before(substring-after($bio, '('), ' :')
    ) else ( $bio )
};

declare function viaf-utils:extractEarliestDate($bio as xs:string?) {
    if (empty($bio))
    then ( '' ) else (
        if(contains($bio, '-'))
        then (
            let $temp := substring-before($bio, '-')
            return
                if(contains($temp, '('))
                then (
                        substring-after($temp, '(')
                ) else ( $temp )                                
        ) else ( 
            if(matches($bio, '\([0-9]{4}\s:'))
            then (
                substring-before(substring-after($bio, '('), ' :')
            ) else ( $bio )
        )
    ) 
};

declare function viaf-utils:extractLatestDate($bio as xs:string?) {
   if (empty($bio))
   then ( '' ) else (
       if(contains($bio, '-'))
        then (
            let $temp := substring-after($bio, '-')
            return
                if(contains($temp, ')'))
                then (
                        substring-after($temp, ')')
                ) else ( $temp )
        ) else ( '' )
   )
};

declare function viaf-utils:countVIAFSources($mainHeadings as item()*) {
    let $sourcesCount := for $sources in $mainHeadings/*:data/*:sources
        return count($sources/*:s)
    return $sourcesCount
};

declare function viaf-utils:getBestMatch($viafCluster) {
    let $maxCount :=  max(viaf-utils:countVIAFSources($viafCluster//*:mainHeadings))
    let $source := $viafCluster//*:mainHeadings/*:data/*:sources[count(*:s) = $maxCount]/*:s[1]
    let $mainHeadingElement := $viafCluster//*:mainHeadingEl[*:sources/*:s = $source]
    return $mainHeadingElement
};

(: JPG: GETTY ULAN, DNB: GND :)
declare function viaf-utils:getSources($mainHeadingEl) {
    let $sources := for $source in $mainHeadingEl//*:links/*:link return substring-before($source/text(), '|')
    return if( empty($sources) ) then ( () ) else ( string-join($sources, ' ') )
};


