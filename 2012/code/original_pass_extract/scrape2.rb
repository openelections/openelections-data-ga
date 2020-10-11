require 'open-uri'
require 'Nokogiri'
require 'CSV'
require_relative 'helpers'

url = 'http://sos.ga.gov/elections/election_results/2012_0306/ByDist/default.htm'
elec_date = url.scan(/\d+_\d+/)[0]

data = []
doc = Nokogiri::HTML(open(url))
table = doc.css('body > table')[-1].xpath('./tr')
names = table[1].css('td')[1..-1].map(&:text)

index_list = []

14.times do |i|
    index_list << 4*(i+1) - 2
end

index_list.each do |i|
    puts "On row #{i}"
    tds = table[i].css('td')
    dist = tds[0].text.scan(/District \d+/)[0]
    names.each_with_index do |n, j|
        votes = tds[1 + j].at_css('font').remove
        votes = tds[1 + j].text.gsub(",", "")
        temp = {"office"=> 'President',"candidate"=>n, "party" => 'R', "votes"=>votes, "district"=> dist}
        data << temp
    end
end

fname = elec_date + '__ga__primary__president__district.csv'
write_csv(data, fname) 