xquery version "3.0";
(:
    Converter and utils for tei:persName, tei:orgName and mads:mads nodes (EXC)
    Auhtor: zwobit
:)

module namespace ns2-utils="http://github.com/hra-team/rosids-services/services/converter/ns2/ns2-utils";

(: Namespace :)
declare namespace ns2= "http://viaf.org/viaf/terms#";

(:
    ### Utility functions ###
:)

declare function ns2-utils:extractBio($bio as xs:string?) {
    if(matches($bio, '\([0-9]{4}\s:'))
    then (
        substring-before(substring-after($bio, '('), ' :')
    ) else ( $bio )
};

declare function ns2-utils:extractEarliestDate($bio as xs:string?) {
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

declare function ns2-utils:extractLatestDate($bio as xs:string?) {
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

declare function ns2-utils:countSources($mainHeadings as item()*) {
    let $count := count(?)
    let $sourcesCount := for-each($mainHeadings/*:data/*:sources, $count)
    return $sourcesCount
};

declare function ns2-utils:getBestMatchingMainHeadingEl($viafCluster) {
    let $maxCount :=  max(viaf-utils:countVIAFSources($viafCluster//*:mainHeadings))
    let $source := $viafCluster//*:mainHeadings/*:data/*:sources[count(*:s) = $maxCount]/*:s[1]
    let $mainHeadingElement := $viafCluster//*:mainHeadingEl[*:sources/*:s = $source]
    return $mainHeadingElement
};

(: JPG: GETTY ULAN, DNB: GND :)
declare function ns2-utils:getLinkSources($mainHeadingEl) {
    let $substring-before := substring-before(?, '|')
    let $sources := for-each($mainHeadingEl//*:links/*:link, $substring-before)
    return
      if( empty($sources) )
      then (
         ()
      ) else (
         string-join($sources, ' ')
      )
};

declare function ns2-utils:getMainHeadings($VIAFCluster as element()) as  element() {
  element mainHeadings {
      for $data in $VIAFCluster/*:mainHeadings/*:data
      let $sources := string-join($data/*:sources/*:s, ' ')
      return
          <term sources="{$sources}" value="{$data/*:text/text()}"/>
  }

}
(:
let $viafCluster :=
    if($viafID)
    then (
        rosids-id-retrieve-viaf:retrieve($viafID)
    ) else (
        ()
    )
let $mainHeadingElement := if($viafID) then (  viaf-utils:getBestMatch($viafCluster) ) else ()
let $sources := if($viafID) then (  'viaf ' || viaf-utils:getSources($mainHeadingElement) ) else ( '' )
let $bio := if($viafID) then ( if($mainHeadingElement) then ( $mainHeadingElement/ns2:datafield/ns2:subfield[@code = 'd']) else () ) else ()

if($viafID) then (
    attribute id {$viafID},
    attribute sources {$sources},
    if($bio) then (
        attribute bio {$bio},
        attribute earliestDate {viaf-utils:extractEarliestDate($bio[1])},
        attribute latestDate {viaf-utils:extractLatestDate($bio[1])}
    ) else (),
    element mainHeadings {
        for $data in $viafCluster/*:mainHeadings/*:data
        let $sources := string-join($data/*:sources/*:s, ' ')
        return
            <term sources="{$sources}" value="{$data/*:text/text()}"/>
    }
) else ()

declare function rosids-converter:VIAFCluster-2-rosids($VIAFCluster) {
    let $mainHeadingElement := viaf-utils:getBestMatch($VIAFCluster)
    let $nameTemp := ($mainHeadingElement/*:datafield/*:subfield[@code = 'a'])[1]
    let $nameTemp := normalize-space($nameTemp)
    let $name := if(ends-with($nameTemp, ',')) then ( substring($nameTemp, 1, string-length($nameTemp) -1 ) ) else ($nameTemp)
    let $sources := viaf-utils:getSources($mainHeadingElement)
    let $bio := ($mainHeadingElement/*:datafield/*:subfield[@code = 'd'])[1]
    let $relatedTerms := string-join(subsequence($VIAFCluster//*:mainHeadings//*:data/*:text, 1, 6), ' ')
    return
        element term {
            attribute id {$VIAFCluster/*:viafID},
            attribute type {lower-case($VIAFCluster/*:nameType)},
            attribute value {$name},
            attribute authority {'viaf'},
            attribute sources {$sources},
            attribute source {'viaf'},
            attribute icon {'viaf'},
            if($bio) then (
                attribute bio {viaf-utils:extractBio($bio)},
                attribute earliestDate {viaf-utils:extractEarliestDate($bio[1])},
                attribute latestDate {viaf-utils:extractLatestDate($bio[1])}
            ) else (),
            if ($relatedTerms) then (
                attribute relatedTerms { $relatedTerms }
            ) else (),

        }
};

:)
