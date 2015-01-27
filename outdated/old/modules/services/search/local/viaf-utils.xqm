xquery version "3.0";
(:
    Utilities for local viaf searches.
:)

module namespace viaf-utils="http://exist-db.org/xquery/biblio/services/search/local/viaf-utils";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "../../app.xqm";

(: VIAF Terms :)
declare namespace ns2= "http://viaf.org/viaf/terms#"; 

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
        ) else ( $bio )
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

declare %private function viaf-utils:countVIAFLinks($mainHeadingElements as item()*) {
    let $linksCount := for $mainHeadingElement in $mainHeadingElements
                        return count($mainHeadingElement/ns2:links/ns2:link)
    return $linksCount
};

declare function viaf-utils:getBestMatch($mainHeadingElements as item()*) {
    let $maxCount := max(viaf-utils:countVIAFLinks($mainHeadingElements))
    let $mainHeadingElement := $mainHeadingElements[count(ns2:links/ns2:link) = $maxCount][1]
    return $mainHeadingElement
};

(: JPG: GETTY ULAN, DNB: GND :)
declare function viaf-utils:getSources($mainHeadingEl) {
    let $sources := for $source in $mainHeadingEl//ns2:links/ns2:link return substring-before($source/text(), '|')
    return if( empty($sources) ) then ( () ) else ( 'viaf ' || string-join($sources, ' ') )
};


