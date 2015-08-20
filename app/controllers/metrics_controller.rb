class MetricsController < ApplicationController
require 'curb'
require 'json'
require 'yaml'
require 'sqlite3'


def metrics
	@config = YAML.load_file("#{Rails.root.to_s}/config/config.yml")['flurry']

    passing = params['from_date']['day'] + '-' + params['from_date']['month'] + '-' + params['from_date']['year']
    now = passing.to_date
    @daterange = Hash.new
    @daterange['last'] = format_date(now)
    last_month = format_date(now - 1)
    days_in_last_month = last_month.to_date.end_of_month.day
    @daterange['first'] = format_date(now - 94) if params['increment'] == 'Month'
    @daterange['first'] = format_date(now - (2*7)) if params['increment'] == 'TwoWeeks'
    @daterange['first'] = format_date(now - (7)) if params['increment'] == 'Week'

    now = @daterange['last']
    prev = @daterange['first']

    metrics = Hash.new

    @config['apps'].each do |app|
        if app['metrics']
            app_name = app['platform'] + ' ' + app['type']
            metrics[app_name] = get_app_metrics(app['metrics'], app['api_key'], prev, now)
        end
    end

    @response = metrics

    # metrics.each do |result|
    #     # if Metric.first != result.first
    #         Metric.create(app: result['app'], name: result['metric_name'], date: result['date'], value: result['value'])
    #         @response = "Added to DB"
    #     # end
    #     # @response = "did not overwrite"
    # end
end

private

def get_app_metrics(metrics_config, api_key, start_date, end_date)
    metrics = Array.new

    # Iterate through each metirc
    metrics_config.each do |metric|
        days = fetch_metric_list(metric['type'], api_key, start_date, end_date)

        if days.kind_of?(Array)
            days.each do |day|
                metrics << create_metric(metric['type'], day['@date'], day['@value'])
            end
        else
            # For single day, an array is not returned
            metrics << create_metric(metric['type'], days['@date'], days['@value'])
        end
    end

    metrics
end

def fetch_metric_list(metric_type, api_key, start_date, end_date)
    path = "/appMetrics/#{metric_type}?apiAccessCode=#{@config['api_access_code']}"
    params = "&apiKey=#{api_key}&startDate=#{start_date}&endDate=#{end_date}"
    response = JSON.parse(api_request(path+params))

    response['day']
end

def create_metric(metric_name, date, value)
	metric = Hash.new
	metric['metric_name'] = metric_name
	metric['date'] = date
	metric['value'] = value
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
