xquery version "3.0";

module namespace app="http://exist-db.org/xquery/biblio/services/app";


(: Current versions of local repositories :)

(: Outdated: search collections
declare %private variable $app:global-persons := "persons_tei_2014-03-05_16-49-56.xml";
declare %private variable $app:global-organisations := "organisations_tei_2014-03-05_16-49-56.xml";
declare %private variable $app:global-subjects := "subjects_mads_2014-03-05_16-49-56.xml";
:)

(: collection paths for local repositories :)
declare %private variable $app:global-repositories-collection := "/resources/services/repositories/local/";
declare %private variable $app:global-persons-repositories-collection := $app:global-repositories-collection || "persons/";
declare %private variable $app:global-organisations-repositories-collection := $app:global-repositories-collection || "organisations/";
declare %private variable $app:global-subjects-repositories-collection := $app:global-repositories-collection || "subjects/";

declare %private variable $app:global-mirrors-repositories-collection := "/resources/services/repositories/global/externalmirrors/";

(: VIAF :)
declare %private variable $app:global-viaf-repositories-collection := "/resources/services/repositories/local/viaf/";

(: GETTY :)
declare %private variable $app:global-getty-repositories-collection := "/resources/services/repositories/local/getty/";
(: GETTY subcollections :)
declare %private variable $app:global-getty-ulan-repositories := $app:global-getty-repositories-collection || "ulan/";
declare %private variable $app:global-getty-aat-repositories := $app:global-getty-repositories-collection || "aat/";
declare %private variable $app:global-getty-tgn-repositories := $app:global-getty-repositories-collection || "tgn/";

(: USERS :)
declare %private variable $app:users-repositories-collection := "/resources/services/repositories/users/";

(: GROUPS :)
declare %private variable $app:groups-repositories-collection := "/resources/services/repositories/groups/";

(: full path to repositories :)

(: Outdated: search collections
declare variable $app:global-persons-repositories := $app:global-persons-repositories-collection || $app:global-persons;
declare variable $app:global-organisations-repositories := $app:global-organisations-repositories-collection || $app:global-organisations;
declare variable $app:global-subjects-repositories := $app:global-subjects-repositories-collection || $app:global-subjects;
:)
declare variable $app:global-viaf-rdf-repositories := $app:global-viaf-repositories-collection || 'rdf/';
declare variable $app:global-viaf-xml-repositories := $app:global-viaf-repositories-collection || 'xml/';

declare variable $app:debug as xs:boolean := true();
