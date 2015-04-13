xquery version "3.0";

module namespace remote-viaf="http://github.com/hra-team/rosids-services/services/search/remote/names/remote-viaf";

import module namespace viaf-utils="http://github.com/hra-team/rosids-services/services/search/utils/viaf-utils" at "../../utils/viaf-utils.xqm";
import module namespace rosids-converter="http://github.com/hra-team/rosids-services/services/search/utils/rosids-converter" at "/apps/rosids-services/modules/services/search/utils/rosids-converter.xqm";
import module namespace rosids-id-retrieve-viaf="http://github.com/hra-team/rosids-services/services/retrieve/viaf/rosids-id-retrieve-viaf" at "/apps/rosids-services/modules/services/retrieve/remote/viaf/id.xqm";

import module namespace httpclient ="http://exist-db.org/xquery/httpclient";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";

declare namespace srw = "http://www.loc.gov/zing/srw/";
declare namespace functx = "http://www.functx.com";

declare %private function remote-viaf:is-value-in-sequence ( $value as xs:anyAtomicType? , $seq as xs:anyAtomicType* ) as xs:boolean {
   $value = $seq
};

declare function functx:is-value-in-sequence( $value as xs:anyAtomicType?, $seq as xs:anyAtomicType*) as xs:boolean {
   $value = $seq
};

declare function functx:get-matches($string as xs:string?, $regex as xs:string ) as xs:string* {
    functx:get-matches-and-non-matches($string,$regex)/string(self::match)
};

declare function functx:get-matches-and-non-matches
  ( $string as xs:string? ,
    $regex as xs:string )  as element()* {

   let $iomf := functx:index-of-match-first($string, $regex)
   return
   if (empty($iomf))
   then <non-match>{$string}</non-match>
   else
   if ($iomf > 1)
   then (<non-match>{substring($string,1,$iomf - 1)}</non-match>,
         functx:get-matches-and-non-matches(
            substring($string,$iomf),$regex))
   else
   let $length :=
      string-length($string) -
      string-length(functx:replace-first($string, $regex,''))
   return (<match>{substring($string,1,$length)}</match>,
           if (string-length($string) > $length)
           then functx:get-matches-and-non-matches(
              substring($string,$length + 1),$regex)
           else ())
 } ;
 
 declare function functx:replace-first
  ( $arg as xs:string? ,
    $pattern as xs:string ,
    $replacement as xs:string )  as xs:string {

   replace($arg, concat('(^.*?)', $pattern),
             concat('$1',$replacement))
 } ;
 
 
declare function functx:index-of-match-first
  ( $arg as xs:string? ,
    $pattern as xs:string )  as xs:integer? {

  if (matches($arg,$pattern))
  then string-length(tokenize($arg, $pattern)[1]) + 1
  else ()
 } ;
 
 declare function functx:substring-before-last-match
  ( $arg as xs:string? ,
    $regex as xs:string )  as xs:string? {

   replace($arg,concat('^(.*)',$regex,'.*'),'$1')
 } ;

declare %private function remote-viaf:generate-search-uri($type as xs:string, $query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $exact_mode as xs:string) {
    let $base-uri := 'http://viaf.org/viaf/search?query='
    let $postfix-uri := '&amp;sortKeys=holdingscount&amp;httpAccept=application/xml&amp;startRecord=' || $startRecord || '&amp;maximumRecords=' || $page_limit
    return 
    if($exact_mode  eq 'true')
    then (
        $base-uri || 'local.names+exact+' || encode-for-uri('"' ||$query || '"') || $postfix-uri
    ) else (
        if($type eq 'persons' )
        then (
            $base-uri || 'local.personalNames+' || encode-for-uri('=')  || '+' || encode-for-uri('"' ||$query || '"') || $postfix-uri
        ) else ( 
            $base-uri || 'local.corporateNames+' || encode-for-uri('=')  || '+' || encode-for-uri('"' ||$query || '"') || $postfix-uri
        )
    )
};

declare function remote-viaf:searchNames1($type, $query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $local-viaf-ids  as item()*, $exact_mode as xs:string) as item()* {
    let $uri := remote-viaf:generate-search-uri($type, $query, $startRecord, $page_limit, $exact_mode)
    let $log := util:log("INFO", "URI: " || $uri)
    
    let $response := httpclient:get($uri, true(), ())//srw:searchRetrieveResponse
    let $countTerms := $response/srw:numberOfRecords/text()
    let $terms := $response//*:VIAFCluster 
    let $log := util:log("INFO", "Count: " || $countTerms || 'Response: ' || count($terms))
    let $filteredTerms := if($countTerms > 0) then ( $terms[not(remote-viaf:is-value-in-sequence(*:viafID,$local-viaf-ids))] ) else ()
    return map {
        "total" := $countTerms,
        "results" :=
                if($startRecord = 1 or $countTerms > $startRecord)
                then (
                    for $term in $filteredTerms
                    return
                        rosids-converter:VIAFCluster-2-rosids($term)
                ) else ( () ) 
    }
};


declare function remote-viaf:searchNames($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $local-viaf-ids  as item()*) as item()* {
    let $uri := "http://viaf.org/viaf/AutoSuggest?query=" || encode-for-uri($query)
    let $response := httpclient:get(xs:anyURI($uri), true(), ())
    let $body := xqjson:parse-json(util:base64-decode($response/httpclient:body/text()))
    return map {
            "total" := count($body//item),
            "results" := 
            for $item in $body//item
            let $viaf-cluster := rosids-id-retrieve-viaf:retrieve($item/pair[@name = 'viafid']/text())
            return 
                rosids-converter:VIAFCluster-2-rosids($viaf-cluster)
        }
};

declare function remote-viaf:searchNames2($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $local-viaf-ids  as item()*) as item()* {
    let $uri := "http://viaf.org/viaf/AutoSuggest?query=" || encode-for-uri($query)
    let $response := httpclient:get(xs:anyURI($uri), true(), ())
    let $body := xqjson:parse-json(util:base64-decode($response/httpclient:body/text()))
    let $filter := ('term', 'nametype', 'viafid')
    let $filtered-items := $body//item[not(remote-viaf:is-value-in-sequence(pair[@name="viafid"]/text(),$local-viaf-ids))]
    let $sorted-items :=
        for $item in $filtered-items
        order by upper-case(replace(functx:substring-before-last-match($item/pair[@name="term"]/text(), ',\s\d'), ',', ''))
        return $item
    return
        map {
            "total" := count($sorted-items),
            "results" := 
            for $item in subsequence($sorted-items, $startRecord, $page_limit)
                let $bio := replace(data($item/pair[@name="term"]), '^\D*', '')
                let $sources := string-join($item/pair/@name[not(functx:is-value-in-sequence(., $filter))], ' ') 
                return 
                    element term {
                    attribute uuid {$item/pair[@name="viafid"]/text()},
                    attribute type {$item/pair[@name="nametype"]/text()},
                    attribute value {functx:substring-before-last-match($item/pair[@name="term"]/text(), ',\s\d')},
                    attribute authority {'viaf'},
                    attribute source {'viaf'},
                    attribute icon {'viaf'},
                    attribute sources { $sources },
                    if($bio)
                    then (
                        attribute bio {$bio},
                        attribute earliestDate {viaf-utils:extractEarliestDate($bio)},
                        attribute latestDate {viaf-utils:extractLatestDate($bio)}
                    ) else ( () )
                }
        }
};