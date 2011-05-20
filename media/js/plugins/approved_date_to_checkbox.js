var replaceApprovedDateRow = function(){
    //build our new form row
    var approvedRow = '<div class="form-row approved"><div><label for="id_approved_checkbox">Approved</label><p class="checkbox"><input type="checkbox" id="id_approved_checkbox" name="id_approved_checkbox" value="approved"/></p></div></div>';
    
    //hide the approved_date form row and add the new form row before it
    $('.form-row.approved_date').hide().before(approvedRow);
    
    //set the state of the checkbox
    if ( !$('#id_approved_date_0').val() ){
    }else{
        $('#id_approved_checkbox').val(['approved'])
    }
    
    //bind the update function to the change event
    $('#id_approved_checkbox').change(updateApprovedDate)   
}

//update the approved_date fields when the checkbox changes
var updateApprovedDate = function(e){
    var newDate = ''
    if($(this).attr('checked')){
        var currentTime = new Date();
        newDate = currentTime.getISODate();
        newTime = currentTime.getHourMinuteSecond();
    }else{
        newDate = ''
        newTime = ''
    }

    $('#id_approved_date_0').val(newDate)
    $('#id_approved_date_1').val(newTime)
}

$(document).ready(function(){
    replaceApprovedDateRow();
})
