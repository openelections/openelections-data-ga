require 'Nokogiri'
require 'csv'
require 'open-uri'

# api_url = 'http://openelections.net/api/v1/election/?format=json&limit=0&state__postal=GA&start_date__year=2008'

url = 'http://sos.ga.gov/elections/election_results/2008_1202/swall.htm'

doc = Nokogiri::HTML(open(url))
elec_date = url[/\d{4}_\d{4}/].gsub('_', '')
elec_type = doc.css('table')[1].css('tr')[0].text.split(' ')[-3..-1] - ["Election", "2008"]
elec_type = elec_type.map(&:downcase).join('__')
fname = elec_date + '__ga__' + elec_type + '__state.csv'

def write_csv(data, fname)
	keys = data.flat_map(&:keys).uniq
	# puts keys
	CSV.open('../' + fname, "wb") do |csv|
	  csv << keys # adds the attributes name on the first line
	  data.each do |d|
	    csv << d.values_at(*keys)
	  end
	end
end

def get_detail(href, off, dist)
	elex_url = 'http://sos.ga.gov/elections/election_results/2008_1202/' + href
	elex_details = Nokogiri::HTML(open(elex_url))
	answer = []
	rows = elex_details.css('table')[-1].css('tr')

	names = rows[0].css('td').map(&:text).values_at(3,4,-1).map{ |n| n.gsub("\t", ' ').gsub("\r", ' ').gsub("(", '').gsub(")", '').split(' ')}
	names[-1].insert(1, "Total")

	rows = rows[3..-1] # Skip the first three rows because there's nothing in it

	rows.each do |r|
	    tds = r.css('td').map(&:text).map{ |n| n.gsub("\t", ' ').gsub("\r", ' ').gsub("(", '').gsub(")", '').strip.gsub(",","")}

	    names.each_with_index do |n, i|
	    	temp = {"office"=> off,"candidate"=>n[0], "party" => n[1], "county" => tds[0].capitalize, "votes"=>tds[3+i].to_i, "district"=> dist}
	    	answer << temp
	    end
	end
	return answer
end

data = []
hrefs = []
county_level = []

all_rows = doc.css('body > table')[2].xpath('./tr')
rows = all_rows.select { |r| all_rows.index(r) % 2 > 0  }
offices = all_rows.select { |r| all_rows.index(r) % 2 == 0  }.map(&:text)

rows.each_with_index do |row, i|
	off = offices[i].strip.split(',')[0]
	dist = offices[i].strip.split(',')[1].split("\r")[0].strip
	puts "On row no #{i} of the page: #{off}, #{dist}"

	inner_table = row.css('tr')[1..3] # leave out the row with link to detailed result
	detail = row.css('tr')[4].css('a')[0]['href'] # Push those to an array
	hrefs << detail

	county_level << get_detail(detail, off, dist)

	inner_table.each_with_index do |tr, j| # Loop through each candidate
		# puts "\t On row #{j} of inner table"
		cells = tr.css('td')
		if j != 2
			temp = { "county"=> 'GA', "office"=> off, "district"=> dist, "party"=> cells[2].text.strip, "candidate"=> cells[1].text.strip, "votes"=> cells[3].text.split(" ")[0].gsub(",","").to_i }
			data << temp
		# Total row doesn't have candidate name
		else
			temp = {"county"=> 'GA', "office"=> off, "district"=> dist, "party"=> "Total", "candidate"=> cells[1].text.strip, "votes"=> cells[2].text.split(" ")[0].gsub(",","").to_i }
			data << temp
		end
	end
end

county_level = county_level.flatten
county_level.map { |row|  row['votes'].to_s.gsub(",", "").to_i }
puts county_level[-1]

county_csv_name = elec_date + '__ga__' + elec_type + '__county.csv'
write_csv(data, fname)
write_csv(county_level, county_csv_name)