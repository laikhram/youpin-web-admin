report-department-page
  .container
    .report-tool.opaque-bg
      .breadcrumb
        span
          strong Report
      h1.page-title
        span Department
        span(hide='{ can_choose_department }') : { user && user.dept && user.dept.name}
        .field.is-inline(show='{ can_choose_department }', style='vertical-align: middle;')
          .control(style='width: 200px;')
            input(type='text', id='select_department', ref='select_department', placeholder='แสดงตามหน่วยงาน')

      h3.section-title แสดงตามช่วงเวลา
        | {moment(date['from']).format('DD/MM/YYYY')}
        | -
        | {moment(date['to']).format('DD/MM/YYYY')}

      .level
        .level-left
          .level-item
            div
              label.label ตั้งแต่
              .control
                .date-from-picker
                input.input(type='text', name='date_from', value='{ date["from"] }')
          .level-item
            div
              label.label ถึง
              .control
                .date-to-picker
                input.input(type='text', name='date_to', value='{ date["to"] }')

    .spacing-small

    .section.opaque-bg
      h3.section-title เรื่องแยกตามเจ้าหน้าที่
      .columns
        .column
          table.table.is-striped.is-narrow.performance-summary
            tr
              th.team Team
              th.assigned(style='width: 120px;')
                .has-text-right เปิด
              th.resolved(style='width: 120px;')
                .has-text-right แก้ไขสำเร็จ
              th.rejected(style='width: 120px;')
                .has-text-right ปิดกรณีอื่น
              th.performance(style='width: 120px;')
                .has-text-right Performance Index

            tr(each="{ row in data }")
              td.name
                a(href='/issue?staff={row.id}:{row.name}') { row.name }
              td.numeric-col { _.sum(_.pick(row.summary, ['pending', 'assigned', 'processing'])) || 0}
              td.numeric-col { row.summary.resolved || 0 }
              td.numeric-col { row.summary.rejected || 0 }
              td.numeric-col.performance(class="{  positive: row.performance > 0, negative: row.performance < 0 }") { row.performance.toFixed(2) }

  script.
    let self = this;

    self.picker = {};
    self.date = {
      from: moment().subtract(30, 'days').format('YYYY-MM-DD'),
      to: moment().format('YYYY-MM-DD')
    };
    self.data = [];
    self.officers = [];
    self.department_id = user.dept._id;
    self.can_choose_department = util.check_permission('view_department', user.role);

    self.on('mount', () => {
      self.initSelectDepartment();

      self.setupCloseDateCalendar($(self.root).find('.date-from-picker'), 'from');
      self.setupCloseDateCalendar($(self.root).find('.date-to-picker'), 'to');
      self.loadDepartment();
    });

    self.loadDepartment = () => {
      let dept;
      return api.getDepartments()
      .then(result => {
        dept = result;
        return api.getUsers({ department: self.department_id });
      })
      .then(result => {
        self.officers = result.data || [];
      })
      .then(() => self.loadData());
    }

    self.loadData = () => {
      function computePerformance( attributes, summary){
        let total = _.reduce( attributes, (acc, attr) => {
            acc += (summary[attr] || 0);
            return acc;
          }, 0);

        let divider = total - ((summary.pending || 0 ) + (summary.rejected || 0 ));
        if( divider === 0 ) {
          return 0;
        }

        return (summary.resolved || 0) / divider;
      }

      const start_date = self.date['from'];
      const end_date = self.date['to'];

      let summaries = [];
      let orgSummary = [];
      let available_departments = [];
      let attributes = [];

      return Promise.resolve({})
      .then(() =>
        api.getPerformance(self.date.from, self.date.to)
        .then(result => {
          console.log('Perf:', result);
        })
      )
      .then(() =>
        api.getSummary( start_date, end_date, (data) => {
          available_departments = Object.keys(data);
          attributes = available_departments.length > 0 ? Object.keys( data[available_departments[0]] ) : [];

          // Officer summary
          summaries = _.map( self.officers, officer => {
            const data_dept = data[user.dept.name];
            const data_officer = (data_dept && data_dept[officer.name]) ? data_dept[officer.name] : attributes.reduce((acc, cur) => { acc[cur] = 0; return acc; }, {});
            return {
              id: officer._id,
              name: officer.name,
              summary: data_officer,
              performance: computePerformance(attributes, data_officer)
            }
          });

        })
      )
      .then(() => {
        let all = _.reduce( attributes, (acc,attr) => {
          acc[attr] = 0;
          return acc;
        }, {} );

        all = _.reduce( summaries, (acc, dept) => {
           _.each( attributes, attr => {
              acc[attr] += dept['summary'][attr] || 0;
          });
          return acc;
        }, all);

        orgSummary = {
          id: '',
          name: 'All',
          summary: all,
          performance: computePerformance(attributes, all)
        };
      })
      .then(() => {
        self.data = user.is_superuser ? [ orgSummary ] : [];
        self.data = self.data.concat(summaries);

        self.update();
      });
    };

    self.destroyCloseDateCalendar = function() {
      if (self.picker.length === 0) return;
      _.forEach(self.picker, picker => {
        $(window).off('resize.' + picker.__id);
        picker.destroy();
      });
      self.picker = [];
    }

    self.setupCloseDateCalendar = function(calendar, name) {
      if (self.picker[name]) return;
      var this_year = moment().format('YYYY');
      var $calendar = $(calendar);
      var $input = $calendar.next('input');
      self.picker[name] = new Pikaday({
        field: $input.get(0),
        format: 'YYYY-MM-DD',
        numberOfMonths: 1,
        showDaysInNextAndPreviousMonths: true,
        yearRange: [+this_year, +this_year+1],
        // minDate: moment().toDate(),
        maxDate: moment().toDate(),
        onSelect: function(date) {
          self.date[name] = moment(date).format('YYYY-MM-DD');
          self.loadData();
        },
      });
      self.picker[name].__id = util.uniqueId('calendar-');
      $(window).on('resize.' + self.picker[name].__id, function() {
        self.picker[name].adjustPosition();
      });
    };

    self.initSelectDepartment = () => {
      const status = [
        { _id: user.dept._id, name: user.dept.name }
      ];
      $(self.refs.select_department).selectize({
        maxItems: 1,
        valueField: '_id',
        labelField: 'name',
        searchField: 'name',
        options: _.compact(status), // all choices
        items: [user.dept._id], // selected choices
        create: false,
        allowEmptyOption: false,
        //- hideSelected: true,
        preload: true,
        load: function(query, callback) {
          //- if (!query.length) return callback();
          api.getDepartments({ })
          .then(result => {
            callback(result.data);
          });
        },
        onChange: function(value) {
          self.department_id = value;
          self.loadDepartment();
        }
      });
    }
