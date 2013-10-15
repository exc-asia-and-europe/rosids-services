module namespace typeahead="http://exist-db.org/xquery/biblio/services/search/autocomplete/typeahead";

declare function typeahead:jquery-typeahead-default() {
    <result>
        <name>Not found</name>
        <value>Not found</value>
        <internalID/>
        <bio/>
        <uuid/>
        <resource/>
        <type/>
        <sources/>
        <hint>create/request new record</hint>
    </result>
};

(: <name name="{$name}" internalID="{$person/ns2:viafID}" bio="{$bio}" uuid="" resource="viaf" type="person" sources="{$sources}"/>  :)
declare function typeahead:jquery-typeahead($results as item()*) {
    <result>
    {
        (
            for $result in $results
            return
                <result>
                    <name>{replace( data($result/@name), "&quot;", "'")}</name>
                    <value>{replace( data($result/@name), "&quot;", "'")}</value>
                    <internalID>{data($result/@internalID)}</internalID>
                    <bio>{if(exists($result/@bio)) then ( data($result/@bio) ) else ("")}</bio>
                    <uuid>{data($result/@uuid)}</uuid>
                    <resource>{data($result/@resource)}</resource>
                    <type>{data($result/@type)}</type>
                    <sources>{data($result/@type)}</sources>
                    <hint>{data($result/@hint)}</hint>
                </result>
        ), typeahead:jquery-typeahead-default()
    }
    </result>
};