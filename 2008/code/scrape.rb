require 'Nokogiri'
require 'csv'
require 'open-uri'

url_list = ['http://sos.ga.gov/elections/election_results/2008_1202/swall.htm', 'http://sos.ga.gov/elections/election_results/2008_1104/swall.htm']

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

# Method to get county-level results for each state-level election
def get_detail(base_url, href, off, dist)
	elex_url = base_url + href
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

# Loop through each link
url_list.each do |url|
	puts "Now on #{url}"
	doc = Nokogiri::HTML(open(url))
	elec_date = url[/\d{4}_\d{4}/].gsub('_', '')
	elec_type = doc.css('table')[1].css('tr')[0].text.split(' ')[-3..-1] - ["Election", "2008"]
	elec_type = elec_type.map(&:downcase).join('__')
	fname = elec_date + '__ga__' + elec_type + '.csv'

	data = []
	county_level = []

	# Get only the last table, and all first children tr elements
	all_rows = doc.css('body > table')[2].xpath('./tr')
	
	# These are our individual tables for each election on the page
	rows = all_rows.select { |r| all_rows.index(r) % 2 > 0  }
	
	# These are the office headings. Yes, they are a table
	offices = all_rows.select { |r| all_rows.index(r) % 2 == 0  }.map(&:text)

	# Iterate and extract state-level data from each table
	rows.each_with_index do |row, i|
		if offices[i].strip.include?("President") || offices[i].strip.include?("Chambliss")
			off = offices[i].strip.split("\r")[0]
			# Senator has a "Chambliss attached to it"
			if off.include?("Senator")
				off = "U.S. Senate"
			end
			dist = "N/A"
		else
			off = offices[i].strip.split(',')[0]
			dist = offices[i].strip.split(',')[1].split("\r")[0].strip
		end
		puts "On row no #{i} of the page: #{off}, #{dist}"

		# Each individual table is inside a td element
		inner_table = row.xpath('./td')

		inner_table.each do |inner|
			
			if inner.css('tr').length > 2
				# Skip the header row of table and interate through the rest of the rows
				inner.css('tr')[1..-4].each_with_index do |tr, j|
					cells = tr.css('td')
					temp = { "county"=> 'GA', "office"=> off, "district"=> dist, "party"=> cells[2].text.strip, "candidate"=> cells[1].text.strip, "votes"=> cells[3].text.split(" ")[0].gsub(",","").to_i }
					data << temp
				end

				# Total row doesn't have candidate name, so built its Hash separately
				total_row = inner.css('tr')[-3]
				total_cells = total_row.css('td')
				temp = {"county"=> "GA", "office"=> off, "district"=> dist, "party"=> "Total", "candidate"=> total_cells[1].text.strip, "votes"=> total_cells[2].text.split(" ")[0].gsub(",","").to_i }
				data << temp
				
				# Build URL for county-level results
				detail  = inner.css('tr')[-2].css('a')[0]['href']			
				base_url = url.scan(/\w+.+\d\//)[0]
				county_level << get_detail(base_url, detail, off, dist)
			end
		end
	end

	# Collapse all arrays of Hashes into one master array, so that we can directly write it to CSV
	county_level = county_level.flatten

	county_csv_name = elec_date + '__ga__' + elec_type + '__county.csv'
	write_csv(data, fname)
	write_csv(county_level, county_csv_name)
end