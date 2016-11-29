dashboard-table-summary
  h1.page-title Overview
  ul.duration-selector
    li(each="{ dur, i in durationSelectors}", class="{ highlight: activeSelector == i }", onclick="{ selectDuration(i) }", title="{dur.start}-today")
        div {dur.name}

  table.summary
    tr
      th.team Team
      th.assigned Assigned
      th.processing Processing
      th.resolved Resolved
      th.rejected Rejected
      th.performance Performance Index

    tr.row(each="{data}", class="{ hide: shouldHideRow(department._id) }")
      td.team { department.name } {  }
      td.numeric-col { assigned }
      td.numeric-col { processing }
      td.numeric-col { resolved }
      td.numeric-col { rejected }
      td.performance(class="{  positive: performance > 0, negative: performance < 0 }") {  performance }

  script.

    let self = this;
    let ymd = "YYYY-MM-DD";
    let end_date = moment().format(ymd);

    self.activeSelector = 0;

    this.durationSelectors = [
        { name: 'week', start: generateStartDate('week', 'day', 1) },
        { name: '1 months', start: generateStartDate('month', 'month', 0) },
        { name: '2 months', start: generateStartDate('month', 'month', -1) },
        { name: '6 months', start: generateStartDate('month', 'month', -5) }
    ];

    this.selectDuration  = function(selectorIdx) {
        return function(){
            self.activeSelector = selectorIdx;

            let start_date = self.durationSelectors[selectorIdx].start;

            api.getSummary( user.organization, start_date, end_date, (data) => {
                let summary =  data.data[0].by_department;

                summary = _.keyBy( summary, 'department.name' );

                /* Aggregate by date*/
                for( var i = 1; i < data.data.length; i++ ) {
                  _.each( data.data[i].by_department, dep => {
                    _.each( ['resolved', 'processing', 'assigned'], k => {
                      summary[dep.department.name][k] += dep[k];
                    });
                  });
                }

                self.data = _.map( summary, d => {
                  d.performance = ( d.processing + d.resolved ) - d.assigned;
                  return d;
                });

                self.update();
            });
        }
    }

    // Initialize selector
    this.selectDuration(0)();

    function generateStartDate(period, adjPeriod, unit ){
        return moment().isoWeekday(1).startOf(period).add(unit,adjPeriod).format(ymd);
    }

    this.shouldHideRow = function(department){
        return user.role != "organization_admin" && user.department != department;
    }
