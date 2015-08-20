class EventsController < ApplicationController
require 'curb'
require 'json'
require 'yaml'
require 'sqlite3'


def test
    passing = params['from_date']['day'] + '-' + params['from_date']['month'] + '-' + params['from_date']['year']
    now = passing.to_date
    @daterange = Hash.new
    @daterange['last'] = format_date(now)
    @daterange['first'] = format_date(now - now.end_of_month.day) if params['increment'] == 'Month'
    @daterange['first'] = format_date(now - (2*7)) if params['increment'] == 'TwoWeeks'
    @daterange['first'] = format_date(now - (7)) if params['increment'] == 'Week'
end


def events
	@config = YAML.load_file("#{Rails.root.to_s}/config/config.yml")['flurry']

    passing = params['from_date']['day'] + '-' + params['from_date']['month'] + '-' + params['from_date']['year']
    now = passing.to_date
    @daterange = Hash.new
    @daterange['last'] = format_date(now)
    last_month = format_date(now - 1)
    days_in_last_month = last_month.to_date.end_of_month.day
    @daterange['first'] = format_date(now - days_in_last_month) if params['increment'] == 'Month'
    @daterange['first'] = format_date(now - (2*7)) if params['increment'] == 'TwoWeeks'
    @daterange['first'] = format_date(now - (7)) if params['increment'] == 'Week'

    now = @daterange['last']
    prev = @daterange['first']

    @response = Hash.new

    @config['apps'].each do |app|
        appl = app['platform'] + ' ' + app['type']
        path = "/eventMetrics/Summary?apiAccessCode=#{@config['api_access_code']}"
        params = "&apiKey=#{app['api_key']}&startDate=#{prev}&endDate=#{now}"
        @response[appl] = JSON.parse(api_request(path+params))
    end

   # @response = response
end

private

def get_app_metrics(events_config, api_key, start_date, end_date, application)
    metrics = Array.new

    # Iterate through each metirc
    events_config.each do |metric|
        data = fetch_metric_list(metric['event'], api_key, start_date, end_date)
        days = data['day']
        params = data['parameters']

        if days.kind_of?(Array)
            days.each do |day|
                metrics << create_metric(metric['event'], day['@date'], day['@totalCount'], application)
            end
        else
            # For single day, an array is not returned
            metrics << create_metric(metric['event'], days['@eventName'], days['@usersLastMonth'], application)
        end

        if params.kind_of?(Array)
            params.each do |param|
                metrics << create_metric(metric['event'], param['@name'], param['@key'], application)
            end
        end
    end

    metrics
end

def fetch_metric_list(event_type, api_key, start_date, end_date)
    # path = "/eventMetrics/Event?apiAccessCode=#{@config['api_access_code']}"
    path = "/eventMetrics/Summary?apiAccessCode=#{@config['api_access_code']}"
    # params = "&apiKey=#{api_key}&startDate=#{start_date}&endDate=#{end_date}&eventName=#{event_type}"
    params = "&apiKey=#{api_key}&startDate=#{start_date}&endDate=#{end_date}"
    response = JSON.parse(api_request(path+params))

    response
end

def create_metric(metric_name, date, value, application)
	metric = Hash.new
	metric['event_name'] = metric_name
	metric['date'] = date
	metric['value'] = value
	metric['app'] = application
	metric
end

def api_request(path)
    api_uri = "http://api.flurry.com"
    url = api_uri + path

    result = api_call(url)
    status = result.response_code

    i = 0
    while (i < 3) && (status != 200)
        result = api_call(url)

        i += 1
        status = result.response_code
    end

    if status != 200
        raise "Api call #{url} failed with status #{status}"
    end

    
    result.body_str
end

def api_call(url)
    sleep(1)

    result = Curl.get(url) do |api_http|
        api_http.headers['Accept'] = 'application/json'
    end

    result
end

def format_date(date)
    date.strftime("%Y-%m-%d")
end

end
