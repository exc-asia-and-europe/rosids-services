xquery version "3.0";

module namespace remote-viaf="http://exist-db.org/xquery/biblio/services/search/remote/names/remote-viaf";

import module namespace httpclient ="http://exist-db.org/xquery/httpclient";
import module namespace viaf-utils="http://exist-db.org/xquery/biblio/services/search/utils/viaf-utils" at "../../utils/viaf-utils.xqm";

declare namespace srw = "http://www.loc.gov/zing/srw/";

declare function remote-viaf:searchNames($query as xs:string, $startRecord as xs:integer, $page_limit as xs:integer, $local-viaf-ids  as item()*) as item()* {
    let $uri-persons := 'http://viaf.org/viaf/search?query=+local.personalNames+' || encode-for-uri('=') || '+' || encode-for-uri('"' ||$query || '"') || '&amp;httpAccept=application/xml&amp;startRecord=' || $startRecord || '&amp;maximumRecords=' || $page_limit
    let $uri-organisations := 'http://viaf.org/viaf/search?query=+local.corporateNames+' || encode-for-uri('=') || '+' || encode-for-uri('"' ||$query || '"') || '&amp;httpAccept=application/xml&amp;startRecord=' || $startRecord || '&amp;maximumRecords=' || $page_limit
    let $response-persons := httpclient:get(xs:anyURI($uri-persons), true(), ())//srw:searchRetrieveResponse
    let $response-organisations := httpclient:get(xs:anyURI($uri-organisations), true(), ())//srw:searchRetrieveResponse
    let $countTerms := $response-persons/srw:numberOfRecords/text() + $response-organisations/srw:numberOfRecords/text()
    let $terms :=  ($response-persons//*:VIAFCluster , $response-organisations//*:VIAFCluster)
    return map {
        "total" := $countTerms,
        "results" :=
                for $term in $terms
                     return
                         let $mainHeadingElement := viaf-utils:getBestMatch($term//*:mainHeadingEl)
                         let $nameTemp := normalize-space($mainHeadingElement/*:datafield/*:subfield[@code = 'a'])
                         let $name := if(ends-with($nameTemp, ',')) then ( substring($nameTemp, 1, string-length($nameTemp) -1 ) ) else ($nameTemp)
                         let $sources := viaf-utils:getSources($mainHeadingElement)
                         let $bio := $mainHeadingElement/*:datafield/*:subfield[@code = 'd']
                         return
                             element term {
                                 attribute id {$term/*:viafID},
                                 attribute type {lower-case($term/*:nameType)},
                                 attribute value {$name},
                                 attribute authority {'viaf'},
                                 attribute sources {$sources},
                                 attribute source {'viaf'},
                                 attribute icon {'viaf'},
                                 if($bio) then (
                                     attribute bio {$bio},
                                     attribute earliestDate {viaf-utils:extractEarliestDate($bio)},
                                     attribute latestDate {viaf-utils:extractLatestDate($bio)}
                                 ) else ()
                             }
    }
};



