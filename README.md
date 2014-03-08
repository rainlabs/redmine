Redmine with plugins and themes
-------------------------------

**Redmine contains:**
- Theme a1 as default: http://redminecrm.com/pages/a1*theme
- Plugin redmine_people: http://www.redminecrm.com/projects/people/pages/1
- Plugin redmine_helpdesk: https://github.com/jfqd/redmine_helpdesk
- Plugin redmine_better_gantt_chart: https://github.com/kulesa/redmine_better_gantt_chart
- Plugin scrum2b: https://github.com/scrum2b/scrum2b
- Plugin redmine_dashboard: https://github.com/jgraichen/redmine_dashboard
- Plugin redmine_code_review: https://bitbucket.org/haru_iida/redmine_code_review
- Plugin redmine_bitbucket: https://bitbucket.org/steveqx/redmine_bitbucket

INSTALL
-------

For install project enter following command:

    $ git clone https://github.com/rainlabs/redmine
    $ cd redmine
    $ git submodule foreach git pull
    $ bundle
    $ rake RAILS_ENV=production db:migrate
    $ rake redmine:plugins:migrate RAILS_ENV=production
    $ rake generate_secret_token
    $ RAILS_ENV=production rake redmine:load_default_data

