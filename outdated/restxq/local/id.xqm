xquery version "3.0";

module namespace rosids-id-retrieve="http://github.com/hra-team/rosids-services/services/retrieve/local/rosids-id-retrieve";

import module namespace app="http://github.com/hra-team/rosids-shared/config/app" at "/apps/rosids-shared/modules/ziziphus/config/app.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare
    %rest:GET
    %rest:path("/organisations/local/{$uuid}")
    %rest:produces("application/xml", "text/xml") 
function rosids-id-retrieve:get-org-by-uuid($uuid) {
    let $col := collection($app:global-organisations-repositories-collection)
    return $col//tei:org[@xml:id=$uuid]
};

declare
    %rest:GET
    %rest:path("/persons/local/{$uuid}")
    %rest:produces("application/xml", "text/xml")
function rosids-id-retrieve:get-person-by-uuid($uuid) {
    let $col := collection($app:global-persons-repositories-collection)
    return $col//tei:person[@xml:id=$uuid]
};