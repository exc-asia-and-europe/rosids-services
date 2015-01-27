xquery version "3.0";

let $users := ( 'tony.buchwald', 'eric.decker', 'heinz.kuper', 'marnold1', 'johannes.alisch', 'simon.gruening', 'matthias.guth' , 'claudius.teodorescu', 'zak.patel' )
let $domain-postfix := '@ad.uni-heidelberg.de'
let $group := 'heraeditor'
let $create-group := if(sm:group-exists($group)) then () else (sm:create-group($group))
return
    <result>
        {
            for $user in $users
            let $domain-user := $user || $domain-postfix 
            return 
                if (sm:user-exists($domain-user)) 
                then (
                    let $add := sm:add-group-member($group, $domain-user)
                    return
                    <done>{$domain-user}</done>
                ) else (
                    <fail>{$domain-user}</fail>
                )
        }
    </result>