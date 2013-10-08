xquery version "3.0";

module namespace app="http://exist-db.org/xquery/biblio/services/app";


(: Current versions of local repositories :)
declare %private variable $app:local-persons := "persons_tei_2013-09-03_20-36-45.xml";
declare %private variable $app:local-organisations := "organisations_tei_2013-09-03_20-36-46.xml";
declare %private variable $app:local-subjects := "subjects_mads_2013-08-27.xml";

(: collection paths for local repositories :)
declare %private variable $app:local-repositories-collection := "/resources/services/repositories/local/";
declare %private variable $app:local-persons-repositories-collection := $app:local-repositories-collection || "persons/";
declare %private variable $app:local-organisations-repositories-collection := $app:local-repositories-collection || "organisations/";
declare %private variable $app:local-subjects-repositories-collection := $app:local-repositories-collection || "subjects/";
declare %private variable $app:local-getty-repositories-collection := $app:local-repositories-collection || "getty/";
declare %private variable $app:local-getty-ulan-repositories := $app:local-getty-repositories-collection || "ulan/";
declare %private variable $app:local-getty-aat-repositories := $app:local-getty-repositories-collection || "aat/";
declare %private variable $app:local-getty-tgn-repositories := $app:local-getty-repositories-collection || "tgn/";
declare %private variable $app:local-viaf-repositories-collection := $app:local-repositories-collection || "viaf/";

(: full path to repositories :)
declare variable $app:local-persons-repositories := $app:local-persons-repositories-collection || $app:local-persons;
declare variable $app:local-organisations-repositories := $app:local-organisations-repositories-collection || $app:local-organisations;
declare variable $app:local-subjects-repositories := $app:local-subjects-repositories-collection || $app:local-subjects;
declare variable $app:local-viaf-rdf-repositories := $app:local-viaf-repositories-collection || 'rdf/';
declare variable $app:local-viaf-xml-repositories := $app:local-viaf-repositories-collection || 'xml/';
