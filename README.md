# Redmine with plugins and themes
Redmine contains:

* Theme a1 as default: http://redminecrm.com/pages/a1*theme
* Plugin redmine_people: http://www.redminecrm.com/projects/people/pages/1
* Plugin redmine_helpdesk: https://github.com/jfqd/redmine_helpdesk
* Plugin redmine_better_gantt_chart: https://github.com/kulesa/redmine_better_gantt_chart
* Plugin scrum2b: https://github.com/scrum2b/scrum2b
# INSTALL
For install project enter following command:

    $ bundle
    $ rake RAILS_ENV=production db:migrate
    $ rake redmine:plugins:migrate RAILS_ENV=production
    $ rake generate_secret_token
    $ RAILS_ENV=production REDMINE_LANG=ru rake redmine:load_default_data