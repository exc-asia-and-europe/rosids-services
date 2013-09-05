xquery version "3.0";

module namespace app="http://exist-db.org/xquery/biblio/services/app";


(: Current versions of local repositories :)
declare %private% variable $app:local-persons := "persons_tei_2013-09-03_20-36-45.xml";
declare %private% variable $app:local-organisations := "organisations_tei_2013-09-03_20-36-46.xml";
declare %private% variable $app:local-subjects := "subjects_mads_2013-08-27.xml";

(: collection paths for local repositories :)
declare %private% variable $app:local-repositories-collection := "resources/service/repositories/local/"
declare %private% variable $app:local-persons-repositories-collection := $app:local-repositories || "persons/"
declare %private% variable $app:local-organisations-repositories-collection := $app:local-repositories || "organisations/"
declare %private% variable $app:local-subjects-repositories-collection := $app:local-repositories || "subjects/"

(: full path to repositories :)
declare variable $app:local-persons-repositories := $app:local-persons-repositories || $app:local-persons
declare variable $app:local-organisations-repositories := $app:local-organisations-repositories || $app:local-organisations
declare variable $app:local-subjects-repositories := $app:local-subjects-repositories || $app:local-subjects