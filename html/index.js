'use strict';
Vue.use(VueMaterial);
Vue.use(VueResource);
var vm = new Vue({
  el: '#pakreqweb',
  methods: {
    toggleLeftSidenav: function() {
      this.$refs.sidenav.toggle();
    },
    fetchReqList: function() {
      this.$http.get('/api/lists.json').then(response => {
        this.tb_loaded = true;
        if (response.body.status != 0) {
          this.$refs.snackbar.open();
          this.tb_error = true;
          this.tb_loaded = true;
        }
        var recv_data = response.body.data;
        this.reqtable = [];
        for (var i = 0; i < recv_data.length; i++) {
          this.reqtable.unshift(parse_entry(recv_data[i], i));
        }
        this.$refs.snackbar.close();
        this.tb_error = false;
        this.$forceUpdate();
      }, err => {
        this.$refs.snackbar.open();
        this.tb_error = true;
        this.tb_loaded = true;
      });
    },
    retryFetch: function() {
      this.tb_loaded = false;
      this.fetchReqList();
    }
  },
  data: () => ({
    tb_loaded: false,
    tb_error: false,
    snkbar: {
      dur: Infinity
    },
    reqtable: [
      {}
    ]
  })
});

vm.fetchReqList();

function parse_entry(entry, index) {
  var result_obj = {};
  var tdate = moment.utc(entry[7], "YYYY-MM-DD HH:mm:SS");
  result_obj.id = index;
  var result_array = {
    name: entry[0],
    desc: entry[1],
    type: '',
    claim: entry[3] ? entry[3] : '',
    req: entry[5] ? entry[5] : '',
    reqts: tdate.format("YYYY-MM-DD HH:mm:SS") + ' (' + tdate.fromNow() + ')',
    eta: entry[8] ? entry[8] : ''
  };
  switch (entry[2]) {
    case 1:
      result_array.type = 'New';
      break;
    case 2:
      result_array.type = 'Update';
      break;
    case 3:
      result_array.type = 'Optimize';
      break;
    default:
      result_array.type = 'Unknown ' + entry[3];
  }
  result_obj.payload = result_array;
  return result_array;
}
