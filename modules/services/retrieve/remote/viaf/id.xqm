xquery version "3.0";

module namespace rosids-retrieve-viaf-id="http://exist-db.org/xquery/biblio/services/retrieve/remote/viaf/id";

import module namespace httpclient ="http://exist-db.org/xquery/httpclient";

declare namespace ns2= "http://viaf.org/viaf/terms#";

declare function rosids-retrieve-viaf-id:retrieve($id as xs:string) {
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