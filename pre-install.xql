xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";

(: The following external variables are set by the repo:deploy function :)
(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;


(: DB root :)
declare variable $db-root := "/db";

declare variable $db-system-root := "/db/system/config/db";

(: collection paths for local repositories :)
declare variable $local-repositories-collection := "resources/services/repositories/local/";
declare variable $local-persons-repositories-collection := $local-repositories-collection || "persons/";
declare variable $local-organisations-repositories-collection := $local-repositories-collection || "organisations/";
declare variable $local-subjects-repositories-collection := $local-repositories-collection || "subjects/";
declare variable $local-getty-repositories-collection := $local-repositories-collection || "getty/";
declare variable $local-getty-ulan-repositories := $local-getty-repositories-collection || "ulan/";
declare variable $local-getty-aat-repositories := $local-getty-repositories-collection || "aat/";
declare variable $local-getty-tgn-repositories := $local-getty-repositories-collection || "tgn/";
declare variable $local-viaf-repositories-collection := $local-repositories-collection || "viaf/";
declare variable $local-viaf-rdf-repositories-collection := $local-viaf-repositories-collection || "rdf/";
declare variable $local-viaf-xml-repositories-collection := $local-viaf-repositories-collection || "xml/";


(: User and group to store and own files :)
declare variable $biblio-admin-user := "editor";
declare variable $biblio-users-group := "biblio.users";

(: Log level :)
declare variable $log-level := "INFO";

declare function local:set-collection-resource-permissions($collection as xs:string, $owner as xs:string, $group as xs:string, $permissions as xs:int) {
    if(xmldb:collection-available($collection))
    then (
        let $resources :=
            for $resource in xmldb:get-child-resources($collection)
                return
                    xmldb:set-resource-permissions($collection, $resource, $owner, $group, $permissions)
        let $collections :=
            for $child-collection in  xmldb:get-child-collections($collection)
                         let $permission := xmldb:set-collection-permissions($collection || "/" || $child-collection, $owner, $group, $permissions)
                         return
                                 local:set-collection-resource-permissions($collection || "/" || $child-collection, $owner, $group, $permissions)
         return ()
    ) else ()
};

declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xmldb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};


util:log($log-level, "Script: Running pre-install script ..."),

(: Create users and groups :)
util:log($log-level, fn:concat("Security: Creating user '", $biblio-admin-user, "' and group '", $biblio-users-group, "' ...")),
    if (xmldb:group-exists($biblio-users-group)) then ()
    else xmldb:create-group($biblio-users-group),
    if (xmldb:exists-user($biblio-admin-user)) then ()
    else xmldb:create-user($biblio-admin-user, $biblio-admin-user, $biblio-users-group, ()),
util:log($log-level, "Security: Done."),

util:log($log-level, "Script: creating collection for repositories."),
local:mkcol($db-root, $local-persons-repositories-collection),
local:mkcol($db-root, $local-organisations-repositories-collection),
local:mkcol($db-root, $local-subjects-repositories-collection),
local:mkcol($db-root, $local-getty-ulan-repositories),
local:mkcol($db-root, $local-getty-aat-repositories),
local:mkcol($db-root, $local-getty-tgn-repositories),
local:mkcol($db-root, $local-viaf-rdf-repositories-collection),
local:mkcol($db-root, $local-viaf-xml-repositories-collection),

util:log($log-level, "Script: Storing repositories."),
xmldb:store-files-from-pattern( $local-persons-repositories-collection, $dir, "repositories/local/persons/*.xml"),
xmldb:store-files-from-pattern( $local-organisations-repositories-collection, $dir, "repositories/local/organisations/*.xml"),
xmldb:store-files-from-pattern( $local-subjects-repositories-collection, $dir, "repositories/local/subjects/*.xml"),
xmldb:store-files-from-pattern( $local-getty-ulan-repositories, $dir, "repositories/local/getty/ulan/*.xml"),
xmldb:store-files-from-pattern( $local-getty-aat-repositories, $dir, "repositories/local/getty/aat/*.xml"),
xmldb:store-files-from-pattern( $local-getty-tgn-repositories, $dir, "repositories/local/getty/tgn/*.xml"),
xmldb:store-files-from-pattern( $local-viaf-rdf-repositories-collection, $dir, "repositories/local/viaf/rdf/*.xml"),
xmldb:store-files-from-pattern( $local-viaf-xml-repositories-collection, $dir, "repositories/local/viaf/xml/*.xml"),

util:log($log-level, "Script: Chaning ownership"),
local:set-collection-resource-permissions($db-root || '/' ||   $local-persons-repositories-collection, $biblio-admin-user, $biblio-users-group, util:base-to-integer(0755, 8)),
local:set-collection-resource-permissions($db-root || '/' ||   $local-organisations-repositories-collection, $biblio-admin-user, $biblio-users-group, util:base-to-integer(0755, 8)),
local:set-collection-resource-permissions($db-root || '/' ||   $local-subjects-repositories-collection, $biblio-admin-user, $biblio-users-group, util:base-to-integer(0755, 8)),
local:set-collection-resource-permissions($db-root || '/' ||   $local-getty-ulan-repositories, $biblio-admin-user, $biblio-users-group, util:base-to-integer(0755, 8)),
local:set-collection-resource-permissions($db-root || '/' ||   $local-getty-aat-repositories, $biblio-admin-user, $biblio-users-group, util:base-to-integer(0755, 8)),
local:set-collection-resource-permissions($db-root || '/' ||   $local-getty-tgn-repositories, $biblio-admin-user, $biblio-users-group, util:base-to-integer(0755, 8)),
local:set-collection-resource-permissions($db-root || '/' ||   $local-viaf-rdf-repositories-collection, $biblio-admin-user, $biblio-users-group, util:base-to-integer(0755, 8)),
local:set-collection-resource-permissions($db-root || '/' ||   $local-viaf-xml-repositories-collection, $biblio-admin-user, $biblio-users-group, util:base-to-integer(0755, 8)),


util:log($log-level, "Script: creating system collections for repositories."),
local:mkcol($db-system-root, $local-persons-repositories-collection),
local:mkcol($db-system-root, $local-organisations-repositories-collection),
local:mkcol($db-system-root, $local-subjects-repositories-collection),
local:mkcol($db-system-root, $local-getty-ulan-repositories),
local:mkcol($db-system-root, $local-getty-aat-repositories),
local:mkcol($db-system-root, $local-getty-tgn-repositories),
local:mkcol($db-system-root, $local-viaf-rdf-repositories-collection),
local:mkcol($db-system-root, $local-viaf-xml-repositories-collection),

util:log($log-level, "Script: storing index configurations for repositories."),
xmldb:store-files-from-pattern($db-system-root || '/' || $local-persons-repositories-collection, $dir, "xconfs/local/repositories/persons/*.xconf") ,
xmldb:store-files-from-pattern($db-system-root || '/' || $local-organisations-repositories-collection, $dir, "xconfs/local/repositories/organisations/*.xconf") ,
xmldb:store-files-from-pattern($db-system-root || '/' || $local-subjects-repositories-collection, $dir, "xconfs/local/repositories/subjects/*.xconf") ,
xmldb:store-files-from-pattern($db-system-root || '/' || $local-getty-ulan-repositories, $dir, "xconfs/local/repositories/getty/ulan/*.xconf") ,
xmldb:store-files-from-pattern($db-system-root || '/' || $local-getty-aat-repositories, $dir, "xconfs/local/repositories/getty/aat/*.xconf") ,
xmldb:store-files-from-pattern($db-system-root || '/' || $local-getty-tgn-repositories, $dir, "xconfs/local/repositories/getty/tgn/*.xconf") ,
xmldb:store-files-from-pattern($db-system-root || '/' || $local-viaf-rdf-repositories-collection, $dir, "xconfs/local/repositories/viaf/rdf/*.xconf") ,
xmldb:store-files-from-pattern($db-system-root || '/' || $local-viaf-xml-repositories-collection, $dir, "xconfs/local/repositories/viaf/xml/*.xconf") ,

util:log($log-level, "DONE.")