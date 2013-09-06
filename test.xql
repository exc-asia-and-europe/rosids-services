xquery version "3.0";

import module namespace app="http://exist-db.org/xquery/biblio/services/app" at "modules/services/app.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace ns2= "http://viaf.org/viaf/terms#"; 

(: 
    let $results := doc($app:local-persons-repositories)
        return ( $results, <path> {"/db" || $app:local-persons-repositories} </path>)
:)
let $persons := doc($app:local-viaf-repositories)//ns2:VIAFCluster[ns2:nameType eq 'Personal' and ns2:mainHeadings/ns2:mainHeadingEl/ns2:datafield[ngram:contains(ns2:subfield, "arx") and ns2:subfield/@code eq 'a']]

for $person in $persons
        let $name := $person//ns2:mainHeadingEl[max(count(ns2:links/ns2:link))]/ns2:datafield/ns2:subfield[@code eq 'a']
        return <test>
                <name>{$name}</name>
                {
                    for $test in $person//ns2:mainHeadingEl
                    return ($test/ns2:datafield[ns2:subfield/@code eq 'a'] , count($test/ns2:links/ns2:link))
                }
                </test>
        
(: 
  and ]]
:)