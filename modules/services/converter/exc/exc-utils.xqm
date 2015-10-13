xquery version "3.0";
(:
    Converter and utils for tei:persName, tei:orgName and mads:mads nodes (EXC)
    Auhtor: zwobit
:)

module namespace exc-utils="http://github.com/hra-team/rosids-services/services/converter/exc/exc-utils";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace mads = "http://www.loc.gov/mads/v2";

declare %private function exc-utils:getName($person as element()) {
  let $persName :=
    if (exists($person/tei:persName[@type = "preferred"]))
    then (
      $person/tei:persName[@type = "preferred"]
    ) else (
      $person/tei:persName[1]
    )
  return
    if (exists($persName/tei:forename) and exists($persName/tei:surname))
    then (
      normalize-space( $persName/tei:surname/text() || ", " || $persName/tei:forename/text() )
    ) else (
      if ( exists($persName/tei:surname) )
      then (
        normalize-space( $persName/tei:surname/text() )
      ) else (
        if ( exists($persName/tei:forename) )
        then (
          normalize-space( $persName/tei:forename/text() )
        ) else (
           $persName/text()
        )
      )
    )
};

declare %private function exc-utils:getViafID($person as element()) {
  let $ref := $person/tei:persName/@ref[contains(., 'http://viaf.org/viaf/')]
  return
    if($ref)
    then (
        substring-after($ref, "http://viaf.org/viaf/")
      ) else (
        ()
      )
};

declare function rosids-converter:tei-person-2-rosids($person) {


    let $viafID := if( exists(]) ) then () else ()
    let $viafCluster :=
        if($viafID)
        then (
            (: collection($app:global-viaf-xml-repositories)//ns2:VIAFCluster[ns2:viafID = $viafID] :)
            rosids-id-retrieve-viaf:retrieve($viafID)
        ) else (
            ()
        )
    let $mainHeadingElement := if($viafID) then (  viaf-utils:getBestMatch($viafCluster) ) else ()
    let $sources := if($viafID) then (  'viaf ' || viaf-utils:getSources($mainHeadingElement) ) else ( '' )
    let $bio := if($viafID) then ( if($mainHeadingElement) then ( $mainHeadingElement/ns2:datafield/ns2:subfield[@code = 'd']) else () ) else ()
    return
        element term {
                attribute uuid {data($person/@xml:id)},
                attribute type {'personal'},
                attribute value {$name},
                attribute authority {'local'},
                attribute source {'EXC'},
                attribute icon {'local'},
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
            }
};
