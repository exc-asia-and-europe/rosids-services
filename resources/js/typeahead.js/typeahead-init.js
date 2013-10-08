var autocompletes = [];

function initAutocompletes() {
    console.log("init-autocompletes()");
    
    $.each(autocompletes, function () {
        console.log('Destroying: ', this)
        this.typeahead('destroy');
    });
    autocompletes.length = 0;

    $(".xfRepeatItem [class$=-autocomplete-input]").each(function () {
        var jObject = $(this);
        var xfValue = jObject.parent('.xfContainer').find( '.' + jObject.attr('name') + ' .xfValue' )
        //$('#' + jObject.attr('callbackSet') + ' .xfRepeatItem .' + jObject.attr('name') + ' .xfValue');
        
        //console.log('#' + jObject.attr('callbackSet') + ' .xfRepeatItem .' + jObject.attr('name') + ' .xfValue')
        console.log("parent: " , jObject.parent('.xfContainer'));
        console.log("xfValue: " , xfValue, " Value: ", xfValue.val());
        
        //Set input ot xforms value
        jObject.val(xfValue.val());
        
        var name = jObject.attr("name");            
        var query = jObject.attr("query");
        
        
        console.log("Name: " , name , " Query: " , query);
        
        jObject.typeahead({
            name: query,
            dataType: "json",
            minLength: 3,
            limit: 20,
            template: '<p><strong>{{value}}</strong>{{#bio}}, {{/bio}}{{bio}}  <small><strong>{{resource}}<strong></small> <small><i>{{hint}}</i></small></p>',
            engine: Hogan,
            remote: {
                url: '/exist/apps/cluster-services/modules/services/search/search.xql?' + query + '=%QUERY',
                filter: function(parsedData){
                    var dataset = [];
                    if( Object.prototype.toString.call( parsedData.name ) === '[object Array]' ) {
                        var dataset = [];
                        for(i = 0; i < parsedData.name.length; i++) {
                            dataset.push({
                                name: parsedData.name[i].name,
                                value: parsedData.name[i].value,
                                bio: parsedData.name[i].bio,
                                resource: parsedData.name[i].resource,
                                uuid: parsedData.name[i].uuid,
                                viafID: parsedData.name[i].viafID,
                                hint: parsedData.name[i].hint
                            });
                        }
                    } else {
                        dataset.push({
                            name: parsedData.name.name,
                            value: parsedData.name.value,
                            bio: parsedData.name.bio,
                            resource: parsedData.name.resource,
                            uuid: parsedData.name.uuid,
                            viafID: parsedData.name.viafID,
                            hint: parsedData.name.hint
                        });
                    }
                    return dataset;
                }
            }
        }).on('typeahead:selected', function (e, datum) {
            var target = jQuery(e.target);
            var xfValue = $('#' + jObject.attr('callbackSet') + ' .xfRepeatIndex .' + jObject.attr('name') + ' .xfValue');
            xfValue.val(datum.name)
            
            var id = xfValue.attr('id');
            id = id.substring(0, id.indexOf('-value'));
            console.log("ID: " , id)
            fluxProcessor.sendValue("" + id, datum.name);
            
        });
        
        autocompletes.push(jObject);
    });
}