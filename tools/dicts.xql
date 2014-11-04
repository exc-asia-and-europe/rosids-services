xquery version "3.0";

declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace mads = "http://www.loc.gov/mads/v2";
(: 
    subjects -> vra:subject/vra:term
    materials -> vra:material
    styleperiods -> vra:stylePeriod
    techniques -> vra:technique
    worktypes -> vra:worktype
:)

declare namespace functx = "http://www.functx.com";
declare function functx:distinct-deep($nodes as node()*) as node()* {
    for $seq in (1 to count($nodes))
    return $nodes[$seq][not(functx:is-node-in-sequence-deep-equal(.,$nodes[position() < $seq]))]
};
 
declare function functx:is-node-in-sequence-deep-equal($node as node()?, $seq as node()*) as xs:boolean {
   some $nodeInSeq in $seq satisfies deep-equal($nodeInSeq,$node)
};

(: 
let $terms := (functx:distinct-deep(collection(xmldb:encode('/db/resources/commons/Priya Paul Collection/'))//vra:subject/vra:term), functx:distinct-deep(collection(xmldb:encode('/db/resources/commons/Priya Paul Collection/'))//vra:subject/vra:term))
let $subjects := <subjects>{for $term in $terms return $terms/parent::vra:subject}</subjects>
:)

let $doc := doc('/db/resources/services/repositories/global/subjects/subjects_mads_2014-03-05_16-49-56.xml')
let $vra := ( collection(xmldb:encode('/db/resources/commons/Priya Paul Collection/')), collection(xmldb:encode('/db/resources/commons/Priya Paul Collection/VRA_Images')) )
let $materials := functx:distinct-deep($vra//vra:material)
let $stylePeriods := functx:distinct-deep($vra//vra:stylePeriod)
let $techniques := functx:distinct-deep($vra//vra:technique)
let $worktypes := functx:distinct-deep($vra//vra:worktype)

let $local-subjects-doc := <mads:madsCollection>
    {doc('/db/resources/services/repositories/global/subjects/subjects_mads_2014-03-05_16-49-56.xml')//mads:mads[count(.//mads:topic[@authorityURI ="https://kjc-fs1.kjc.uni-heidelberg.de/AATService/api/get.xml/" and lower-case(@authority) = "aat"]) = 0]}
    </mads:madsCollection>
return xmldb:store('/db', '/subjects_local_mads_2014-03-05_16-49-56.xml', $local-subjects-doc)

let $materials-doc := 
    <mads:madsCollection>{
        for $material in $materials[lower-case(@vocab) ='local']
        let $mads-node := $doc//mads:mads//mads:topic[. = $material/text()]/ancestor::mads:mads
        return 
            if(count($mads-node//mads:topic[lower-case(@authority) = "aat" and exists(@valueURI)]) >= 1)
            then (
            ) else ($mads-node)
    }</mads:madsCollection>
let $store := xmldb:store('/db', '/materials_mads_2014-03-05_16-49-56.xml', $materials-doc)

let $stylePeriods-doc := 
    <mads:madsCollection>{
        for $stylePeriod in $stylePeriods[lower-case(@vocab) ='local']
        let $mads-node := $doc//mads:mads//mads:topic[. = $stylePeriod/text()]/ancestor::mads:mads
        return 
            if(count($mads-node//mads:topic[lower-case(@authority) = "aat" and exists(@valueURI)]) >= 1)
            then (
            ) else ($mads-node)
    }</mads:madsCollection>
let $store := xmldb:store('/db', '/stylePeriods_mads_2014-03-05_16-49-56.xml', $stylePeriods-doc)

let $techniques-doc := 
    <mads:madsCollection>{
        for $technique in $techniques[lower-case(@vocab) ='local']
        let $mads-node := $doc//mads:mads//mads:topic[. = $technique/text()]/ancestor::mads:mads
        return 
            if(count($mads-node//mads:topic[lower-case(@authority) = "aat" and exists(@valueURI)]) >= 1)
            then (
            ) else ($mads-node)
    }</mads:madsCollection>
let $store := xmldb:store('/db', '/techniques_mads_2014-03-05_16-49-56.xml', $techniques-doc)

let $worktypes-doc := 
    <mads:madsCollection>{
        for $worktype in $worktypes[lower-case(@vocab) ='local']
        let $mads-node := $doc//mads:mads//mads:topic[. = $worktype/text()]/ancestor::mads:mads
        return 
            if(count($mads-node//mads:topic[lower-case(@authority) = "aat" and exists(@valueURI)]) >= 1)
            then (
            ) else ($mads-node)
    }</mads:madsCollection>
let $store := xmldb:store('/db', '/worktypes_mads_2014-03-05_16-49-56.xml', $worktypes-doc)
return "done"
   
    
