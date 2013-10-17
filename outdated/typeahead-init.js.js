$(document).ready(function(){
    var autocompletes = [];
                
    $.each(autocompletes, function () {
        this.destroy();
    });
    
    $("[class$=-ac]").each(function () {
        var jObject = $(this);
        var name = jObject.attr("name");            
        var query = jObject.attr("query");
        
        console.log("Name: " , name , " Query: " , query);
        
        jObject.typeahead({
            name: query,
            dataType: "json",
            minLength: 3,
            template: '<p><strong>{{value}}</strong> – {{bio}}</p>',
            engine: Hogan,
            remote: {
                url: 'modules/services/search/search.xql?' + query + '=%QUERY',
                filter: function(parsedData){
                    var dataset = [];
                    console.log(parsedData.name)
                    if( Object.prototype.toString.call( parsedData.name ) === '[object Array]' ) {
                        console.log(parsedData.name.length)
                        var dataset = [];
                        for(i = 0; i < parsedData.name.length; i++) {
                            console.log(parsedData.name[i].name);
                            dataset.push({
                                name: parsedData.name[i].name,
                                value: parsedData.name[i].value,
                                bio: parsedData.name[i].bio
                            });
                        }
                    } else {
                        console.log(parsedData.name)
                        dataset.push({
                            name: parsedData.name.name,
                            value: parsedData.name.value,
                            bio: parsedData.name.bio
                        });
                    }
                    return dataset;
                }
            }
        });
    });
});