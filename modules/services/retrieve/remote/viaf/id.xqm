xquery version "3.0";

module namespace rosids-id-retrieve-viaf="http://github.com/hra-team/rosids-services/services/retrieve/viaf/rosids-id-retrieve-viaf";

import module namespace httpclient ="http://exist-db.org/xquery/httpclient";

declare namespace ns2= "http://viaf.org/viaf/terms#";

declare function rosids-id-retrieve-viaf:retrieve($id as xs:string) {
    if(string(number($id)) != 'NaN' )
    then (
        let $uri:= 'http://www.viaf.org/viaf/' || $id || '/viaf.xml'
        let $http-call := httpclient:get(xs:anyURI($uri), true(), ())
        return 
            if(exists($http-call//ns2:VIAFCluster)) 
            then (
                $http-call//ns2:VIAFCluster
            ) else ( () )
    ) else ( () )
};