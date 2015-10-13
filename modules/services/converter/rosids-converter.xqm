xquery version "3.0";

(:
    Convert various terms, like tei:person or vp:Subject, into rosids-term-elements
    Auhtor: zwobit
:)

module namespace rosids-converter="http://github.com/hra-team/rosids-services/services/converter/rosids-converter";

(: Getty utils :)
import module namespace vp-utils="http://github.com/hra-team/rosids-services/services/converter/vp/vp-utils" at "/apps/rosids-services/modules/services/converter/vp/vp-utils.xqm";

(: Getty namespace :)
declare namespace vp = "http://localhost/namespace";


(: Constants :)
declare variable $rosids-converter:GETTY := 'getty'


(:
 : ### GETTY AAT + TGN ###
 :)
declare function rosids-converter:getty-to-rosid-term($subject, $type, $authority) {
    element term {
        attribute id {$subject/@Subject_ID},
        attribute type {$type},
        (: value, qualifier, languages) :)
        vp-utils:getPreferredTerm($subject),
        attribute authority {$authority},
        attribute source {$rosids-converter:GETTY},
        attribute sources {$rosids-converter:GETTY},
        attribute icon {$rosids-converter:GETTY},
        vp-utils:getDescriptiveNotes($subject),
        vp-utils:getNonPreferredTerms($subject),
        vp-utils:getHierarchy($subject)
    }
};



(:
 : ### exc asia and europe ###
 :)
