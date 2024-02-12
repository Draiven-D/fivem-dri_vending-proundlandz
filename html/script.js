var myshop = false,
    othershop = false,
    buy = false,
    itemlist = [],
    additem = false,
    itemdata = []

$(document).ready(function () {
    $(".myshop").hide();
    $(".othershop").hide();
    $("#textnoti").hide();
    $(".input-line").attr('maxlength', '50');
});
window.addEventListener('message', (event)=> {
    var data_type = event.data.type;
    switch (data_type) {
        case "CloseShop":
            $(".myshop").hide();
            $(".othershop").hide();
            $('#confirm').css('display', 'none')
            myshop = false;
            othershop = false;
            buy = false,
            itemlist = [];
            itemdata = [];
            $("#textnoti").show();
            break;
        case "MyShop":
            myshop = true;
            $('.btn-add').show();
            $('#confirmshop').show();
            $('.input-line').show();
            $('.myitem').show();
            $(".myshop").fadeIn(300);
            $('.input-line').val("");
            $('.myshoplive').html('');
            $(".myshoplive").hide();
            $("#textnoti").hide();
            refreshshop();
            itemdata = event.data.items;
            break;
        case "UpdateMyShop":
            updateshop(event.data.items);
            break;
        case "OtherShop":
            othershop = true;
            $(".othershop").fadeIn(300);
            updateothershop(event.data.name,event.data.items);
            break;
        case "UpdateOtherShop":
            updateothershop(event.data.name,event.data.items);
            break;
        case "Noti":
            $("#textnoti").show();
            break;
        case "CloseNoti":
            $("#textnoti").hide();
            break;
        default:
            break;
    }
});
$('.btn-add').click(()=>{
    if (!additem) {
        additem = true
        $(".additemshop").html('');
        var app = '<form><div class="form-row"><div class="form-group col-md-12"><label for="chooseitem">สินค้าที่ต้องการขาย</label><select class="form-control form-control-sm" id="chooseitem"><option value="none">เลือกสินค้าที่ต้องการขาย (จำนวนที่มี)</option>';
        $.each(itemdata, function(index, item) {
            if (!item.choose) {
                app = app + '<option value="'+ index +'">'+ item.label +' ('+ item.count +')</option>';
            }
        });
        app = app + '</select></div><div class="form-group col-md-6"><label for="inputprice">ราคาที่ต้องการขาย</label><input type="number" min="1" value="1"  class="form-control form-control-sm" id="inputprice"></div><div class="form-group col-md-6"><label for="inputcount">จำนวนที่ต้องการขาย</label><input type="number" min="1" value="1" class="form-control form-control-sm" id="inputcount"></div></div><div class="btn-confirm" onclick="additemshop()">ตกลง</div><div class="btn-cancel" onclick="closeadditem()">ยกเลิก</div></form>';
        $(".additemshop").append(app);
        $(".additemshop").fadeIn(300);
    }
});
function additemshop(){
    var aditem = $('#chooseitem').val();
    var adprice = $('#inputprice').val();
    var adcount = $('#inputcount').val();
    if ((!aditem) || (aditem == 'none')) {
        let text = 'คุณยังไม่ได้เลือกสินค้า';
        $.post("http://dri_vending/NotiError", JSON.stringify({
            data : text
        }));
    } else if ((!adprice) || (adprice < 1)) {
        let text = 'คุณยังไม่ได้ใส่ราคาขาย';
        $.post("http://dri_vending/NotiError", JSON.stringify({
            data : text
        }));
    } else if ((!adcount) || (adcount < 1)) {
        let text = 'คุณยังไม่ได้ใส่จำนวน';
        $.post("http://dri_vending/NotiError", JSON.stringify({
            data : text
        }));
    } else {
        if (adcount > itemdata[aditem]['count']) {
            let text = 'คุณใส่จำนวนไม่ถูกต้อง';
            $.post("http://dri_vending/NotiError", JSON.stringify({
                data : text
            }));
        } else {
            itemdata[aditem]['choose'] = true;
            let data = {
                name: itemdata[aditem]['name'],
                label: itemdata[aditem]['label'],
                price: adprice,
                amount: adcount,
                index: aditem
            };
            itemlist.push(data)
            additem = false
            $(".additemshop").fadeOut(300);
            $(".additemshop").html('');
            // console.log(itemlist)
            refreshshop();
        }
    }
};
function closeadditem(){
    additem = false
    $(".additemshop").fadeOut(300);
    $(".additemshop").html('');
};
$('#confirmshop').click(()=>{
    if (!additem) {
        let value = null;
        if (($('.input-line').val() !== "") && (itemlist.length > 0)){
            // myshop = true;
            value = $('.input-line').val();
            $('.btn-add').hide();
            $('#confirmshop').hide();
            $('.input-line').hide();
            $.post("http://dri_vending/CreateShop", JSON.stringify({
                value : value,
                itemlist : itemlist
            }));
            $('.myitem').html('');
            $(".myitem").hide();
            $(".myshoplive").fadeIn(300);
            // updateshop(itemlist);
        }else{
            var text = 'คุณยังไม่ได้ใส่ชื่อร้านค้า';
            if (itemlist.length === 0) {
                text = 'คุณยังไม่ได้เพิ่มสินค้า';
            }
            $.post("http://dri_vending/NotiError", JSON.stringify({
                data : text
            }));
        }
    }
});
$('.closeshop').click(()=>{
    if ((!additem) && (myshop)) {
        $.post("http://dri_vending/CloseShop", JSON.stringify({}));
        $(".myshop").hide();
        $("#textnoti").show();
        myshop = false
        itemlist = []
        itemdata = []
    }
    if ((!buy) && (othershop)) {
        $.post("http://dri_vending/CloseOtherShop", JSON.stringify({}));
        $(".othershop").hide();
        othershop = false
    }
});
function refreshshop(){
    $('.myitem').html('');
    if (itemlist.length > 0) {
        var app = '';
        $.each(itemlist, function(index, item) {
            app = app + '<div class="item-shop"><img src="nui://esx_inventoryhud/html/img/items/'+ item.name +'.png"><div class="item-detail"><h5 class="item-name">'+
            item.label +'</h5><h6 class="item-price">ราคาขาย: $'+ item.price +'</h6><h6 class="item-amount">คงเหลือ: '+ item.amount +' ชิ้น</h6><div class="btn-del" onclick="removeitem('+index+','+item.index+')">X</div></div></div>'
        });
        $(".myitem").append(app);
    }
};
function removeitem(list,index) {
    itemlist.splice(list, 1);
    itemdata[index]['choose'] = false;
    // console.log(itemlist);
    refreshshop();
};
function updateshop(list) {
    if (myshop) {
        $('.myshoplive').html('');
        if (list.length > 0) {
            var app = '';
            $.each(list, function(index, item) {
                app = app + '<div class="item-shop"><img src="nui://esx_inventoryhud/html/img/items/'+ item.name +'.png"><div class="item-detail"><h5 class="item-name">'+
                item.label +'</h5><h6 class="item-price">ราคาขาย: $'+ item.price +'</h6><h6 class="item-amount">คงเหลือ: '+ item.amount +' ชิ้น</h6></div></div>'
            });
            $(".myshoplive").append(app);
        }
    }
}
function updateothershop(text, list) {
    if (othershop) {
        $('#otname').html(text)
        $('.othershoplive').html('');
        if (list.length > 0) {
            var app = '';
            $.each(list, function(index, item) {
                app = app + '<div class="item-shop"><img src="nui://esx_inventoryhud/html/img/items/'+ item.name +'.png"><div class="item-detail"><h5 class="item-name">'+
                item.label +'</h5><h6 class="item-price">ราคาขาย: $'+ item.price +'</h6><h6 class="item-amount">คงเหลือ: '+ item.amount +' ชิ้น</h6><button type="button" onclick="buyinput(event)" value="'+
                item.name +'" value2="'+ item.amount +'" value3="'+ item.label +'" class="btn-buy">ซื้อ</button></div></div>'

            });
            $(".othershoplive").append(app);
        }
    }
}
function buyinput(event) {
    if (!buy) {
        buy = true
        var Selected = $(event.currentTarget).attr('value');
        var Label = $(event.currentTarget).attr('value3');
        var Maxs = $(event.currentTarget).attr('value2');
        $("#confirm").html("");
        var app = '<div id="confirmtitle"><h5>ต้องการซื้อ '+Label+'</h5><input type="number" class="text-center" min="1" max="' + Maxs + '" id="count" placeholder="1" value="1" onChange="input_Change(this.id)"></div><button type="button" id="bconfirm" class="btn btn-success btn-sm" onclick="Confirmbuy(event)" value="'+ Selected +'">ตกลง</button><button type="button" class="btn btn-danger" id="bcancel" onclick="Cancelbuy()">ยกเลิก</button>'
        $("#confirm").append(app);
        $('#confirm').css('display', 'block')
        $(".othershop").addClass('opClass');
    }
}
function Confirmbuy(event) {
    if (buy) {
        var Count = $("#count").val()
        var Selected = $(event.currentTarget).attr('value');
        $('#confirm').css('display', 'none')
        $(".othershop").removeClass('opClass');
        if (Count == null){
            Count = 1;
        } else {
            Count = Number(Count);
        }
        $.post('http://dri_vending/BuyInput', JSON.stringify({Selected,Count}));
        buy = false
    }
}
function Cancelbuy() {
    buy = false;
	$('#confirm').css('display', 'none')
    $(".othershop").removeClass('opClass');
}
function input_Change(_name) {
    const _key = document.getElementById(_name);
    if (_key.value) {
        if (Number(_key.value) > _key.max) {
            _key.value = _key.max;
        } else {
            if (Number(_key.value) < _key.min) {
                _key.value = _key.min;
            }
        }
    } else {
        _key.value = _key.min;
    }
}