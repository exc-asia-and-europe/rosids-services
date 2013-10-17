/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
var autocompletes = [];

function autocomplete-init() {
    autocompletes.each(function () {
        this.destroy();
    });
    $("[id$=-ac]").each(function () {
        //init autocomplete ...
    });
}
