xquery version "3.0";
(:
    Local subjects search module.
    Search local repository
:)


module namespace subjects="http://exist-db.org/xquery/biblio/services/search/local/subjects";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "../../app.xqm";

declare namespace mads = "http://www.loc.gov/mads/v2";

(: Getty namespace :)
declare namespace vp = "http://localhost/namespace"; 

(:
 <mads xmlns="http://www.loc.gov/mads/v2" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/mads/ http://cluster-schemas.uni-hd.de/madsCluster.xsd" ID="UUID-0003cac6-c455-5478-af3b-e98c776bedbd">
        <authority lang="eng" script="Latn">
            <topic authority="AAT" lang="eng" script="Latn">air quality</topic>
        </authority>
:)
declare  %private function subjects:searchSubjectLocal($query as xs:string) {
    let $results :=  collection($app:local-subjects-repositories-collection)/madsCollection/mads:mads[ ngram:contains(.//mads:topic, $query)]
    for $result in $results
        let $subject := $result/mads:authority/mads:topic/text()
        let $internalID := data($result/@ID)
        let $hints := for $related in $result//mads:related return $related//mads:topic/text() || "(" || data($related//mads:topic/@authority) || ")"
        let $hint := string-join($hints, " ")
        let $log := util:log("INFO", $hint)
        return
            <subject name="{$subject}" internalID="{$internalID}" bio="" uuid="{$internalID}" resource="local" type="subject" sources="" hint="{normalize-space($hint)}"/>
};

declare  %private function subjects:searchSubjectAAT($query as xs:string) {
   let $results :=  collection($app:local-getty-aat-repositories)//vp:Subject[ ngram:contains(.//vp:Term_Text, $query)]
   return
      for $result in $results
            let $subject := if ( exists($result//vp:Preferred_Term) ) then ( $result//vp:Preferred_Term[1] ) else ( $result//vp:Non-Preferred_Term[1] )
            let $internalID := data( $result/@Subject_ID )
            let $subjectText := $subject/vp:Term_Text[1]/text()
            return 
                <subject name="{$subjectText}" internalID="{$internalID}" bio="" uuid="" resource="aat" type="subject" sources="jpg" hint=""/>
                
};

declare function subjects:searchSubject($query as xs:string) {
     ( subjects:searchSubjectLocal($query) , subjects:searchSubjectAAT($query) )
};