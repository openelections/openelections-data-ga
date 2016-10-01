require 'open-uri'
require 'Nokogiri'
require 'CSV'
require_relative 'helpers'

url_list = ['http://sos.ga.gov/elections/election_results/2012_0306/0005001.htm', 'http://sos.ga.gov/elections/election_results/2012_0306/0005002.htm']
elec_date = url_list[0].scan(/\d+_\d+/)[0]
data = []

url_list.each do |url|
	doc = Nokogiri::HTML(open(url))
	data << scrape(doc)
end

fname = elec_date + '__ga__primary__president__county.csv'
write_csv(data.flatten, fname)

answer = []
special = 'http://sos.ga.gov/elections/election_results/2012_0306/00607.htm'
doc = Nokogiri::HTML(open(special))
elec_type = (doc.css('table')[1].css('tr')[0].text.split(' ')[-3..-1] - ["Election", "2008"]).map(&:downcase).join("__")
office = doc.css('.largebold').text.strip.split(', ')[0].gsub(' Representative', ' House')
dist = doc.css('.largebold').text.strip.split(', ')[1]

answer << get_detail(special, office, dist)
fname = elec_date + '__ga__' + elec_type + '__' + office.downcase.gsub(' ', '_') + '__' + dist[/\d+/] + '.csv'
write_csv(answer.flatten, fname)