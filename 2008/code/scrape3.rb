require 'Nokogiri'
require 'csv'
require 'open-uri'
require_relative 'helpers'


url_list = ['http://sos.ga.gov/elections/election_results/2008_0205/00101.htm', 'http://sos.ga.gov/elections/election_results/2008_0205/00102.htm']

doc = Nokogiri::HTML(open(url_list[0]))
elec_date = url_list[0][/\d{4}_\d{4}/].gsub('_', '')
elec_type = (doc.css('body>p')[2].text.split(' ')[-3..-1] - ["Election", "2008"]).map(&:downcase).join('__')

data = []
url_list.each do |url|
	doc = Nokogiri::HTML(open(url))
	elec_date = url[/\d{4}_\d{4}/].gsub('_', '')
	elec_type = (doc.css('body>p')[2].text.split(' ')[-3..-1] - ["Election", "2008"]).map(&:downcase).join('__')

	# Get only first letter from the h4
	party = doc.css('h4').text.strip.split("\r")[-1].strip[0]
	off = doc.css('h4').text.strip.split("\r")[0]

	base_url = url.scan(/\w+.+\d\//)[0]
	href = url.scan(/\d+\.\w+/)[0]

	data << get_detail(base_url, href, off, 'N/A', party)
	
end

data = data.flatten
csv_name = elec_date + '__ga__' + elec_type + '__president__county.csv'
write_csv(data, csv_name)